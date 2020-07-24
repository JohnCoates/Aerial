//
//  Sidebar.swift
//  Aerial
//
//  Created by Guillaume Louel on 15/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class Sidebar {
    var videos: [Any] = []
    var settings: [Any] = []
    var infos: [Any] = []

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
        makeSettings()
        makeInfos()
        refreshVideos()
    }

    // Settings are static
    func makeSettings() {
        settings = [MenuEntry(name: "Sources", path: "settings:sources"),
                    MenuEntry(name: "Time", path: "settings:time"),
                    MenuEntry(name: "Displays", path: "settings:displays"),
                    MenuEntry(name: "Brightness", path: "settings:brightness"),
                    MenuEntry(name: "Cache", path: "settings:cache"),
                    MenuEntry(name: "Overlays", path: "settings:overlays"),
                    MenuEntry(name: "Auto Updates", path: "settings:updates"),
                    MenuEntry(name: "Advanced", path: "settings:advanced"),
                    ]
    }

    // So is infos
    func makeInfos() {
        infos = [MenuEntry(name: "About", path: "infos:about")]
    }

    // This is where we maintain the list of the Sidebar content, this will need to be
    // updated periodically unlike the other sidebars that are static
    func refreshVideos() {
        // At the very top, the current rotation
        let onRotation = MenuEntry(name: "On Rotation", path: "videos:rotation:0")

        // Favs
        let fav = MenuEntry(name: "Favorites", path: "videos:favorites:0")

        // All videos
        let all = MenuEntry(name: "All videos", path: "videos:all")

        // Cached/uncached
        let cache = Header(name: "Cache",
                           entries: makeEntriesFor(sources: VideoList.instance.getSources(mode: .cache),
                           path: "videos:cache"))

        // Locations
        let locations = Header(name: "Location",
                               entries: makeEntriesFor(sources: VideoList.instance.getSources(mode: .location),
                               path: "videos:location"))

        // Times
        let time = Header(name: "Time",
                          entries: makeEntriesFor(sources: VideoList.instance.getSources(mode: .time),
                          path: "videos:time"))
        // Scenes
        let scene = Header(name: "Scene",
                           entries: makeEntriesFor(sources: VideoList.instance.getSources(mode: .scene),
                           path: "videos:scene"))

        // Sources
        let source = Header(name: "Source",
                           entries: makeEntriesFor(sources: VideoList.instance.getSources(mode: .source),
                           path: "videos:source"))

        // Hidden
        let hidden = MenuEntry(name: "Hidden", path: "videos:hidden:0")

        videos = [onRotation, fav, all, cache, locations, time, scene, source, hidden]
    }

    func makeEntriesFor(sources: [String], path: String) -> [MenuEntry] {
        var entries: [MenuEntry] = []
        var index = 0

        for source in sources {
            entries.append(MenuEntry(name: source, path: path + ":\(index)"))
            index += 1
        }

        return entries
    }

    // Helper to get the various icons for the sidebar
    //swiftlint:disable:next cyclomatic_complexity
    static func iconFor(_ path: String, name: String) -> NSImage? {
        if #available(OSX 10.16, *) {
            if path.starts(with: "videos:location") {
                return NSImage(systemSymbolName: "location", accessibilityDescription: "")
            } else if path.starts(with: "videos:cache") && name == VideoList.instance.cacheDownloaded {
                return NSImage(systemSymbolName: "internaldrive", accessibilityDescription: "")
            } else if path.starts(with: "videos:cache") && name == VideoList.instance.cacheOnline {
                return NSImage(systemSymbolName: "cloud", accessibilityDescription: "")

            } else if path.starts(with: "videos:time") && name == "Day" {
                return NSImage(systemSymbolName: "sun.max", accessibilityDescription: "")
            } else if path.starts(with: "videos:time") && name == "Night" {
                return NSImage(systemSymbolName: "moon.stars", accessibilityDescription: "")
            } else if path.starts(with: "videos:time") && name == "Sunrise" {
                return NSImage(systemSymbolName: "sunrise", accessibilityDescription: "")
            } else if path.starts(with: "videos:time") && name == "Sunset" {
                return NSImage(systemSymbolName: "sunset", accessibilityDescription: "")

            } else if path.starts(with: "videos:scene") && name == "Landscape" {
                return NSImage(systemSymbolName: "leaf", accessibilityDescription: "")
            } else if path.starts(with: "videos:scene") && name == "City" {
                return NSImage(systemSymbolName: "building", accessibilityDescription: "")
            } else if path.starts(with: "videos:scene") && name == "Space" {
                return NSImage(systemSymbolName: "sparkles", accessibilityDescription: "")
            } else if path.starts(with: "videos:scene") && name == "Sea" {
                return NSImage(systemSymbolName: "drop", accessibilityDescription: "")

            } else if path.starts(with: "videos:rotation") {
                return NSImage(systemSymbolName: "dial.min", accessibilityDescription: "")

            } else if path.starts(with: "videos:favorite") {
                return NSImage(systemSymbolName: "star", accessibilityDescription: "")

            } else if path.starts(with: "videos:hidden") {
                return NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "")

            } else if path.starts(with: "videos:source") {
                return NSImage(systemSymbolName: "video.badge.plus", accessibilityDescription: "")

            } else if path.starts(with: "videos:") {
                return NSImage(systemSymbolName: "film", accessibilityDescription: "")

            } else if path.starts(with: "settings:sources") {
                return NSImage(systemSymbolName: "video.badge.plus", accessibilityDescription: "")
            } else if path.starts(with: "settings:time") {
                return NSImage(systemSymbolName: "clock", accessibilityDescription: "")
            } else if path.starts(with: "settings:displays") {
                return NSImage(systemSymbolName: "display.2", accessibilityDescription: "")
            } else if path.starts(with: "settings:brightness") {
                return NSImage(systemSymbolName: "sun.min", accessibilityDescription: "")
            } else if path.starts(with: "settings:cache") {
                return NSImage(systemSymbolName: "internaldrive", accessibilityDescription: "")
            } else if path.starts(with: "settings:overlays") {
                return NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "")
            } else if path.starts(with: "settings:updates") {
                return NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "")
            } else if path.starts(with: "settings:advanced") {
                return NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: "")
            } else if path.starts(with: "info") {
                return NSImage(systemSymbolName: "info.circle", accessibilityDescription: "")
            } else {
                // For the WIP
                return NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "")
            }

        } else {
            return nil
        }

    }
}
