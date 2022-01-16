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

enum NewShouldPlay: Int {
    case location, favorites, time, scene, source
}

enum RefreshPeriodicity: Int {
    case weekly, monthly, never
}

struct PrefsVideos {
    // Main playback mode after v2.5
    @SimpleStorage(key: "intNewShouldPlay", defaultValue: NewShouldPlay.location.rawValue)
    static var intNewShouldPlay: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var newShouldPlay: NewShouldPlay {
        get {
            return NewShouldPlay(rawValue: intNewShouldPlay)!
        }
        set(value) {
            intNewShouldPlay = value.rawValue
        }
    }

    // Main playback mode (deprecated in 2.5)
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

    // Starting with v2.5
    @SimpleStorage(key: "newShouldPlayString", defaultValue: [])
    static var newShouldPlayString: [String]

    // Deprecated in v2.5
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

    // How often should we look for new videos ?
    @SimpleStorage(key: "intRefreshPeriodicity",
                   defaultValue: PrefsCache.enableManagement
                    ? RefreshPeriodicity.monthly.rawValue
                    : RefreshPeriodicity.never.rawValue)
    static var intRefreshPeriodicity: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var refreshPeriodicity: RefreshPeriodicity {
        get {
            return RefreshPeriodicity(rawValue: intRefreshPeriodicity)!
        }
        set(value) {
            intRefreshPeriodicity = value.rawValue
        }
    }

    // Allow video skips with right arrow key (on supporting OSes)
    @SimpleStorage(key: "allowSkips", defaultValue: true)
    static var allowSkips: Bool

    @SimpleStorage(key: "sourcesEnabled", defaultValue: ["tvOS 15": true,
                                                         "tvOS 13": false,
                                                         "tvOS 12": false,
                                                         "tvOS 11": false,
                                                         "tvOS 10": false ])
    static var enabledSources: [String: Bool]

    // Favorites (we use the video ID)
    @SimpleStorage(key: "favorites", defaultValue: [])
    static var favorites: [String]

    // Hidden list (same)
    @SimpleStorage(key: "hidden", defaultValue: [])
    static var hidden: [String]

    @SimpleStorage(key: "vibrance", defaultValue: [:])
    static var vibrance: [String: Double]

    @SimpleStorage(key: "durationCache", defaultValue: [:])
    static var durationCache: [String: Double]

    @SimpleStorage(key: "playbackSpeed", defaultValue: [:])
    static var playbackSpeed: [String: Float]

    @SimpleStorage(key: "globalVibrance", defaultValue: 0)
    static var globalVibrance: Double

    @SimpleStorage(key: "allowPerVideoVibrance", defaultValue: false)
    static var allowPerVideoVibrance: Bool

    static private func intervalSinceLastVideoCheck() -> TimeInterval {
        let preferences = Preferences.sharedInstance
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale.init(identifier: "en_GB")
        let dateObj = dateFormatter.date(from: preferences.lastVideoCheck!)!

        // debugLog("Last manifest check : \(dateObj)")

        return dateObj.timeIntervalSinceNow
    }

    static func saveLastVideoCheck() {
        let preferences = Preferences.sharedInstance
        let dateFormatter = DateFormatter()
        let current = Date()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        preferences.lastVideoCheck = dateFormatter.string(from: current)
    }

    static func shouldCheckForNewVideos() -> Bool {
        if refreshPeriodicity == .never {
            return false
        }

        var dayCheck = 7
        if refreshPeriodicity == .monthly {
            dayCheck = 30
        }

        // debugLog("Interval : \(intervalSinceLastVideoCheck())")
        if Int(intervalSinceLastVideoCheck()) < -dayCheck * 86400 {
            // debugLog("Checking for new videos")
            return true
        } else {
            // debugLog("No need to check for new videos")
            return false
        }
    }
}
