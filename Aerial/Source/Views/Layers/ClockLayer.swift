//
//  ClockLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 12/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import AVKit

class ClockLayer: AnimationLayer {
    var wasSetup = false
    var clockTimer: Timer?

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our init
    override init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        super.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)

        // Always on layers should start with full opacity
        self.opacity = 1
    }

    // Called at each new video, we only setup once though !
    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        let preferences = Preferences.sharedInstance

        // Only run this once, if enabled
        if !wasSetup && preferences.showClock {
            wasSetup = true

            if #available(OSX 10.12, *) {
                clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                    self.update(string: self.getTimeString())
                })
            }

            update(string: getTimeString())
            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")
        }
    }

    func getTimeString() -> String {
        let preferences = Preferences.sharedInstance

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: preferences.withSeconds
            ? "j:mm:ss"
            : "j:mm", options: 0, locale: Locale.current)

        return dateFormatter.string(from: Date())
    }

}
