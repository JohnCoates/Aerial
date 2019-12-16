//
//  DescriptionLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 11/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import AVKit

class DescriptionLayer: AnimationLayer {
    var timeObserver: Any?

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our init
    override init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        super.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
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
        let preferences = Preferences.sharedInstance

        if preferences.showDescriptions {
            // We need to make sure we actually have descriptions to show.
            // Custom videos, and earlier tvOS videos may not
            if poiStringProvider.hasPoiKeys(video: video) {
                // Grab a sorted array of timestamps and the keys
                let (keys, times) = getKeysAndTimestamps(video: video)

                // Animate the very first one on it's own
                let str = poiStringProvider.getString(key: keys["0"]!, video: video)

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
    }

    // to be removed after corner refactoring below
    override func update(string: String) {
        // Setup string
        self.string = string
        self.isWrapped = true

        (self.font, self.fontSize) = getFont()

        // This is the rect resized to our string
        frame = calculateRect(string: string, font: self.font as! NSFont)
        move(corner: getDescriptionCorner(), fullRedraw: false)
    }

    // TODO, refactor that
    func getDescriptionCorner() -> Preferences.DescriptionCorner {
        let preferences = Preferences.sharedInstance
        var pos: Preferences.DescriptionCorner

        // We may have a random value...
        if preferences.descriptionCorner == Preferences.DescriptionCorner.random.rawValue {
            var corner = Int.random(in: 0...3)

            while corner == lastCorner {
                corner = Int.random(in: 0...3)
            }

            pos = Preferences.DescriptionCorner(rawValue: corner)!
        } else {
            pos = Preferences.DescriptionCorner(rawValue: preferences.descriptionCorner!)!
        }

        return pos
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
         let preferences = Preferences.sharedInstance

         // We may only show for 10s
         if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
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
