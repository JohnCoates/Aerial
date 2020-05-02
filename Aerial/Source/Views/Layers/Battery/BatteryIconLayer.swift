//
//  BatteryIconLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 01/05/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class BatteryIconLayer: CALayer {
    var textLayer: CATextLayer
    var charging: CALayer

    override init() {
        charging = CALayer()
        textLayer = CATextLayer()

        super.init()

        let imagePath = Bundle(for: PreferencesWindowController.self).path(
            forResource: "battery.0",
            ofType: "pdf")

        let img = NSImage(contentsOfFile: imagePath!)
        if imagePath != nil {
            frame.size.height = img!.size.height / 3
            frame.size.width = img!.size.width / 3
            contents = img

            textLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width-5, height: frame.size.height)
            textLayer.fontSize = 15
            textLayer.alignmentMode = .center
            textLayer.string = "100%"
            textLayer.foregroundColor = .white
            textLayer.position.y = 9.5
        }
        self.addSublayer(textLayer)

        let chargingPath = Bundle(for: PreferencesWindowController.self).path(
            forResource: "bolt.fill",
            ofType: "pdf")

        if chargingPath != nil {
            let cimg = NSImage(contentsOfFile: chargingPath!)
            charging.contents = cimg
            charging.frame.size.height = cimg!.size.height / 6
            charging.frame.size.width = cimg!.size.width / 6
            charging.position.x = -10
            self.addSublayer(charging)
        }
        update()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContentScale(scale: CGFloat) {
        print("sCS ovInner \(scale)")
        self.contentsScale = scale
        textLayer.contentsScale = scale
        charging.contentsScale = scale
    }

    func update() {
        let percent = Battery.getRemainingPercent()

        // Should we put the bolt or not
        if !Battery.isUnplugged() {
            charging.opacity = 1
        } else {
            charging.opacity = 0
        }

        // Update the string
        textLayer.string = "\(percent) %"
    }
}
