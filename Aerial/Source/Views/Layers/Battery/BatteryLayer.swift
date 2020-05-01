//
//  BatteryLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 27/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class BatteryLayer: AnimationTextLayer {
    var config: PrefsInfo.Battery?
    var wasSetup = false
    var batteryTimer: Timer?
    var icon: BatteryIconLayer?

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our inits
    override init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        super.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)

        // We start with a full opacity
        self.opacity = 1
    }

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Battery) {
        self.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
        self.config = config

        // Set our layer's font & corner now
        (self.font, self.fontSize) = getFont(name: config.fontName,
                                             size: config.fontSize)
        self.corner = config.corner

        if config.mode == .icon {
            icon = BatteryIconLayer()
            frame.size = icon!.frame.size
            icon!.anchorPoint = CGPoint(x: 1, y: 0)
            icon!.position = CGPoint(x: 15, y: 0)    // This is probably wrong...
            self.addSublayer(icon!)
        }
    }

    override func setContentScale(scale: CGFloat) {
        print("sCS ov : \(scale)")
        if icon != nil {
            icon!.setContentScale(scale: scale)
        }
    }

    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        // Only run this once
        if !wasSetup {
            wasSetup = true

            if config!.mode == .text {
                update(string: getBatteryString())
            } else {
                /*icon = BatteryIconLayer()
                frame.size = icon!.frame.size
                icon!.anchorPoint = CGPoint(x: 1, y: 0)
                icon!.position = CGPoint(x: 15, y: 0)    // This is probably wrong...
                addSublayer(icon!)*/
                self.update(string: "")
            }

            if #available(OSX 10.12, *) {
                batteryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (_) in
                    if self.config!.mode == .text {
                        self.update(string: self.getBatteryString())
                    } else {
                        self.icon!.update()
                        self.update(string: "")
                    }
                })
            }

            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")
        }
    }

    func getBatteryString() -> String {
        var bstring = ""

        if !Battery.isUnplugged() {
            let percent = Battery.getRemainingPercent()
            if percent == 100 || percent == 0 {
                bstring += "Charged"
            } else {
                bstring += "Charging"
            }
        }

        let percent = Battery.getRemainingPercent()

        if percent > 0 {
            if bstring != "" {
                bstring += ", "
            }

            bstring += "\(percent)%"
        }

        return bstring
    }
}
