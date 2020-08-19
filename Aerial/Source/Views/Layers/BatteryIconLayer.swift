//
//  BatteryIconLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 01/05/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class BatteryIconLayer: AnimationLayer {
    var config: PrefsInfo.Battery?
    var wasSetup = false
    var batteryTimer: Timer?

    var iconLayer: CALayer?
    var textLayer: CATextLayer?
    var charging: CALayer?

    var backupHeight: CGFloat?

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our inits
    override init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        super.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)

        // Always on layers should start with full opacity
        self.opacity = 1
    }

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Battery) {
        self.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
        self.config = config

/*        // Set our layer's font & corner now
        (self.font, self.fontSize) = getFont(name: config.fontName,
                                             size: config.fontSize)*/
        self.corner = config.corner
        iconLayer = CALayer()
        charging = CALayer()
        textLayer = CATextLayer()
    }

    func setup() {
        let imagePath = Bundle(for: PanelWindowController.self).path(
            forResource: "battery.0",
            ofType: "pdf")

        guard let img = NSImage(contentsOfFile: imagePath!) else {
            errorLog("BatteryIconLayer couldn't load the icon files")
            return
        }

        iconLayer!.frame.size.height = img.size.height / 3
        iconLayer!.frame.size.width = img.size.width / 3
        iconLayer!.anchorPoint = CGPoint(x: 1, y: 1)
        iconLayer!.contents = img

        frame.size.height = iconLayer!.frame.size.height + 10
        frame.size.width = iconLayer!.frame.size.width + 20

        // We need that for later
        backupHeight = frame.size.height

        iconLayer!.position.x = frame.size.width
        iconLayer!.position.y = frame.size.height

        textLayer!.frame = CGRect(x: 20, y: 0,
                                  width: iconLayer!.frame.size.width-5,
                                  height: iconLayer!.frame.size.height)
        textLayer!.fontSize = 15
        textLayer!.alignmentMode = .center
        textLayer!.string = "100%"
        textLayer!.foregroundColor = .white
        textLayer!.position.y = 19.5

        self.addSublayer(iconLayer!)
        self.addSublayer(textLayer!)

        let chargingPath = Bundle(for: PanelWindowController.self).path(
            forResource: "bolt.fill",
            ofType: "pdf")

        if chargingPath != nil {
            let cimg = NSImage(contentsOfFile: chargingPath!)
            charging!.contents = cimg
            charging!.frame.size.height = cimg!.size.height / 6
            charging!.frame.size.width = cimg!.size.width / 6
            charging!.anchorPoint = CGPoint(x: 0, y: 0.5)
            charging!.position.y = frame.size.height/2+5
            charging!.position.x = 2
            self.addSublayer(charging!)
        }

    }

    override func setContentScale(scale: CGFloat) {
        self.contentsScale = scale
        iconLayer!.contentsScale = scale
        textLayer!.contentsScale = scale
        charging!.contentsScale = scale
    }

    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        // Only run this once
        if !wasSetup {
            wasSetup = true

            setup()

            // Update also moves and align everything... So we call it here
            self.updateStatus()
            self.update()

            if #available(OSX 10.12, *) {
                batteryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (_) in
                        self.updateStatus()
                        self.update()
                    })
            }

            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")
        }
    }

    func updateStatus() {
        let percent = Battery.getRemainingPercent()

        if PrefsInfo.battery.disableWhenFull {
            if percent == 100 {
                opacity = 0
                frame.size.height = 1
            } else {
                opacity = 1
                frame.size.height = backupHeight!
            }
        }

        // Should we put the bolt or not
        if !Battery.isUnplugged() {
            charging!.opacity = 1
        } else {
            charging!.opacity = 0
        }

        // Update the string
        textLayer!.string = "\(percent) %"
    }
}
