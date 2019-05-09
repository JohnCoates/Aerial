//
//  DisplayDetection.swift
//  Aerial
//
//  Created by Guillaume Louel on 09/05/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import Cocoa

class Screen {
    var id: CGDirectDisplayID
    var width: Int
    var height: Int
    var bottomLeftFrame: CGRect
    var topRightCorner: CGPoint
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
        self.isMain = isMain
        self.backingScaleFactor = 1
    }

    var description: String {
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

        debugLog("***Display Detection Done***")
        for screen in screens {
            debugLog("\(screen.description)")
        }
    }

    // MARK: - Helpers

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
/*
    func getGlobalScreenRect -> CGRect {
        var minX, minY, maxX, maxY = 0
        for screen in screens {
            if screen.origin.x
        }
    }*/
    // NSScreen coordinates are with a bottom left origin, whereas CGDisplay
    // coordinates are top left origin, this function converts the origin.y value
    func convertTopLeftToBottomLeft(rect: CGRect) -> CGRect {
        let screenFrame = (NSScreen.main?.frame)!
        let newY = 0 - (rect.origin.y - screenFrame.size.height + rect.height)
        return CGRect(x: rect.origin.x, y: newY, width: rect.width, height: rect.height)
    }

}
