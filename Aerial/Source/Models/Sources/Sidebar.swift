//
//  Sidebar.swift
//  Aerial
//
//  Created by Guillaume Louel on 15/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class Sidebar {
    var modern: [Any] = []

    struct Header {
        let name: String
        let entries: [MenuEntry]
    }
    struct MenuEntry {
        let name: String
        let path: String
    }

    static let instance: Sidebar = Sidebar()

    init() {
        makeModern()
    }

    // The new modern menu in 3.0
    func makeModern() {

        modern = [
            Header(name: "Aerials", entries: [
                MenuEntry(name: "Now Playing", path: "modern:nowplaying"),
                MenuEntry(name: "Browse Videos", path: "videos:all"),
                MenuEntry(name: "More Videos", path: "settings:sources")
            ]),
            Header(name: "Settings", entries: [
                MenuEntry(name: "Time", path: "settings:time"),
                MenuEntry(name: "Displays", path: "settings:displays"),
                MenuEntry(name: "Brightness", path: "settings:brightness"),
                MenuEntry(name: "Cache", path: "settings:cache"),
                MenuEntry(name: "Overlays", path: "settings:overlays"),
                MenuEntry(name: "Filters", path: "settings:filters"),
                // MenuEntry(name: "Auto Updates", path: "settings:updates"),
                MenuEntry(name: "Advanced", path: "settings:advanced")
            ]),
            Header(name: "Information", entries: [
                MenuEntry(name: "About", path: "infos:about"),
                MenuEntry(name: "Credits", path: "infos:credits"),
                MenuEntry(name: "Help", path: "infos:help")
            ])
        ]
    }

    // Helper to get the various icons for the sidebar
    // swiftlint:disable:next cyclomatic_complexity
    static func iconFor(_ path: String, name: String) -> NSImage? {
        if path.starts(with: "videos:location") {
            return Aerial.helper.getAccentedSymbol("mappin.and.ellipse")
        } else if path.starts(with: "videos:cache") && name == VideoList.instance.cacheDownloaded {
            return Aerial.helper.getAccentedSymbol("internaldrive")
        } else if path.starts(with: "videos:cache") && name == VideoList.instance.cacheOnline {
            return Aerial.helper.getAccentedSymbol("cloud")

        } else if path.starts(with: "videos:time") && name == "Day" {
            return Aerial.helper.getAccentedSymbol("sun.max")
        } else if path.starts(with: "videos:time") && name == "Night" {
            return Aerial.helper.getAccentedSymbol("moon.stars")
        } else if path.starts(with: "videos:time") && name == "Sunrise" {
            return Aerial.helper.getAccentedSymbol("sunrise")
        } else if path.starts(with: "videos:time") && name == "Sunset" {
            return Aerial.helper.getAccentedSymbol("sunset")

        } else if path.starts(with: "videos:scene") && name == "Nature" {
            return Aerial.helper.getAccentedSymbol("leaf")
        } else if path.starts(with: "videos:scene") && name == "City" {
            return Aerial.helper.getAccentedSymbol("tram.fill")
        } else if path.starts(with: "videos:scene") && name == "Space" {
            return Aerial.helper.getAccentedSymbol("sparkles")
        } else if path.starts(with: "videos:scene") && name == "Sea" {
            return Aerial.helper.getAccentedSymbol("helm")
        } else if path.starts(with: "videos:scene") && name == "Beach" {
            return Aerial.helper.getAccentedSymbol("helm")
        } else if path.starts(with: "videos:scene") && name == "Countryside" {
            return Aerial.helper.getAccentedSymbol("helm")

        } else if path.starts(with: "videos:rotation") {
            return Aerial.helper.getAccentedSymbol("dial.min")

        } else if path.starts(with: "videos:favorite") {
            return Aerial.helper.getSymbol("star")

        } else if path.starts(with: "videos:hidden") {
            return Aerial.helper.getAccentedSymbol("eye.slash")

        } else if path.starts(with: "videos:source") {
            return Aerial.helper.getAccentedSymbol("antenna.radiowaves.left.and.right")

        } else if path.starts(with: "videos:") {
            return Aerial.helper.getAccentedSymbol("film")

        } else if path.starts(with: "settings:sources") {
            return Aerial.helper.getAccentedSymbol("antenna.radiowaves.left.and.right")
        } else if path.starts(with: "settings:time") {
            return Aerial.helper.getAccentedSymbol("clock")
        } else if path.starts(with: "settings:displays") {
            return Aerial.helper.getAccentedSymbol("display.2")
        } else if path.starts(with: "settings:brightness") {
            return Aerial.helper.getAccentedSymbol("sun.min")
        } else if path.starts(with: "settings:cache") {
            return Aerial.helper.getAccentedSymbol("internaldrive")
        } else if path.starts(with: "settings:overlays") {
            return Aerial.helper.getAccentedSymbol("text.bubble")
        } else if path.starts(with: "settings:filters") {
            return Aerial.helper.getAccentedSymbol("slider.horizontal.3")
        } else if path.starts(with: "settings:updates") {
            return Aerial.helper.getAccentedSymbol("arrow.down.circle")
        } else if path.starts(with: "settings:advanced") {
            return Aerial.helper.getAccentedSymbol("wrench.and.screwdriver")

        } else if path.starts(with: "infos:help") {
            return Aerial.helper.getAccentedSymbol("bubble.left.and.bubble.right")
        } else if path.starts(with: "infos:credits") {
            return Aerial.helper.getAccentedSymbol("person.3")
        } else if path.starts(with: "infos:about") {
            return Aerial.helper.getAccentedSymbol("info.circle")

        } else if path.starts(with: "modern:nowplaying") {
            return Aerial.helper.getAccentedSymbol("play.circle")

        } else {
            // For the WIP
            return Aerial.helper.getSymbol("wrench")
        }
    }
}
