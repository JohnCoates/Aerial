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

enum FadeMode: Int {
    // swiftlint:disable:next identifier_name
    case disabled, t0_5, t1, t2
}

enum ShouldPlay: Int {
    case everything, favorites, location, time, scene, source, collection
}

struct PrefsVideos {
    // Main playback mode
    @SimpleStorage(key: "intShouldPlay", defaultValue: ShouldPlay.everything.rawValue)
    static var intShouldPlay: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var shouldPlay: ShouldPlay {
        get {
            return ShouldPlay(rawValue: intShouldPlay)!
        }
        set(value) {
            intShouldPlay = value.rawValue
        }
    }

    @SimpleStorage(key: "shouldPlayString", defaultValue: "")
    static var shouldPlayString: String

    // What do we do on battery ?
    @SimpleStorage(key: "intOnBatteryMode", defaultValue: OnBatteryMode.keepEnabled.rawValue)
    static var intOnBatteryMode: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var onBatteryMode: OnBatteryMode {
        get {
            return OnBatteryMode(rawValue: intOnBatteryMode)!
        }
        set(value) {
            intOnBatteryMode = value.rawValue
        }
    }

    // Internal storage for video format
    @SimpleStorage(key: "intVideoFormat", defaultValue: VideoFormat.v1080pH264.rawValue)
    static var intVideoFormat: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var videoFormat: VideoFormat {
        get {
            return VideoFormat(rawValue: intVideoFormat)!
        }
        set(value) {
            intVideoFormat = value.rawValue
        }
    }

    // Video fade in/out mode
    @SimpleStorage(key: "fadeMode", defaultValue: FadeMode.t1.rawValue)
    static var intFadeMode: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var fadeMode: FadeMode {
        get {
            return FadeMode(rawValue: intFadeMode)!
        }
        set(value) {
            intFadeMode = value.rawValue
        }
    }

    // Allow video skips with right arrow key (on supporting OSes)
    @SimpleStorage(key: "allowSkips", defaultValue: true)
    static var allowSkips: Bool

    @SimpleStorage(key: "sourcesEnabled", defaultValue: ["tvOS 13": true,
                                                         "tvOS 12": false,
                                                         "tvOS 11": false,
                                                         "tvOS 10": false, ])
    static var enabledSources: [String: Bool]

    // Favorites (we use the video ID)
    @SimpleStorage(key: "favorites", defaultValue: [])
    static var favorites: [String]

    // Hidden list (same)
    @SimpleStorage(key: "hidden", defaultValue: [])
    static var hidden: [String]

}
