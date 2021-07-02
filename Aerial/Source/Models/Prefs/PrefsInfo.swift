//
//  PrefsInfo.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation
import ScreenSaver

protocol CommonInfo {
    var isEnabled: Bool { get set }
    var fontName: String { get set }
    var fontSize: Double { get set }
    var corner: InfoCorner { get set }
    var displays: InfoDisplays { get set }
}

// Helper Enums for the common infos
enum InfoCorner: Int, Codable {
    case topLeft, topCenter, topRight, bottomLeft, bottomCenter, bottomRight, screenCenter, random, absTopRight
}

enum InfoDisplays: Int, Codable {
    case allDisplays, mainOnly, secondaryOnly
}

enum InfoTime: Int, Codable {
    case always, tenSeconds
}

enum InfoClockFormat: Int, Codable {
    case tdefault, t24hours, t12hours, custom
}

enum InfoDate: Int, Codable {
    case textual, compact, custom
}

enum InfoIconText: Int, Codable {
    case text, icon
}

enum InfoCountdownMode: Int, Codable {
    case preciseDate, timeOfDay
}

enum InfoLocationMode: Int, Codable {
    case useCurrent, manuallySpecify
}

enum InfoDegree: Int, Codable {
    case celsius, fahrenheit
}

enum InfoIconsWeather: Int, Codable {
    case flat, colorflat, oweather
}

// The various info types available
enum InfoType: String, Codable {
    case location, message, clock, date, battery, updates, weather, countdown, timer, music
}

enum InfoMessageType: Int, Codable {
    case text, shell, textfile
}

enum InfoRefreshPeriodicity: Int, Codable {
    case never, tenseconds, thirtyseconds, oneminute, fiveminutes, tenminutes
}

enum InfoWeatherMode: Int, Codable {
    case current, forecast6hours, forecast3days, forecast5days
}

enum InfoWeatherWind: Int, Codable {
    case kph, mps
}

// swiftlint:disable:next type_body_length
struct PrefsInfo {
    struct Location: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var time: InfoTime
    }

    struct Message: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var message: String
        var shellScript: String
        var textFile: String
        var messageType: InfoMessageType
        var refreshPeriodicity: InfoRefreshPeriodicity
    }

    struct Clock: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var showSeconds: Bool
        var hideAmPm: Bool
        var clockFormat: InfoClockFormat
    }

    struct IDate: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var format: InfoDate
        var withYear: Bool
    }

    struct Weather: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var locationMode: InfoLocationMode
        var locationString: String
        var degree: InfoDegree
        var icons: InfoIconsWeather
        var mode: InfoWeatherMode
        var showHumidity: Bool
        var showWind: Bool
        var showCity: Bool
    }

    struct Battery: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var mode: InfoIconText
        var disableWhenFull: Bool
    }

    struct Updates: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var betaReset: Bool // This is useless, just to reload default settings for users of 1.7.2 early betas
    }

    struct Countdown: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var mode: InfoCountdownMode
        var targetDate: Date
        var enforceInterval: Bool
        var triggerDate: Date
        var showSeconds: Bool
    }

    struct Timer: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var duration: Date
        var showSeconds: Bool
        var disableWhenElapsed: Bool
        var replaceWithMessage: Bool
        var customMessage: String
    }

    struct Music: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
    }

    // Our array of Info layers. User can reorder the array, and we may periodically add new Info types
    @Storage(key: "layers", defaultValue: [ .message, .clock, .date, .location, .battery, .updates, .weather, .countdown, .timer])
    static var layers: [InfoType]

    // Location information
    @Storage(key: "LayerLocation", defaultValue: Location(isEnabled: true,
                                                           fontName: "Helvetica Neue Medium",
                                                           fontSize: 28,
                                                           corner: .random,
                                                           displays: .allDisplays,
                                                           time: .always))
    static var location: Location

    // Custom string message
    @Storage(key: "LayerMessage", defaultValue: Message(isEnabled: false,
                                                         fontName: "Helvetica Neue Medium",
                                                         fontSize: 20,
                                                         corner: .topCenter,
                                                         displays: .allDisplays,
                                                         message: "Hello there!",
                                                         shellScript: "",
                                                         textFile: "",
                                                         messageType: .text,
                                                         refreshPeriodicity: .tenminutes))
    static var message: Message

    // Clock
    @Storage(key: "LayerClock", defaultValue: Clock(isEnabled: true,
                                                     fontName: "Helvetica Neue Medium",
                                                     fontSize: 50,
                                                     corner: .bottomLeft,
                                                     displays: .allDisplays,
                                                     showSeconds: true,
                                                     hideAmPm: false,
                                                     clockFormat: .tdefault))
    static var clock: Clock

    // Date
    @Storage(key: "LayerDate", defaultValue: IDate(isEnabled: false,
                                                     fontName: "Helvetica Neue Thin",
                                                     fontSize: 25,
                                                     corner: .bottomLeft,
                                                     displays: .allDisplays,
                                                     format: .textual,
                                                     withYear: false))
    static var date: IDate

    // Battery
    @Storage(key: "LayerBattery", defaultValue: Battery(isEnabled: false,
                                                     fontName: "Helvetica Neue Medium",
                                                     fontSize: 20,
                                                     corner: .topRight,
                                                     displays: .allDisplays,
                                                     mode: .icon,
                                                     disableWhenFull: false))
    static var battery: Battery

    // Updates
    @Storage(key: "LayerUpdates", defaultValue: Updates(isEnabled: true,
                                                     fontName: "Helvetica Neue Medium",
                                                     fontSize: 20,
                                                     corner: .topRight,
                                                     displays: .allDisplays,
                                                     betaReset: true))
    static var updates: Updates

    // Weather
    @Storage(key: "LayerWeather", defaultValue: Weather(isEnabled: false,
                                                        fontName: "Helvetica Neue Medium",
                                                        fontSize: 40,
                                                        corner: .topRight,
                                                        displays: .allDisplays,
                                                        locationMode: .manuallySpecify,
                                                        locationString: "",
                                                        degree: .celsius,
                                                        icons: isMacOS11() ? .colorflat : .flat,
                                                        mode: .current,
                                                        showHumidity: true,
                                                        showWind: true,
                                                        showCity: true))
    static var weather: Weather

    // Text fade in/out mode
    @SimpleStorage(key: "weatherWindMode", defaultValue: InfoWeatherWind.kph.rawValue)
    static var intWeatherWindMode: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var weatherWindMode: InfoWeatherWind {
        get {
            return InfoWeatherWind(rawValue: intWeatherWindMode)!
        }
        set(value) {
            intWeatherWindMode = value.rawValue
        }
    }

    // Music
    @Storage(key: "LayerMusic", defaultValue: Music(isEnabled: true,
                                                     fontName: "Helvetica Neue Medium",
                                                     fontSize: 20,
                                                     corner: .topRight,
                                                     displays: .allDisplays))
    static var music: Music

    // Apple Music storefront to be used
    @SimpleStorage(key: "appleMusicStoreFront", defaultValue: "United States")
    static var appleMusicStoreFront: String

    // Apple Music storefront to be used
    @SimpleStorage(key: "musicProvider", defaultValue: "Apple Music")
    static var musicProvider: String

    // Countdown
    @Storage(key: "LayerCountdown", defaultValue: Countdown(isEnabled: false,
                                                     fontName: "Helvetica Neue Medium",
                                                     fontSize: 100,
                                                     corner: .screenCenter,
                                                     displays: .allDisplays,
                                                     mode: .timeOfDay,
                                                     targetDate: Date(),
                                                     enforceInterval: false,
                                                     triggerDate: Date(),
                                                     showSeconds: true))
    static var countdown: Countdown

    // Timer
    @Storage(key: "LayerTimer", defaultValue: Timer(isEnabled: false,
                                                    fontName: "Helvetica Neue Medium",
                                                    fontSize: 100,
                                                    corner: .screenCenter,
                                                    displays: .allDisplays,
                                                    duration: Date(timeIntervalSince1970: 300),
                                                    showSeconds: true,
                                                    disableWhenElapsed: true,
                                                    replaceWithMessage: false,
                                                    customMessage: ""))

    static var timer: Timer

    @SimpleStorage(key: "customDateFormat", defaultValue: "")
    static var customDateFormat: String

    @SimpleStorage(key: "customTimeFormat", defaultValue: "")
    static var customTimeFormat: String

    // MARK: - Advanced text settings

    // Text fade in/out mode
    @SimpleStorage(key: "fadeModeText", defaultValue: FadeMode.t1.rawValue)
    static var intFadeModeText: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var fadeModeText: FadeMode {
        get {
            return FadeMode(rawValue: intFadeModeText)!
        }
        set(value) {
            intFadeModeText = value.rawValue
        }
    }

    // Fast rendering mode
    @SimpleStorage(key: "highQualityTextRendering", defaultValue: false)
    static var highQualityTextRendering: Bool

    // Override margins
    @SimpleStorage(key: "overrideMargins", defaultValue: false)
    static var overrideMargins: Bool

    @SimpleStorage(key: "marginX", defaultValue: 50)
    static var marginX: Int
    @SimpleStorage(key: "marginY", defaultValue: 50)
    static var marginY: Int

    // MARK: - Shadows
    // Shadow radius
    @SimpleStorage(key: "shadowRadius", defaultValue: 2)
    static var shadowRadius: Int
    @SimpleStorage(key: "shadowOpacity", defaultValue: 1.0)
    static var shadowOpacity: Float
    @SimpleStorage(key: "shadowOffsetX", defaultValue: 0.0)
    static var shadowOffsetX: CGFloat
    @SimpleStorage(key: "shadowOffsetY", defaultValue: -3.0)
    static var shadowOffsetY: CGFloat

    static func isMacOS11() -> Bool {
        if #available(macOS 11.0, *) {
            return true
        } else {
            return false
        }
    }

    // MARK: - Helpers
    // Helper to quickly access a given struct (read-only as we return a copy of the struct)
    static func ofType(_ type: InfoType) -> CommonInfo {
        switch type {
        case .location:
            return location
        case .message:
            return message
        case .clock:
            return clock
        case .date:
            return date
        case .battery:
            return battery
        case .updates:
            return updates
        case .weather:
            return weather
        case .countdown:
            return countdown
        case .timer:
            return timer
        case .music:
            return music
        }
    }

    // Helpers to store the value for the common properties of all info layers
    static func setEnabled(_ type: InfoType, value: Bool) {
        switch type {
        case .location:
            location.isEnabled = value
        case .message:
            message.isEnabled = value
        case .clock:
            clock.isEnabled = value
        case .date:
            date.isEnabled = value
        case .battery:
            battery.isEnabled = value
        case .updates:
            updates.isEnabled = value
        case .weather:
            weather.isEnabled = value
        case .countdown:
            countdown.isEnabled = value
        case .timer:
            timer.isEnabled = value
        case .music:
            music.isEnabled = value
        }
    }

    static func setFontName(_ type: InfoType, name: String) {
        switch type {
        case .location:
            location.fontName = name
        case .message:
            message.fontName = name
        case .clock:
            clock.fontName = name
        case .date:
            date.fontName = name
        case .battery:
            battery.fontName = name
        case .updates:
            updates.fontName = name
        case .weather:
            weather.fontName = name
        case .countdown:
            countdown.fontName = name
        case .timer:
            timer.fontName = name
        case .music:
            music.fontName = name
        }
    }

    static func setFontSize(_ type: InfoType, size: Double) {
        switch type {
        case .location:
            location.fontSize = size
        case .message:
            message.fontSize = size
        case .clock:
            clock.fontSize = size
        case .date:
            date.fontSize = size
        case .battery:
            battery.fontSize = size
        case .updates:
            updates.fontSize = size
        case .weather:
            weather.fontSize = size
        case .countdown:
            countdown.fontSize = size
        case .timer:
            timer.fontSize = size
        case .music:
            music.fontSize = size
        }
    }

    static func setCorner(_ type: InfoType, corner: InfoCorner) {
        switch type {
        case .location:
            location.corner = corner
        case .message:
            message.corner = corner
        case .clock:
            clock.corner = corner
        case .date:
            date.corner = corner
        case .battery:
            battery.corner = corner
        case .updates:
            updates.corner = corner
        case .weather:
            weather.corner = corner
        case .countdown:
            countdown.corner = corner
        case .timer:
            timer.corner = corner
        case .music:
            music.corner = corner
        }

    }
    static func setDisplayMode(_ type: InfoType, mode: InfoDisplays) {
        switch type {
        case .location:
            location.displays = mode
        case .message:
            message.displays = mode
        case .clock:
            clock.displays = mode
        case .date:
            date.displays = mode
        case .battery:
            battery.displays = mode
        case .updates:
            updates.displays = mode
        case .weather:
            weather.displays = mode
        case .countdown:
            countdown.displays = mode
        case .timer:
            timer.displays = mode
        case .music:
            music.displays = mode
        }
    }

    // This may be a temp workaround, will depend on where it goes
    // We periodically add new types so we must add them
    static func updateLayerList() {
        if !PrefsInfo.layers.contains(.battery) {
            PrefsInfo.layers.append(.battery)
        }

        if !PrefsInfo.layers.contains(.countdown) {
            PrefsInfo.layers.append(.countdown)
        }

        if !PrefsInfo.layers.contains(.timer) {
            PrefsInfo.layers.append(.timer)
        }

        if !PrefsInfo.layers.contains(.date) {
            PrefsInfo.layers.append(.date)
        }

        if !PrefsInfo.layers.contains(.weather) {
            PrefsInfo.layers.append(.weather)
        }

        if !PrefsInfo.layers.contains(.music) {
            PrefsInfo.layers.append(.music)
        }

        // Annnd for backward compatibility with 1.7.2 betas, remove the updates that was once here ;)
        if PrefsInfo.layers.contains(.updates) {
            PrefsInfo.layers.remove(at: PrefsInfo.layers.firstIndex(of: .updates)!)
        }
    }
}

// This retrieves/store any type of property in our plist
@propertyWrapper struct Storage<T: Codable> {
    private let key: String
    private let defaultValue: T
    private let module = "com.JohnCoates.Aerial"

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            if let userDefaults = ScreenSaverDefaults(forModuleWithName: module) {
                // We shoot for a string in the new system
                if let jsonString = userDefaults.string(forKey: key) {
                    guard let jsonData = jsonString.data(using: .utf8) else {
                        return defaultValue
                    }
                    guard let value = try? JSONDecoder().decode(T.self, from: jsonData) else {
                        return defaultValue
                    }
                    return value
                } else {
                    // Old time users may have the prefs stored as a data blob though
                    if let data = userDefaults.object(forKey: key) as? Data {
                        let value = try? JSONDecoder().decode(T.self, from: data)
                        return value ?? defaultValue
                    } else {
                        return defaultValue
                    }
                }
            }

            return defaultValue
        }
        set {
            let encoder = JSONEncoder()
            if #available(OSX 10.13, *) {
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            } else {
                encoder.outputFormatting = [.prettyPrinted]
            }

            let jsonData = try? encoder.encode(newValue)
            let jsonString = String(bytes: jsonData!, encoding: .utf8)

            if let userDefaults = ScreenSaverDefaults(forModuleWithName: module) {
                // Set value to UserDefaults
                userDefaults.set(jsonString, forKey: key)

                // We force the sync so the settings are automatically saved
                // This is needed as the System Preferences instance of Aerial
                // is a separate instance from the screensaver ones
                userDefaults.synchronize()
            } else {
                errorLog("UserDefaults set failed for \(key)")
            }
        }
    }
}

// This retrieves store "simple" types that are natively storable on plists
@propertyWrapper struct SimpleStorage<T> {
    private let key: String
    private let defaultValue: T
    private let module = "com.JohnCoates.Aerial"

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            if let userDefaults = ScreenSaverDefaults(forModuleWithName: module) {
                return userDefaults.object(forKey: key) as? T ?? defaultValue
            }

            return defaultValue
        }
        set {
            if let userDefaults = ScreenSaverDefaults(forModuleWithName: module) {
                userDefaults.set(newValue, forKey: key)

                userDefaults.synchronize()
            }
        }
    }
}
