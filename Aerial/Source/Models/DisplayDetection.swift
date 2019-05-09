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

    init(id: CGDirectDisplayID, width: Int, height: Int, bottomLeftFrame: CGRect, isMain: Bool) {
        self.id = id
        self.width = width
        self.height = height
        self.bottomLeftFrame = bottomLeftFrame
        // We precalculate the right corner too, as we will need this !
        self.topRightCorner = CGPoint(x: bottomLeftFrame.origin.x + CGFloat(width),
                                      y: bottomLeftFrame.origin.y + CGFloat(height))
        self.zeroedOrigin = CGPoint(x: 0, y: 0)
        self.isMain = isMain
        self.backingScaleFactor = 1
    }

    override var description: String {
        //swiftlint:disable:next line_length
        return "[id=\(self.id), width=\(self.width), height=\(self.height), bottomLeftFrame=\(self.bottomLeftFrame), topRightCorner=\(self.topRightCorner), isMain=\(self.isMain), backingScaleFactor=\(self.backingScaleFactor)]"
    }
}

final class DisplayDetection: NSObject {
    static let sharedInstance = DisplayDetection()

    var screens = [Screen]()

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
        // First pass
        let maxDisplays: UInt32 = 32
        var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var displayCount: UInt32 = 0

        _ = CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &displayCount)
        debugLog("\(displayCount) display(s) detected")

        for currentDisplay in onlineDisplays[0..<Int(displayCount)] {
            let isMain = CGDisplayIsMain(currentDisplay)

            var rect = CGDisplayBounds(currentDisplay)
            if isMain == 0 {
                rect = convertTopLeftToBottomLeft(rect: rect)
            }

            screens.append(Screen(id: currentDisplay,
                                  width: CGDisplayPixelsWide(currentDisplay),
                                  height: CGDisplayPixelsHigh(currentDisplay),
                                  bottomLeftFrame: rect, isMain: isMain == 1 ? true : false))
        }

        // Second pass on NSScreen to grab the retina factor
        for screen in NSScreen.screens {
            let dscreen = findScreenWith(frame: screen.frame)

            if dscreen != nil {
                dscreen?.backingScaleFactor = screen.backingScaleFactor
            } else {
                debugLog("Unkown screen on second pass please report")
            }
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

        for screen in screens {
            screen.zeroedOrigin = CGPoint(x: screen.bottomLeftFrame.origin.x - orect.origin.x,
                                          y: screen.bottomLeftFrame.origin.y - orect.origin.y)
        }
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

        return CGRect(x: minX, y: minY, width: maxX-minX, height: maxY-minY)
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
        // TODO SELECTION MODE
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
            return true // Why not?
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
