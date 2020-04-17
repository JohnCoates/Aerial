//
//  WeatherLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class WeatherLayer: AnimationTextLayer {
    var config: PrefsInfo.Weather?
    var wasSetup = false

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

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Weather) {
        self.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
        self.config = config

        // Set our layer's font & corner now
        (self.font, self.fontSize) = getFont(name: config.fontName,
                                             size: config.fontSize)
        self.corner = config.corner
    }

    // Called at each new video, we only setup once though !
    func setupForVideo(video: AerialVideo, player: AVPlayer) {
        // Only run this once
        if !wasSetup {
            wasSetup = true

            update(string: "WeatherLayer")
            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")
        }
    }

}
