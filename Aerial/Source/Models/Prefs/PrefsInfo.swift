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

enum InfoCorner: Int, Codable {
    case topLeft, topCenter, topRight, bottomLeft, bottomCenter, bottomRight, screenCenter, random
}

enum InfoDisplays: Int, Codable {
    case allDisplays, mainOnly, secondaryOnly
}

enum InfoType: String, Codable {
    case location, message, clock, battery
}

enum InfoTime: Int, Codable {
    case always, tenSeconds
}

enum InfoIconText: Int, Codable {
    case textOnly, iconAndText, iconOnly
}

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
    }

    struct Clock: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var showSeconds: Bool
    }

    struct Battery: CommonInfo, Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var mode: InfoIconText
    }

    // Our array of Info layers. User can reorder the array, and we may periodically add new Info types
    @Storage(key: "layers", defaultValue: [ .message, .clock, .location, .battery])
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
                                                         message: "Hello there!"))
    static var message: Message

    // Clock
    @Storage(key: "LayerClock", defaultValue: Clock(isEnabled: true,
                                                     fontName: "Helvetica Neue Medium",
                                                     fontSize: 50,
                                                     corner: .bottomLeft,
                                                     displays: .allDisplays,
                                                     showSeconds: true))
    static var clock: Clock

    // Battery
    @Storage(key: "LayerBattery", defaultValue: Battery(isEnabled: true,
                                                     fontName: "Helvetica Neue Medium",
                                                     fontSize: 20,
                                                     corner: .topRight,
                                                     displays: .allDisplays,
                                                     mode: .textOnly))
    static var battery: Battery

    // Helper to quickly access a given struct (read-only as we return a copy of the struct)
    static func ofType(_ type: InfoType) -> CommonInfo {
        switch type {
        case .location:
            return location
        case .message:
            return message
        case .clock:
            return clock
        case .battery:
            return battery
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
        case .battery:
            battery.isEnabled = value
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
        case .battery:
            battery.fontName = name
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
        case .battery:
            battery.fontSize = size
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
        case .battery:
            battery.corner = corner
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
        case .battery:
            battery.displays = mode
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
                // Read value from UserDefaults
                guard let data = userDefaults.object(forKey: key) as? Data else {
                    // Return defaultValue when no data in UserDefaults
                    return defaultValue
                }

                // Convert data to the desire data type
                let value = try? JSONDecoder().decode(T.self, from: data)
                return value ?? defaultValue
            }

            return defaultValue
        }
        set {
            // Convert newValue to data
            let data = try? JSONEncoder().encode(newValue)

            //let module = "com.JohnCoates.Aerial"
            if let userDefaults = ScreenSaverDefaults(forModuleWithName: module) {
                // Set value to UserDefaults
                userDefaults.set(data, forKey: key)
            } else {
                errorLog("UserDefaults set failed for \(key)")
            }
        }
    }
}

@propertyWrapper
struct SimpleStorage<T> {
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
            }
        }
    }
}
