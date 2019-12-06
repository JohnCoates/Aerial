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

// swiftlint:disable:next type_body_length
final class DisplayDetection: NSObject {
    static let sharedInstance = DisplayDetection()

    var screens = [Screen]()
    var cmInPoints: CGFloat = 40
    var maxLeftScreens: CGFloat = 0
    var maxBelowScreens: CGFloat = 0

    var advancedScreenRect: CGRect?
    var advancedZeroedScreenRect: CGRect?

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
        // This calculation is pretty different in advanced mode so it got split up
        let preferences = Preferences.sharedInstance
        if preferences.displayMarginsAdvanced && !advancedMargins.displays.isEmpty {
            calculateAdvancedZeroedOrigins()
        } else {
            calculateZeroedOrigins()
        }

        for screen in screens {
            debugLog("\(screen)")
        }

        debugLog("\(getGlobalScreenRect())")
        debugLog("***Display Detection Done***")
    }

    // MARK: - Helpers
    // Regular calculation
    func calculateZeroedOrigins() {
        let orect = getGlobalScreenRect()

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

    // Advanced calculation, this is a bit messy...
    func calculateAdvancedZeroedOrigins() {
        // 2 pass, first we calculate the real position of each screen with offsets applied
        for screen in screens {
            debugLog("Asrc orig : \(screen.bottomLeftFrame.origin)")
            var offsetleft: CGFloat = 0
            var offsettop: CGFloat = 0

            if let display = findDisplayAdvancedMargins(posx: screen.bottomLeftFrame.origin.x, posy: screen.bottomLeftFrame.origin.y) {
                offsetleft = display.offsetleft
                offsettop = display.offsettop
            }

            // These are NOT zeroed at this point !!!
            screen.zeroedOrigin = CGPoint(x: screen.bottomLeftFrame.origin.x + (offsetleft * cmInPoints),
                                          y: screen.bottomLeftFrame.origin.y + (offsettop * cmInPoints))
        }

        // We get an intermediate representation of whole bunch, non zeroed
        let irect = getIntermediateAdvancedScreenRect()
        advancedScreenRect = irect  // We store this for later...
        // And now we zero them !
        for screen in screens {
            screen.zeroedOrigin = CGPoint(x: screen.zeroedOrigin.x - irect.origin.x,
                                          y: screen.zeroedOrigin.y - irect.origin.y)
            debugLog("Zorig : \(screen.zeroedOrigin)")
        }

        // Now that zeroed is really zeroed, we can cheat a bit
        let i0rect = getIntermediateAdvancedScreenRect()
        advancedZeroedScreenRect = i0rect  // We store this for later...

        let orect = getGlobalScreenRect()
        debugLog("Orect : \(orect)")
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
        let preferences = Preferences.sharedInstance
        if preferences.displayMarginsAdvanced && !advancedMargins.displays.isEmpty, let adv = advancedScreenRect {
            // Now this is awkward... we precalculated this at detectdisplays->advancedZeroedOrigins
            return adv
        } else {
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
    }

    func getIntermediateAdvancedScreenRect() -> CGRect {
        // At this point, this is non zeroed
        var minX: CGFloat = 0.0, minY: CGFloat = 0.0, maxX: CGFloat = 0.0, maxY: CGFloat = 0.0
        for screen in screens {
            if screen.zeroedOrigin.x < minX {
                minX = screen.zeroedOrigin.x
            }
            if screen.zeroedOrigin.y < minY {
                minY = screen.zeroedOrigin.y
            }
            if (screen.zeroedOrigin.x + CGFloat(screen.width)) > maxX {
                maxX = screen.zeroedOrigin.x + CGFloat(screen.width)
            }
            if (screen.zeroedOrigin.y + CGFloat(screen.height)) > maxY {
                maxY = screen.zeroedOrigin.y + CGFloat(screen.height)
            }
        }

        return CGRect(x: minX, y: minY, width: maxX-minX, height: maxY-minY)
    }

    func getZeroedActiveSpannedRect() -> CGRect {
        let preferences = Preferences.sharedInstance
        if preferences.displayMarginsAdvanced && !advancedMargins.displays.isEmpty, let advz = advancedZeroedScreenRect {
            // Now this is awkward... we precalculated this at detectdisplays->advancedZeroedOrigins
            return advz
        } else {
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

    func getMarginsJSON() -> String {
        let preferences = Preferences.sharedInstance
        var adv: AdvancedMargin

        if !advancedMargins.displays.isEmpty {
            // If we have something already in preferences, return that
            adv = advancedMargins
        } else {
            // Generate a JSON from current config
            var marginArray = [DisplayAdvancedMargin]()

            for screen in screens {
                let zleft = screen.bottomLeftFrame.origin.x
                let ztop = screen.bottomLeftFrame.origin.y

                let (leftScreens, belowScreens) = detectBorders(forScreen: screen)

                let offsetleft = leftScreens * CGFloat(preferences.horizontalMargin!)
                let offsettop = belowScreens * CGFloat(preferences.verticalMargin!)

                marginArray.append(DisplayAdvancedMargin(zleft: zleft, ztop: ztop, offsetleft: offsetleft, offsettop: offsettop))
            }

            adv = AdvancedMargin(displays: marginArray)
        }

        print(adv)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(adv)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("error encoding")
            return ""
        }

        return ""
    }

    func findDisplayAdvancedMargins(posx: CGFloat, posy: CGFloat) -> DisplayAdvancedMargin? {
        for display in advancedMargins.displays {
            if posx == display.zleft && posy == display.ztop {
                return display
            }
        }

        return nil
    }
    var advancedMargins: AdvancedMargin {
        get {
            let preferences = Preferences.sharedInstance
            let jsonString = preferences.advancedMargins!

            if let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()

                do {
                    let adv = try decoder.decode(AdvancedMargin.self, from: jsonData)
                    return adv
                } catch {
                    print(error.localizedDescription)
                }
            }
            return AdvancedMargin(displays: [DisplayAdvancedMargin]())
        }
        set {
            let preferences = Preferences.sharedInstance

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            do {
                let jsonData = try encoder.encode(newValue)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    preferences.advancedMargins = jsonString
                }
            } catch {
                print("error encoding")
            }
        }
    }
}

struct AdvancedMargin: Codable {
    let displays: [DisplayAdvancedMargin]
}

struct DisplayAdvancedMargin: Codable {
    var zleft: CGFloat
    var ztop: CGFloat
    var offsetleft: CGFloat
    var offsettop: CGFloat
}
