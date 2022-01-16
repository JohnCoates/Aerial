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
        makeModern()
        /*makeSettings()
        makeInfos()
        refreshVideos()*/
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

    // This is where we maintain the list of the Sidebar content, this will need to be
    // updated periodically unlike the other sidebars that are static
    /*func refreshVideos() {
        // At the very top, the current rotation
        let onRotation = MenuEntry(name: "Currently playing", path: "videos:rotation:0")

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
    }*/

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
    // swiftlint:disable:next cyclomatic_complexity
    static func iconFor(_ path: String, name: String) -> NSImage? {
        if path.starts(with: "videos:location") {
            return Aerial.getAccentedSymbol("mappin.and.ellipse")
        } else if path.starts(with: "videos:cache") && name == VideoList.instance.cacheDownloaded {
            return Aerial.getAccentedSymbol("internaldrive")
        } else if path.starts(with: "videos:cache") && name == VideoList.instance.cacheOnline {
            return Aerial.getAccentedSymbol("cloud")

        } else if path.starts(with: "videos:time") && name == "Day" {
            return Aerial.getAccentedSymbol("sun.max")
        } else if path.starts(with: "videos:time") && name == "Night" {
            return Aerial.getAccentedSymbol("moon.stars")
        } else if path.starts(with: "videos:time") && name == "Sunrise" {
            return Aerial.getAccentedSymbol("sunrise")
        } else if path.starts(with: "videos:time") && name == "Sunset" {
            return Aerial.getAccentedSymbol("sunset")

        } else if path.starts(with: "videos:scene") && name == "Nature" {
            return Aerial.getAccentedSymbol("leaf")
        } else if path.starts(with: "videos:scene") && name == "City" {
            return Aerial.getAccentedSymbol("tram.fill")
        } else if path.starts(with: "videos:scene") && name == "Space" {
            return Aerial.getAccentedSymbol("sparkles")
        } else if path.starts(with: "videos:scene") && name == "Sea" {
            return Aerial.getAccentedSymbol("helm")
        } else if path.starts(with: "videos:scene") && name == "Beach" {
            return Aerial.getAccentedSymbol("helm")
        } else if path.starts(with: "videos:scene") && name == "Countryside" {
            return Aerial.getAccentedSymbol("helm")

        } else if path.starts(with: "videos:rotation") {
            return Aerial.getAccentedSymbol("dial.min")

        } else if path.starts(with: "videos:favorite") {
            return Aerial.getSymbol("star")

        } else if path.starts(with: "videos:hidden") {
            return Aerial.getAccentedSymbol("eye.slash")

        } else if path.starts(with: "videos:source") {
            return Aerial.getAccentedSymbol("antenna.radiowaves.left.and.right")

        } else if path.starts(with: "videos:") {
            return Aerial.getAccentedSymbol("film")

        } else if path.starts(with: "settings:sources") {
            return Aerial.getAccentedSymbol("antenna.radiowaves.left.and.right")
        } else if path.starts(with: "settings:time") {
            return Aerial.getAccentedSymbol("clock")
        } else if path.starts(with: "settings:displays") {
            return Aerial.getAccentedSymbol("display.2")
        } else if path.starts(with: "settings:brightness") {
            return Aerial.getAccentedSymbol("sun.min")
        } else if path.starts(with: "settings:cache") {
            return Aerial.getAccentedSymbol("internaldrive")
        } else if path.starts(with: "settings:overlays") {
            return Aerial.getAccentedSymbol("text.bubble")
        } else if path.starts(with: "settings:filters") {
            return Aerial.getAccentedSymbol("slider.horizontal.3")
        } else if path.starts(with: "settings:updates") {
            return Aerial.getAccentedSymbol("arrow.down.circle")
        } else if path.starts(with: "settings:advanced") {
            return Aerial.getAccentedSymbol("wrench.and.screwdriver")

        } else if path.starts(with: "infos:help") {
            return Aerial.getAccentedSymbol("bubble.left.and.bubble.right")
        } else if path.starts(with: "infos:credits") {
            return Aerial.getAccentedSymbol("person.3")
        } else if path.starts(with: "infos:about") {
            return Aerial.getAccentedSymbol("info.circle")

        } else if path.starts(with: "modern:nowplaying") {
            return Aerial.getAccentedSymbol("play.circle")

        } else {
            // For the WIP
            return Aerial.getSymbol("wrench")
        }
    }
}
