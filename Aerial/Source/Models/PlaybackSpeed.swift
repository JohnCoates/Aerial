//
//  PlaybackSpeed.swift
//  Aerial
//
//  Created by Guillaume Louel on 08/07/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Foundation

struct PlaybackSpeed {
    static func forVideo(_ id: String) -> Float {
        if let value = PrefsVideos.playbackSpeed[id] {
            return value
        } else {
            return 1
        }
    }

    static func update(video: String, value: Float) {
        // Just in case...
        if value == 0 {
            PrefsVideos.playbackSpeed[video] = 0.01
        } else {
            PrefsVideos.playbackSpeed[video] = value
        }
    }

    static func reset(video: String) {
        PrefsVideos.playbackSpeed[video] = 1
    }
}
