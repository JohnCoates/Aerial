//
//  DisplayDetection.swift
//  Aerial
//
//  Created by Guillaume Louel on 09/05/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import Cocoa

class Screen: NSObject {
    var id: CGDirectDisplayID
    var width: Int
    var height: Int
    var bottomLeftFrame: CGRect
    var topRightCorner: CGPoint
    var zeroedOrigin: CGPoint
    var isMain: Bool
    var backingScaleFactor: CGFloat

    init(id: CGDirectDisplayID, width: Int, height: Int, bottomLeftFrame: CGRect, isMain: Bool, backingScaleFactor: CGFloat) {
        self.id = id
        self.width = width
        self.height = height
        self.bottomLeftFrame = bottomLeftFrame
        // We precalculate the right corner too, as we will need this !
        self.topRightCorner = CGPoint(x: bottomLeftFrame.origin.x + CGFloat(width),
                                      y: bottomLeftFrame.origin.y + CGFloat(height))
        self.zeroedOrigin = CGPoint(x: 0, y: 0)
        self.isMain = isMain
        self.backingScaleFactor = backingScaleFactor
    }

    override var description: String {
        //swiftlint:disable:next line_length
        return "[id=\(self.id), width=\(self.width), height=\(self.height), bottomLeftFrame=\(self.bottomLeftFrame), topRightCorner=\(self.topRightCorner), isMain=\(self.isMain), backingScaleFactor=\(self.backingScaleFactor)]"
    }
}

final class DisplayDetection: NSObject {
    static let sharedInstance = DisplayDetection()

    var screens = [Screen]()
    var cmInPoints: CGFloat = 40
    var maxLeftScreens: CGFloat = 0
    var maxBelowScreens: CGFloat = 0

    // MARK: - Lifecycle
    override init() {
        super.init()
        debugLog("Display Detection initialized")
        _ = detectDisplays()
    }

    // MARK: - Detection
    func detectDisplays() {
        // Display detection is done in two passes :
        // - Through CGDisplay, we grab all online screens (connected, but
        //   may or may not be powered on !) and get most information needed
        // - Through NSScreen to get the backingScaleFactor (retinaness of a screen)

        debugLog("***Display Detection***")
        // Cleanup a bit in case of redetection
        screens = [Screen]()
        maxLeftScreens = 0
        maxBelowScreens = 0

        // First pass
        let maxDisplays: UInt32 = 32
        var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var displayCount: UInt32 = 0

        _ = CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &displayCount)
        debugLog("\(displayCount) display(s) detected")
        var mainID: CGDirectDisplayID?

        for currentDisplay in onlineDisplays[0..<Int(displayCount)] {
            let isMain = CGDisplayIsMain(currentDisplay)

            if isMain == 1 {
                // We calculate the equivalent of a centimeter in points on the main screen as a reference
                let mmsize = CGDisplayScreenSize(currentDisplay)
                let wide = CGDisplayPixelsWide(currentDisplay)
                cmInPoints = CGFloat(wide) / CGFloat(mmsize.width) * 10
                debugLog("1cm = \(cmInPoints) points")
                mainID = currentDisplay
            }

            // swiftlint:disable:next line_length
            //debugLog("pass1: id \(currentDisplay), width: \(CGDisplayPixelsWide(currentDisplay)), height: \(CGDisplayPixelsHigh(currentDisplay)),isMain isMain \(isMain)")
        }

        // Second pass on NSScreen to grab the retina factor
        for screen in NSScreen.screens {
            let screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID

            var thisIsMain = false
            if screenID == mainID {
                thisIsMain = true
            }

            debugLog("npass: dict \(screen.deviceDescription)")
            debugLog("       bottomLeftFrame \(screen.frame)")

            screens.append(Screen(id: screenID,
                                  width: Int(screen.frame.width),
                                  height: Int(screen.frame.height),
                                  bottomLeftFrame: screen.frame,
                                  isMain: thisIsMain,
                                  backingScaleFactor: screen.backingScaleFactor))
        }

        // Before we finish, we calculate the origin of each screen from a 0,0 perspective
        calculateZeroedOrigins()

        for screen in screens {
            debugLog("\(screen)")
        }

        debugLog("\(getGlobalScreenRect())")
        debugLog("***Display Detection Done***")
    }

    // MARK: - Helpers

    func calculateZeroedOrigins() {
        let orect = getGlobalScreenRect()

        // First we check for the screen relative position and calculate how many screens we have horizontally
        for screen in screens {
            debugLog("src orig : \(screen.bottomLeftFrame.origin)")

            let (leftScreens, belowScreens) = detectBorders(forScreen: screen)

            if leftScreens > maxLeftScreens {
                maxLeftScreens = leftScreens
            }
            if belowScreens > maxBelowScreens {
                maxBelowScreens = belowScreens
            }

            screen.zeroedOrigin = CGPoint(x: screen.bottomLeftFrame.origin.x - orect.origin.x + (leftScreens * leftMargin()),
                                          y: screen.bottomLeftFrame.origin.y - orect.origin.y + (belowScreens * belowMargin()))
        }
    }

    // Border detection
    // This will work for most cases, but will fail in some grid/tetris like arrangements
    func detectBorders(forScreen: Screen) -> (CGFloat, CGFloat) {
        var leftScreens: CGFloat = 0
        var belowScreens: CGFloat = 0

        for screen in screens where screen != forScreen {
            if screen.bottomLeftFrame.origin.x < forScreen.bottomLeftFrame.origin.x &&
                screen.bottomLeftFrame.origin.x + CGFloat(screen.width) <=
                forScreen.bottomLeftFrame.origin.x {
                leftScreens += 1
            }
            if screen.bottomLeftFrame.origin.y < forScreen.bottomLeftFrame.origin.y &&
                screen.bottomLeftFrame.origin.y + CGFloat(screen.height) <=
                forScreen.bottomLeftFrame.origin.y {
                belowScreens += 1
            }
        }
        debugLog("left \(leftScreens) below \(belowScreens)")

        return (leftScreens, belowScreens)
    }

    func leftMargin() -> CGFloat {
        let preferences = Preferences.sharedInstance
        return cmInPoints * CGFloat(preferences.horizontalMargin!)
    }

    func belowMargin() -> CGFloat {
        let preferences = Preferences.sharedInstance
        return cmInPoints * CGFloat(preferences.verticalMargin!)
    }

    func findScreenWith(frame: CGRect) -> Screen? {
        for screen in screens where frame == screen.bottomLeftFrame {
            return screen
        }

        return nil
    }

    func findScreenWith(id: CGDirectDisplayID) -> Screen? {
        for screen in screens where screen.id == id {
            return screen
        }

        return nil
    }

    // Calculate the size of the global screen (the composite of all the displays attached)
    func getGlobalScreenRect() -> CGRect {
        var minX: CGFloat = 0.0, minY: CGFloat = 0.0, maxX: CGFloat = 0.0, maxY: CGFloat = 0.0
        for screen in screens {
            if screen.bottomLeftFrame.origin.x < minX {
                minX = screen.bottomLeftFrame.origin.x
            }
            if screen.bottomLeftFrame.origin.y < minY {
                minY = screen.bottomLeftFrame.origin.y
            }
            if screen.topRightCorner.x > maxX {
                maxX = screen.topRightCorner.x
            }
            if screen.topRightCorner.y > maxY {
                maxY = screen.topRightCorner.y
            }
        }

        return CGRect(x: minX, y: minY, width: maxX-minX+(maxLeftScreens*leftMargin()), height: maxY-minY+(maxBelowScreens*belowMargin()))
    }

    func getZeroedActiveSpannedRect() -> CGRect {
        var minX: CGFloat = 0.0, minY: CGFloat = 0.0, maxX: CGFloat = 0.0, maxY: CGFloat = 0.0
        for screen in screens where isScreenActive(id: screen.id) {
            if screen.bottomLeftFrame.origin.x < minX {
                minX = screen.bottomLeftFrame.origin.x
            }
            if screen.bottomLeftFrame.origin.y < minY {
                minY = screen.bottomLeftFrame.origin.y
            }
            if screen.topRightCorner.x > maxX {
                maxX = screen.topRightCorner.x
            }
            if screen.topRightCorner.y > maxY {
                maxY = screen.topRightCorner.y
            }
        }

        let width = maxX - minX
        let height = maxY - minY
        // Zero the origin to the global rect
        let orect = getGlobalScreenRect()
        minX -= orect.origin.x
        minY -= orect.origin.y
        return CGRect(x: minX, y: minY, width: width+(maxLeftScreens*leftMargin()), height: height+(maxBelowScreens*belowMargin()))
    }

    // NSScreen coordinates are with a bottom left origin, whereas CGDisplay
    // coordinates are top left origin, this function converts the origin.y value
    func convertTopLeftToBottomLeft(rect: CGRect) -> CGRect {
        let screenFrame = (NSScreen.main?.frame)!
        let newY = 0 - (rect.origin.y - screenFrame.size.height + rect.height)
        return CGRect(x: rect.origin.x, y: newY, width: rect.width, height: rect.height)
    }

    // MARK: - Public utility fuctions
    func isScreenActive(id: CGDirectDisplayID) -> Bool {
        let preferences = Preferences.sharedInstance
        let screen = findScreenWith(id: id)

        switch preferences.newDisplayMode {
        case Preferences.NewDisplayMode.allDisplays.rawValue:
            // This one is easy
            return true
        case Preferences.NewDisplayMode.mainOnly.rawValue:
            if let scr = screen {
                if scr.isMain {
                    return true
                }
            }
            return false
        case Preferences.NewDisplayMode.secondaryOnly.rawValue:
            if let scr = screen {
                if scr.isMain {
                    return false
                }
            }
            return true
        case Preferences.NewDisplayMode.selection.rawValue:
            if isScreenSelected(id: id) {
                return true
            }
            return false
        default:
            return true // Will never get called
        }
    }

    func isScreenSelected(id: CGDirectDisplayID) -> Bool {
        let preferences = Preferences.sharedInstance

        // If we have it in the dictionnary, then return that
        if preferences.newDisplayDict.keys.contains(String(id)) {
            return preferences.newDisplayDict[String(id)]!
        }
        return false    // Unknown screens will not be considered selected
    }

    func selectScreen(id: CGDirectDisplayID) {
        let preferences = Preferences.sharedInstance
        preferences.newDisplayDict[String(id)] = true
    }

    func unselectScreen(id: CGDirectDisplayID) {
        let preferences = Preferences.sharedInstance
        preferences.newDisplayDict[String(id)] = false
    }

}
