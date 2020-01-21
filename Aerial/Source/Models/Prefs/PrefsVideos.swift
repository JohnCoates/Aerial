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

struct PrefsVideos {
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
}
