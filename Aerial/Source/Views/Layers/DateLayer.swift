//
//  DateLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 23/03/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class DateLayer: AnimationTextLayer {
    var config: PrefsInfo.IDate?
    var wasSetup = false
    var dateTimer: Timer?

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

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.IDate) {
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
                dateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                    self.update(string: self.getTimeString())
                })
            }

            update(string: getTimeString())
            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")
        }
    }

    func getTimeString() -> String {
        // Handle locale
        var locale = Locale(identifier: Locale.preferredLanguages[0])
        let preferences = Preferences.sharedInstance
        if preferences.ciOverrideLanguage != "" {
            locale = Locale(identifier: preferences.ciOverrideLanguage!)
        }
        var template = ""

        let dateFormatter = DateFormatter()
        if config!.format == .textual {
            if config!.withYear {
                template = "EEEE, MMMM dd, yyyy"
            } else {
                template = "EEEE, MMMM dd"
            }
        } else if config!.format == .compact {
            if config!.withYear {
                template = "MM/dd/yy"
            } else {
                template = "MM/dd"
            }
        } else {
            template = PrefsInfo.customDateFormat
        }

        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale)
        dateFormatter.locale = locale
        return dateFormatter.string(from: Date()).capitalizeFirstLetter()
    }
}
