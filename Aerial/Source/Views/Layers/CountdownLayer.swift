//
//  CountdownLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 13/02/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class CountdownLayer: AnimationTextLayer {
    var config: PrefsInfo.Countdown?
    var wasSetup = false
    var countdownTimer: Timer?

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

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Countdown) {
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

            if shouldCountdown() {
                if #available(OSX 10.12, *) {
                    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                        self.update(string: self.getTimeString())
                    })
                }

                update(string: getTimeString())
                let fadeAnimation = self.createFadeInAnimation()
                add(fadeAnimation, forKey: "textfade")
            }
        }
    }

    func shouldCountdown() -> Bool {
        let now = Date()
        var target = PrefsInfo.countdown.targetDate
        var trigger = PrefsInfo.countdown.triggerDate

        // We ignore the day, in timeOfDay mode by normalizing it to today
        if config!.mode == .timeOfDay {
            target = todayizeDate(target, strict: false)
            trigger = todayizeDate(trigger, strict: true)
        }

        // We only start the countdown if we're later than the trigger
        if config!.enforceInterval {
            if trigger > now {
                return false
            }
        }

        // Are we still before the countdown date or not ?
        if now < target {
            return true
        }

        return false
    }

    func getTimeString() -> String {
        if #available(OSX 10.12, *) {
            // Handle locale
            var locale = Locale(identifier: Locale.preferredLanguages[0])
            let preferences = Preferences.sharedInstance
            if preferences.ciOverrideLanguage != "" {
                locale = Locale(identifier: preferences.ciOverrideLanguage!)
            }

            var calendar = Calendar.current
            calendar.locale = locale

            let dateComponentsFormatter = DateComponentsFormatter()
            dateComponentsFormatter.calendar = calendar

            if config!.showSeconds {
                dateComponentsFormatter.allowedUnits = [.day, .hour, .minute, .second]
                dateComponentsFormatter.maximumUnitCount = 4
            } else {
                dateComponentsFormatter.allowedUnits = [.day, .hour, .minute]
                dateComponentsFormatter.maximumUnitCount = 3
            }
            dateComponentsFormatter.unitsStyle = .full

            var target = PrefsInfo.countdown.targetDate

            // We ignore the day, in timeOfDay mode by normalizing it to today
            if config!.mode == .timeOfDay {
                target = todayizeDate(target, strict: false)
            }

            return dateComponentsFormatter.string(from: Date(), to: target) ?? ""
        } else {
            // Fallback on earlier versions
            return ""
        }
    }
}

extension Date {
    var tomorrow: Date? {
        return Calendar.current.date(byAdding: .day, value: 1, to: self)
    }
}
