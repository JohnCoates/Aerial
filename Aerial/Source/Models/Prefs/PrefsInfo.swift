//
//  PrefsInfo.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation
import ScreenSaver

enum InfoCorner: Int, Codable {
    case topLeft, topCenter, topRight, bottomLeft, bottomCenter, bottomRight, screenCenter, random
}

enum InfoDisplays: Int, Codable {
    case allDisplays, mainOnly, secondaryOnly
}

enum InfoType: String, Codable {
    case location, message, clock
}

enum InfoTime: Int, Codable {
    case always, tenSeconds
}

struct PrefsInfo {

    struct Location: Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var time: InfoTime
    }

    struct Message: Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var message: String
    }

    struct Clock: Codable {
        var isEnabled: Bool
        var fontName: String
        var fontSize: Double
        var corner: InfoCorner
        var displays: InfoDisplays
        var showSeconds: Bool
    }

    // Our array of Info layers. User can reorder the array, and we may periodically add new Info
    @Storage(key: "layers", defaultValue: [.location, .message, .clock])
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
}

@propertyWrapper struct Storage<T: Codable> {
    private let key: String
    private let defaultValue: T

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            let module = "com.JohnCoates.Aerial"
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

            let module = "com.JohnCoates.Aerial"
            if let userDefaults = ScreenSaverDefaults(forModuleWithName: module) {
                // Set value to UserDefaults
                userDefaults.set(data, forKey: key)
            } else {
                errorLog("UserDefaults set failed for \(key)")
            }
        }
    }
}
