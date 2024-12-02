//
//  PrefsAdvanced.swift
//  Aerial
//
//  Created by Guillaume Louel on 23/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

struct PrefsAdvanced {
    // Display margins
    @SimpleStorage(key: "muteSound", defaultValue: true)
    static var muteSound: Bool

    @SimpleStorage(key: "muteGlobalSound", defaultValue: false)
    static var muteGlobalSound: Bool
    
    @SimpleStorage(key: "autoPlayPreviews", defaultValue: true)
    static var autoPlayPreviews: Bool

    @SimpleStorage(key: "firstTimeSetup", defaultValue: false)
    static var firstTimeSetup: Bool

    @SimpleStorage(key: "favorOrientation", defaultValue: true)
    static var favorOrientation: Bool
    
    // Invert colors
    @SimpleStorage(key: "invertColors", defaultValue: false)
    static var invertColors: Bool
    
    // Debug mode
    @SimpleStorage(key: "debugMode", defaultValue: false)
    static var debugMode: Bool

    // OVerride Language
    @SimpleStorage(key: "ciOverrideLanguage", defaultValue: "")
    static var ciOverrideLanguage: String

    @SimpleStorage(key: "newDisplayDict", defaultValue: [String: Bool]())
    static var newDisplayDict: [String: Bool]
    
    
}
