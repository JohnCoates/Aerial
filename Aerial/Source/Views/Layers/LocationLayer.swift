//
//  LocationLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 11/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class LocationLayer: AnimationTextLayer {
    var config: PrefsInfo.Location?
    var timeObserver: Any?

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our inits
    override init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        super.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
    }

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Location) {
        self.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
        self.config = config

        // Set our layer's font & corner now
        (self.font, self.fontSize) = getFont(name: config.fontName,
                                             size: config.fontSize)
        self.corner = config.corner
    }

    // We need to clear our callbacks on the player
    override func clear(player: AVPlayer) {
        if timeObserver != nil {
            player.removeTimeObserver(timeObserver!)
            timeObserver = nil
        }
    }

    // Called at each new video
    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        let poiStringProvider = PoiStringProvider.sharedInstance
        // We need to make sure we actually have descriptions to show.
        // Custom videos, and earlier tvOS videos may not
        if poiStringProvider.hasPoiKeys(video: video) {
            // Grab a sorted array of timestamps and the keys
            let (keys, times) = getKeysAndTimestamps(video: video)

            // Animate the very first one on it's own
            var initialKey = keys["0"]!
            // Oh Apple... This is a temporary fix for Coit Tower Night where a key was reused
            if initialKey == "A004_C012_0" && video.id == "b6-4" {
                initialKey = "A004_C012_100"
            }

            let str = poiStringProvider.getString(key: initialKey, video: video)

            let duration = calculateAnimationDuration(times: times, current: times[0], video: video)
            let fadeAnimation = createFadeInOutAnimation(duration: duration)

            update(string: str)
            add(fadeAnimation, forKey: "textfade")

            // AVPlayer requires NSValues of CMTime
            var timevals = [NSValue]()
            for time in times {
                timevals.append(NSValue(time: time))
            }

            // We then callback for each timestamp
            timeObserver = player.addBoundaryTimeObserver(forTimes: timevals, queue: DispatchQueue.main) {
                // find closest timestamp to when we're waking up
                var closest = 1000.0
                var closestTime = CMTime.zero

                for time in times {
                    let ts = time.seconds
                    let distance = abs(ts - player.currentTime().seconds)
                    if distance < closest {
                        closest = distance
                        closestTime = time
                    }
                }

                // Get the string for the current timestamp
                let key = String(format: "%.0f", closestTime.seconds)
                let str = poiStringProvider.getString(key: keys[key]!, video: video)

                let duration = self.calculateAnimationDuration(times: times, current: closestTime, video: video)
                let fadeAnimation = self.createFadeInOutAnimation(duration: duration)

                self.update(string: str)
                self.add(fadeAnimation, forKey: "textfade")
            }
        } else {
            // We don't have any extended description, using Secondary name (location) or video name (City)
            let str: String
            if video.secondaryName != "" {
                str = video.secondaryName
            } else {
                str = video.name
            }

            let duration = self.calculateAnimationDuration(times: [], current: CMTime.zero, video: video)
            let fadeAnimation = self.createFadeInOutAnimation(duration: duration)

            update(string: str)
            add(fadeAnimation, forKey: "textfade")
        }
    }

    // MARK: - Time helpers

    func getKeysAndTimestamps(video: AerialVideo) -> ([String: String], [CMTime]) {
         let poiStringProvider = PoiStringProvider.sharedInstance

         // Collect all the timestamps and keys from the JSON
         // They are store as [Time, Key]
         let keys = poiStringProvider.getPoiKeys(video: video)

         var times = [CMTime]()
         for pkv in keys {
             let timeStamp = Double(pkv.key)!
             times.append(CMTime(seconds: timeStamp, preferredTimescale: 1))
         }

         // The JSON isn't sorted though, so we fix that
         times.sort(by: { $0.seconds < $1.seconds })

         return (keys, times)
     }

     func calculateAnimationDuration(times: [CMTime], current: CMTime, video: AerialVideo) -> Double {
         // We may only show for 10s
         if PrefsInfo.location.time == .tenSeconds {
             return 10
         } else {
             if let idx = times.firstIndex(of: current) {
                 if times.count > idx + 1 {
                     return times[idx+1].seconds - times[idx].seconds - 1
                 }
             }

             // We may not have a video duration, if so show it for 15 mins
             return video.duration > 0 ? video.duration : 900
         }
     }
}
