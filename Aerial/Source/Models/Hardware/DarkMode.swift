//
//  DarkMode.swift
//  Aerial
//
//  Created by Guillaume Louel on 19/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation

struct DarkMode {
    static func isAvailable() -> (Bool, reason: String) {
        if #available(OSX 10.14, *) {
            if DarkMode.isEnabled() {
                return (true, "Your Mac is currently in Dark Mode")
            } else {
                return (true, "Your Mac is currently in Light Mode")
            }
        } else {
            // Fallback on earlier versions
            return (false, "macOS 10.14 Mojave or above is required")
        }
    }

    static func isEnabled() -> Bool {
        if #available(OSX 10.14, *) {
            let modeString = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
            return (modeString == "Dark")
        } else {
            return false
        }
    }
}
