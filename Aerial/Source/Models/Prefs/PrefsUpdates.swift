//
//  PrefsUpdates.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/02/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

enum UpdateMode: Int {
    case notify, install
}

struct PrefsUpdates {
    // Update Mode when the screensaver runs (notify or install)
    @SimpleStorage(key: "checkForUpdates", defaultValue: true)
    static var checkForUpdates: Bool

    // Update Mode when the screensaver runs (notify or install)
    @SimpleStorage(key: "sparkleUpdateMode", defaultValue: getDefaultUpdateMode())
    static var intSparkleUpdateMode: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var sparkleUpdateMode: UpdateMode {
        get {
            return UpdateMode(rawValue: intSparkleUpdateMode)!
        }
        set(value) {
            intSparkleUpdateMode = value.rawValue
        }
    }

    // On Catalina, we notify by default, on previous OSes we install by default
    static func getDefaultUpdateMode() -> Int {
        if #available(OSX 10.15, *) {
            return UpdateMode.notify.rawValue
        } else {
            return UpdateMode.install.rawValue
        }
    }
}
