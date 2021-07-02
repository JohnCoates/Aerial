//
//  ClockLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 12/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class ClockLayer: AnimationTextLayer {
    var config: PrefsInfo.Clock?
    var wasSetup = false
    var clockTimer: Timer?

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

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Clock) {
        self.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
        self.config = config

        // Set our layer's font & corner now
        (self.font, self.fontSize) = getFont(name: config.fontName,
                                             size: config.fontSize)
        self.corner = config.corner
    }

    // Called at each new video, we only setup once though !
    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        // Only run this once
        if !wasSetup {
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
        var locale = Locale.current

        let preferences = Preferences.sharedInstance
        if preferences.ciOverrideLanguage != "" {
            locale = Locale(identifier: preferences.ciOverrideLanguage!)
        }

        // Handle the manual override
        if PrefsInfo.clock.clockFormat == .t12hours {
            locale = Locale(identifier: "en_US")
        } else if PrefsInfo.clock.clockFormat != .custom {
            locale = Locale(identifier: "fr_FR")
        }

        let dateFormatter = DateFormatter()
        if config!.clockFormat == .custom {
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: PrefsInfo.customTimeFormat, options: 0, locale: locale)
        } else {
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: config!.showSeconds
                ? "j:mm:ss"
                : "j:mm", options: 0, locale: locale)
        }

        if config!.hideAmPm {
            dateFormatter.amSymbol = ""
            dateFormatter.pmSymbol = ""
        }

        return dateFormatter.string(from: Date())
    }
}
