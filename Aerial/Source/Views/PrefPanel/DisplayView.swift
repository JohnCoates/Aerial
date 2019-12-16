//
//  DisplayView.swift
//  Aerial
//
//  Created by Guillaume Louel on 09/05/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import Cocoa

class DisplayPreview: NSObject {
    var screen: Screen
    var previewRect: CGRect

    init(screen: Screen, previewRect: CGRect) {
        self.screen = screen
        self.previewRect = previewRect
    }
}

extension NSImage {
    func flipped(flipHorizontally: Bool = false, flipVertically: Bool = false) -> NSImage {
        let flippedImage = NSImage(size: size)

        flippedImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high

        let transform = NSAffineTransform()
        transform.translateX(by: flipHorizontally ? size.width : 0, yBy: flipVertically ? size.height : 0)
        transform.scaleX(by: flipHorizontally ? -1 : 1, yBy: flipVertically ? -1 : 1)
        transform.concat()

        draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .sourceOver, fraction: 1)

        flippedImage.unlockFocus()

        return flippedImage
    }
}

class DisplayView: NSView {
    // We store our computed previews here
    var displayPreviews = [DisplayPreview]()

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Drawing
    //swiftlint:disable:next cyclomatic_complexity
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let preferences = Preferences.sharedInstance

        // We need to handle dark mode
        var backgroundColor = NSColor.init(white: 0.9, alpha: 1.0)
        var borderColor = NSColor.init(white: 0.8, alpha: 1.0)

        //let screenColor = NSColor.init(red: 0.38, green: 0.60, blue: 0.85, alpha: 1.0)
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
        displayPreviews = [DisplayPreview]()    // Empty the array in case we redraw

        // In order to draw the screen we need to know the total size of all
        // the displays together
        let globalRect = displayDetection.getGlobalScreenRect()

        var minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat, scaleFactor: CGFloat
        if (frame.width / frame.height) > (globalRect.width / globalRect.height) {
            // We fill vertically then
            maxY = frame.height - 60
            minY = 30
            scaleFactor = globalRect.height / maxY
            maxX = globalRect.width / scaleFactor
            minX = (frame.width - maxX)/2
        } else {
            // We fill horizontally
            maxX = frame.width - 60
            minX = 30
            scaleFactor = globalRect.width / maxX
            maxY = globalRect.height / scaleFactor
            minY = (frame.height - maxY)/2
        }

        // In spanned mode, we start by a faint full view of the span
        if preferences.newViewingMode == Preferences.NewViewingMode.spanned.rawValue {
            let activeRect = displayDetection.getZeroedActiveSpannedRect()
            debugLog("spanned active rect \(activeRect)")
            let activeSRect = NSRect(x: minX + (activeRect.origin.x/scaleFactor),
                               y: minY + (activeRect.origin.y/scaleFactor),
                               width: activeRect.width/scaleFactor,
                               height: activeRect.height/scaleFactor)

            let bundle = Bundle(for: PreferencesWindowController.self)
            if let imagePath = bundle.path(forResource: "screen0", ofType: "jpg") {
                let image = NSImage(contentsOfFile: imagePath)
                image!.draw(in: activeSRect, from: calcScreenshotRect(src: activeSRect), operation: NSCompositingOperation.copy, fraction: 0.1)
            } else {
                errorLog("\(#file) screenshot is missing!!!")
            }
        }

        var idx = 0
        var shouldFlip = true
        // Now we draw each individual screen
        for screen in displayDetection.screens {
            let sRect = NSRect(x: minX + (screen.zeroedOrigin.x/scaleFactor),
                               y: minY + (screen.zeroedOrigin.y/scaleFactor),
                               width: screen.bottomLeftFrame.width/scaleFactor,
                               height: screen.bottomLeftFrame.height/scaleFactor)

            let sPath = NSBezierPath(rect: sRect)
            screenBorderColor.setFill()
            sPath.fill()

            let sInRect = sRect.insetBy(dx: 1, dy: 1)

            func rawValue(for mode: Preferences.NewViewingMode) -> Int { return mode.rawValue }
            let viewMode = preferences.newViewingMode

            if viewMode == rawValue(for: .independent) || viewMode == rawValue(for: .cloned) || viewMode == rawValue(for: .mirrored) {
                if displayDetection.isScreenActive(id: screen.id) {
                    let bundle = Bundle(for: PreferencesWindowController.self)
                    if let imagePath = bundle.path(forResource: "screen"+String(idx), ofType: "jpg") {
                        var image = NSImage(contentsOfFile: imagePath)

                        if preferences.newViewingMode == Preferences.NewViewingMode.mirrored.rawValue && shouldFlip {
                            image = image?.flipped(flipHorizontally: true, flipVertically: false)
                        }

                        shouldFlip = !shouldFlip

                        image!.draw(in: sInRect, from: calcScreenshotRect(src: sInRect), operation: NSCompositingOperation.copy, fraction: 1.0)
                    } else {
                        errorLog("\(#file) screenshot is missing!!!")
                    }

                    // Show difference images in independant mode to simulate
                    if preferences.newViewingMode == Preferences.NewViewingMode.independent.rawValue {
                        if idx < 2 {
                            idx += 1
                        } else {
                            idx = 0
                        }
                    }
                } else {
                    // If the screen is innactive we fill it with a near black color
                    let sInPath = NSBezierPath(rect: sInRect)
                    let grey = NSColor(white: 0.1, alpha: 1.0)
                    grey.setFill()
                    sInPath.fill()
                }
            } else {
                // Spanned mode
                if displayDetection.isScreenActive(id: screen.id) {
                    // Calculate which portion of the image to display
                    let activeRect = displayDetection.getZeroedActiveSpannedRect()
                    let activeSRect = NSRect(x: minX + (activeRect.origin.x/scaleFactor),
                                             y: minY + (activeRect.origin.y/scaleFactor),
                                             width: activeRect.width/scaleFactor,
                                             height: activeRect.height/scaleFactor)
                    let ssRect = calcScreenshotRect(src: activeSRect)
                    let xFactor = ssRect.width / activeSRect.width
                    let yFactor = ssRect.height / activeSRect.height
                    // ...
                    let sFRect = CGRect(x: (sInRect.origin.x - activeSRect.origin.x) * xFactor + ssRect.origin.x,
                                        y: (sInRect.origin.y - activeSRect.origin.y) * yFactor + ssRect.origin.y,
                                        width: sInRect.width*xFactor,
                                        height: sInRect.height*yFactor)

                    let bundle = Bundle(for: PreferencesWindowController.self)
                    if let imagePath = bundle.path(forResource: "screen0", ofType: "jpg") {
                        let image = NSImage(contentsOfFile: imagePath)
                        //image!.draw(in: sInRect)
                        image!.draw(in: sInRect, from: sFRect, operation: NSCompositingOperation.copy, fraction: 1.0)
                    } else {
                        errorLog("\(#file) screenshot is missing!!!")
                    }
                }
            }

            // We preserve those calculations to handle our clicking logic
            displayPreviews.append(DisplayPreview(screen: screen, previewRect: sInRect))

            // We put a white bar on the main screen
            if screen.isMain {
                let mainRect = CGRect(x: sRect.origin.x, y: sRect.origin.y + sRect.height-8, width: sRect.width, height: 8)
                let sMainPath = NSBezierPath(rect: mainRect)
                NSColor.black.setFill()
                sMainPath.fill()
                let sMainInPath = NSBezierPath(rect: mainRect.insetBy(dx: 1, dy: 1))
                NSColor.white.setFill()
                sMainInPath.fill()
            }
        }
    }

    // Helper to keep aspect ratio of screenshots to be displayed
    func calcScreenshotRect(src: CGRect) -> CGRect {
        var minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat, scaleFactor: CGFloat

        let imgw: CGFloat = 720
        let imgh: CGFloat = 400

        if (imgw/imgh) < (src.width/src.height) {
            minX = 0
            maxX = imgw
            scaleFactor = src.width / maxX
            maxY = src.height / scaleFactor
            minY = (imgh - maxY)/2
        } else {
            minY = 0
            maxY = imgh
            scaleFactor = src.height / maxY
            maxX = src.width / scaleFactor
            minX = (imgw - maxX)/2
        }

        return CGRect(x: minX, y: minY, width: maxX, height: maxY)
    }

    // MARK: - Clicking
    override func mouseDown(with event: NSEvent) {
        let displayDetection = DisplayDetection.sharedInstance
        let preferences = Preferences.sharedInstance

        // Grab relative location of the click in view
        let point = convert(event.locationInWindow, from: nil)

        // If in selection mode, toggle the screen & redraw
        if preferences.newDisplayMode == Preferences.NewDisplayMode.selection.rawValue {
            for displayPreview in displayPreviews {
                if displayPreview.previewRect.contains(point) {
                    if displayDetection.isScreenActive(id: displayPreview.screen.id) {
                        displayDetection.unselectScreen(id: displayPreview.screen.id)
                    } else {
                        displayDetection.selectScreen(id: displayPreview.screen.id)
                    }
                    debugLog("Clicked on \(displayPreview.screen.id)")
                    self.needsDisplay = true
                }
            }
        }
    }
}
