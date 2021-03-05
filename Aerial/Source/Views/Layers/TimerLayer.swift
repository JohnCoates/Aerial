//
//  TimerLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 19/03/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class TimerLayer: AnimationTextLayer {
    var config: PrefsInfo.Timer?
    var wasSetup = false
    var timer: Timer?
    var startTime: Date?
    var endTime: Date?

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

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Timer) {
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
            startTime = Date()  // Now

            let calendar = Calendar.current
            let targetComponent = calendar.dateComponents([.hour, .minute, .second], from: PrefsInfo.timer.duration)
            let timerInSeconds = targetComponent.hour! * 3600 + targetComponent.minute! * 60 + targetComponent.second!
            endTime = startTime?.addingTimeInterval(TimeInterval(timerInSeconds))

            if #available(OSX 10.12, *) {
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                    self.update(string: self.getTimeString())
                })
            }

            update(string: getTimeString())
            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")
        }
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
                dateComponentsFormatter.allowedUnits = [.hour, .minute, .second]
                dateComponentsFormatter.maximumUnitCount = 3
            } else {
                dateComponentsFormatter.allowedUnits = [.hour, .minute]
                dateComponentsFormatter.maximumUnitCount = 2
            }
            dateComponentsFormatter.unitsStyle = .full

            if Date() > endTime! && PrefsInfo.timer.disableWhenElapsed {
                // Disabling for next launch
                PrefsInfo.timer.isEnabled = false

                // We may show a message when the timer is elapsed
                if PrefsInfo.timer.replaceWithMessage {
                    return PrefsInfo.timer.customMessage
                }
            }

            return dateComponentsFormatter.string(from: Date(), to: endTime!) ?? ""
        } else {
            // Fallback on earlier versions
            return ""
        }
    }
}
