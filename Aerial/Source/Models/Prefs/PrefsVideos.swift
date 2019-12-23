//
//  PrefsVideos.swift
//  Aerial
//
//  Created by Guillaume Louel on 23/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation

enum VideoFormat: Int, Codable, CaseIterable {
    case v1080pH264, v1080pHEVC, v1080pHDR, v4KHEVC, v4KHDR
}

enum OnBatteryMode: Int, Codable {
    case keepEnabled, alwaysDisabled, disableOnLow
}

struct PrefsVideos {
    @Storage(key: "videoFormat", defaultValue: .v1080pH264)
    static var videoFormat: VideoFormat

    // What do we do on battery ?
    @Storage(key: "onBatteryMode", defaultValue: .keepEnabled)
    static var onBatteryMode: OnBatteryMode
}
