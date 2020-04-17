//
//  UpdatesLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 11/02/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class UpdatesLayer: AnimationTextLayer {
    var config: PrefsInfo.Updates?
    var wasSetup = false
    var updateTimer: Timer?

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

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Updates) {
        self.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
        self.config = config

        // Set our layer's font & corner now
        (self.font, self.fontSize) = getFont(name: config.fontName,
                                             size: config.fontSize)
        self.corner = .absTopRight
    }

    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        if !wasSetup {
            setupUpdateLayer()
        }
    }

    // Setup the layer, but give some time for the probe to complete
    func setupUpdateLayer() {
        let autoupd = AutoUpdates.sharedInstance

        if autoupd.didProbeForUpdate {
            wasSetup = true

            update(string: autoupd.getUpdateString())

            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")
        } else {
            // Ok, let's try again in 10 seconds
            if #available(OSX 10.12, *) {
                updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false, block: { (_) in
                    self.setupUpdateLayer()
                })
            }
        }
    }
}
