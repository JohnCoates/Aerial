//
//  PrefsDisplays.swift
//  Aerial
//
//  Created by Guillaume Louel on 21/01/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

enum DisplayMode: Int {
    case allDisplays, mainOnly, secondaryOnly, selection
}

enum AspectMode: Int {
    case fill, fit
}

enum ViewingMode: Int {
    case independent, cloned, spanned, mirrored
}

struct PrefsDisplays {
    // Display Mode
    @SimpleStorage(key: "newDisplayMode", defaultValue: DisplayMode.allDisplays.rawValue)
    static var intDisplayMode: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var displayMode: DisplayMode {
        get {
            return DisplayMode(rawValue: intDisplayMode)!
        }
        set(value) {
            intDisplayMode = value.rawValue
        }
    }

    // Viewing Mode 
    @SimpleStorage(key: "newViewingMode", defaultValue: ViewingMode.independent.rawValue)
    static var intViewingMode: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var viewingMode: ViewingMode {
        get {
            return ViewingMode(rawValue: intViewingMode)!
        }
        set(value) {
            intViewingMode = value.rawValue
        }
    }

    // Aspect Mode
    @SimpleStorage(key: "aspectMode", defaultValue: AspectMode.fill.rawValue)
    static var intAspectMode: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var aspectMode: AspectMode {
        get {
            return AspectMode(rawValue: intAspectMode)!
        }
        set(value) {
            intAspectMode = value.rawValue
        }
    }

    // Display margins
    @SimpleStorage(key: "displayMarginsAdvanced", defaultValue: false)
    static var displayMarginsAdvanced: Bool

    @SimpleStorage(key: "horizontalMargin", defaultValue: 0)
    static var horizontalMargin: Double

    @SimpleStorage(key: "verticalMargin", defaultValue: 0)
    static var verticalMargin: Double

    // Advanced margins are stored as a string
    @SimpleStorage(key: "advancedMargins", defaultValue: "")
    static var advancedMargins: String
}
