//
//  DisplayView.swift
//  Aerial
//
//  Created by Guillaume Louel on 09/05/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import Cocoa

class DisplayView: NSView {
    /*override init() {
        debugLog("************************DisplayView init")
        super.init()
    }*/

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // We need to handle dark mode
        var backgroundColor = NSColor.init(white: 0.9, alpha: 1.0)
        var borderColor = NSColor.init(white: 0.8, alpha: 1.0)

        let screenColor = NSColor.init(red: 0.44, green: 0.60, blue: 0.82, alpha: 1.0)
        let screenBorderColor = NSColor.black

        let timeManagement = TimeManagement.sharedInstance
        if timeManagement.isDarkModeEnabled() {
            backgroundColor = NSColor.init(white: 0.2, alpha: 1.0)
            borderColor = NSColor.init(white: 0.6, alpha: 1.0)
        }

        // Draw background with a 1pt border
        borderColor.setFill()
        __NSRectFill(dirtyRect)

        let path = NSBezierPath(rect: dirtyRect.insetBy(dx: 1, dy: 1))
        backgroundColor.setFill()
        path.fill()

        let displayDetection = DisplayDetection.sharedInstance

        let sRect = NSRect(x: 20, y: 20, width:
            150, height: 50)
        let sPath = NSBezierPath(rect: sRect)
        screenBorderColor.setFill()
        sPath.fill()

        let sInPath = NSBezierPath(rect: sRect.insetBy(dx: 1, dy: 1))
        screenColor.setFill()
        sInPath.fill()
    }
}
