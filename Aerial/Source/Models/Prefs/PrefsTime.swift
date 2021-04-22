//
//  PrefsTime.swift
//  Aerial
//
//  Created by Guillaume Louel on 21/01/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

enum TimeMode: Int {
    case disabled, nightShift, manual, lightDarkMode, coordinates, locationService
}

enum SolarMode: Int {
    case strict, official, civil, nautical, astronomical
}

struct PrefsTime {
    // Time Mode
    @SimpleStorage(key: "timeMode", defaultValue: TimeMode.disabled.rawValue)
    static var intTimeMode: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var timeMode: TimeMode {
        get {
            return TimeMode(rawValue: intTimeMode)!
        }
        set(value) {
            intTimeMode = value.rawValue
        }
    }

    // Manually specified sunrise/sunsets
    @SimpleStorage(key: "manualSunrise", defaultValue: "09:00")
    static var manualSunrise: String

    @SimpleStorage(key: "manualSunset", defaultValue: "19:00")
    static var manualSunset: String

    // Manually specified latitude/longitude (strings)
    @SimpleStorage(key: "latitude", defaultValue: "")
    static var latitude: String

    @SimpleStorage(key: "longitude", defaultValue: "")
    static var longitude: String

    // Solar Mode
    @SimpleStorage(key: "solarMode", defaultValue: SolarMode.official.rawValue)
    static var intSolarMode: Int

    // Prefs sunrise/sunset duration
    @SimpleStorage(key: "sunEventWindow", defaultValue: 60*180)
    static var sunEventWindow: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var solarMode: SolarMode {
        get {
            return SolarMode(rawValue: intSolarMode)!
        }
        set(value) {
            intSolarMode = value.rawValue
        }
    }

    // Override on macOS dark mode
    @SimpleStorage(key: "darkModeNightOverride", defaultValue: false)
    static var darkModeNightOverride: Bool

    // Last successful coordinates, we're going to save those so we can reuse them if we can't get
    // Anything from Location Services (laptop plugged on ethernet with wifi off is the scenario)
    @SimpleStorage(key: "cachedLatitude", defaultValue: 0)
    static var cachedLatitude: Double

    @SimpleStorage(key: "cachedLongitude", defaultValue: 0)
    static var cachedLongitude: Double

    // Last geocoded string, the result is stored in cachedLatitude/cachedLongitude above
    @SimpleStorage(key: "geocodedString", defaultValue: "")
    static var geocodedString: String

}
