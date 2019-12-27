//
//  BatteryLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 27/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class BatteryLayer: AnimationLayer {
    var config: PrefsInfo.Battery?
    var wasSetup = false
    var batteryTimer: Timer?

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
    }

    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        // Only run this once
        if !wasSetup {
            wasSetup = true

            if #available(OSX 10.12, *) {
                batteryTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true, block: { (_) in
                    self.update(string: self.getBatteryString())
                })
            }

            update(string: getBatteryString())

            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")
        }
    }

    func getBatteryString() -> String {
        var bstring = ""

        if !Battery.isUnplugged() {
            bstring += "Plugged-in"
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
