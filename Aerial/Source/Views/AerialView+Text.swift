//
//  AerialView+Text.swift
//  Aerial
//
//  Created by Guillaume Louel on 06/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import AVKit

extension AerialView {

    func setupTextLayers(layer: CALayer) {
        // Main description layer
        textLayer = CATextLayer()
        textLayer.frame = layer.bounds  // Same size as the screen
        textLayer.opacity = 0
        textLayer.shadowRadius = 10
        textLayer.shadowOpacity = 1.0
        textLayer.shadowColor = CGColor.black
        layer.addSublayer(textLayer)

        // Clock Layer
        clockLayer = CATextLayer()
        clockLayer.opacity = 0
        clockLayer.shadowRadius = 10
        clockLayer.shadowOpacity = 1.0
        clockLayer.shadowColor = CGColor.black
        layer.addSublayer(clockLayer)

        // Message Layer
        messageLayer = CATextLayer()
        messageLayer.opacity = 0
        messageLayer.shadowRadius = 10
        messageLayer.shadowOpacity = 1.0
        messageLayer.shadowColor = CGColor.black
        layer.addSublayer(messageLayer)
    }

    func setupGlitchWorkaroundLayer(layer: CALayer) {
        debugLog("Using dot workaround for video driver corruption")

        let workaroundLayer = CATextLayer()
        workaroundLayer.frame = self.bounds
        workaroundLayer.opacity = 0.5
        workaroundLayer.font = NSFont(name: "Helvetica Neue Medium", size: 4)
        workaroundLayer.fontSize = 4
        workaroundLayer.string = "."

        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: workaroundLayer.font as Any]

        // Calculate bounding box
        let attrString = NSAttributedString(string: workaroundLayer.string as! String, attributes: attributes)
        let rect = attrString.boundingRect(with: layer.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)

        workaroundLayer.frame = rect
        workaroundLayer.position = CGPoint(x: 2, y: 2)
        workaroundLayer.anchorPoint = CGPoint(x: 0, y: 0)
        layer.addSublayer(workaroundLayer)
    }
}
