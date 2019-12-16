//
//  MessageLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 12/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import AVKit

class MessageLayer: AnimationLayer {
    var wasSetup = false

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our init
    override init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        super.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)

        // We start with a full opacity
        self.opacity = 1
    }

    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        let preferences = Preferences.sharedInstance

        // Only run this once, if enabled
        if !wasSetup && preferences.showMessage && preferences.showMessageString != "" {
            wasSetup = true

            update(string: preferences.showMessageString!)
            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")
        }
    }
}
