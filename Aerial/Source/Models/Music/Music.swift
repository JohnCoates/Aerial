//
//  Music.swift
//  Aerial
//
//  Created by Guillaume Louel on 29/06/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Foundation
import AppKit

typealias MusicCallback = (SongInfo) -> Void

struct SongInfo {
    let name: String
    let artist: String
    let album: String
    let id: String
}

// swiftlint:disable:next type_body_length
class Music {
    // Album arts are only available for many titles if you are using the same storefront as what
    // the user is using, so we need to have the user configure that.
    //
    // Note : Horribly reversed dictionnary, because NSPopupButtons are terrible!
    let storefronts = ["Algeria": "dz",
                       "Angola": "ao",
                       "Anguilla": "ai",
                       "Antigua and Barbuda": "ag",
                       "Argentina": "ar",
                       "Armenia": "am",
                       "Australia": "au",
                       "Austria": "at",
                       "Azerbaijan": "az",
                       "Bahamas": "bs",
                       "Bahrain": "bh",
                       "Barbados": "bb",
                       "Belarus": "by",
                       "Belgium": "be",
                       "Belize": "bz",
                       "Benin": "bj",
                       "Bermuda": "bm",
                       "Bhutan": "bt",
                       "Bolivia": "bo",
                       "Bosnia and Herzegovina": "ba",
                       "Botswana": "bw",
                       "Brazil": "br",
                       "British Virgin Islands": "vg",
                       "Bulgaria": "bg",
                       "Cambodia": "kh",
                       "Cameroon": "cm",
                       "Canada": "ca",
                       "Cape Verde": "cv",
                       "Cayman Islands": "ky",
                       "Chad": "td",
                       "Chile": "cl",
                       "China mainland": "cn",
                       "Colombia": "co",
                       "Costa Rica": "cr",
                       "Croatia": "hr",
                       "Cyprus": "cy",
                       "Czech Republic": "cz",
                       "Côte d'Ivoire": "ci",
                       "Democratic Republic of the Congo": "cd",
                       "Denmark": "dk",
                       "Dominica": "dm",
                       "Dominican Republic": "do",
                       "Ecuador": "ec",
                       "Egypt": "eg",
                       "El Salvador": "sv",
                       "Estonia": "ee",
                       "Eswatini": "sz",
                       "Fiji": "fj",
                       "Finland": "fi",
                       "France": "fr",
                       "Gabon": "ga",
                       "Gambia": "gm",
                       "Georgia": "ge",
                       "Germany": "de",
                       "Ghana": "gh",
                       "Greece": "gr",
                       "Grenada": "gd",
                       "Guatemala": "gt",
                       "Guinea-Bissau": "gw",
                       "Guyana": "gy",
                       "Honduras": "hn",
                       "Hong Kong": "hk",
                       "Hungary": "hu",
                       "Iceland": "is",
                       "India": "in",
                       "Indonesia": "id",
                       "Iraq": "iq",
                       "Ireland": "ie",
                       "Israel": "il",
                       "Italy": "it",
                       "Jamaica": "jm",
                       "Japan": "jp",
                       "Jordan": "jo",
                       "Kazakhstan": "kz",
                       "Kenya": "ke",
                       "Korea, Republic of": "kr",
                       "Kosovo": "xk",
                       "Kuwait": "kw",
                       "Kyrgyzstan": "kg",
                       "Lao People's Democratic Republic": "la",
                       "Latvia": "lv",
                       "Lebanon": "lb",
                       "Liberia": "lr",
                       "Libya": "ly",
                       "Lithuania": "lt",
                       "Luxembourg": "lu",
                       "Macao": "mo",
                       "Madagascar": "mg",
                       "Malawi": "mw",
                       "Malaysia": "my",
                       "Maldives": "mv",
                       "Mali": "ml",
                       "Malta": "mt",
                       "Mauritania": "mr",
                       "Mauritius": "mu",
                       "Mexico": "mx",
                       "Micronesia, Federated States of": "fm",
                       "Moldova": "md",
                       "Mongolia": "mn",
                       "Montenegro": "me",
                       "Montserrat": "ms",
                       "Morocco": "ma",
                       "Mozambique": "mz",
                       "Myanmar": "mm",
                       "Namibia": "na",
                       "Nepal": "np",
                       "Netherlands": "nl",
                       "New Zealand": "nz",
                       "Nicaragua": "ni",
                       "Niger": "ne",
                       "Nigeria": "ng",
                       "North Macedonia": "mk",
                       "Norway": "no",
                       "Oman": "om",
                       "Panama": "pa",
                       "Papua New Guinea": "pg",
                       "Paraguay": "py",
                       "Peru": "pe",
                       "Philippines": "ph",
                       "Poland": "pl",
                       "Portugal": "pt",
                       "Qatar": "qa",
                       "Republic of the Congo": "cg",
                       "Romania": "ro",
                       "Russia": "ru",
                       "Rwanda": "rw",
                       "Saudi Arabia": "sa",
                       "Senegal": "sn",
                       "Serbia": "rs",
                       "Seychelles": "sc",
                       "Sierra Leone": "sl",
                       "Singapore": "sg",
                       "Slovakia": "sk",
                       "Slovenia": "si",
                       "Solomon Islands": "sb",
                       "South Africa": "za",
                       "Spain": "es",
                       "Sri Lanka": "lk",
                       "St. Kitts and Nevis": "kn",
                       "St. Lucia": "lc",
                       "St. Vincent and The Grenadines": "vc",
                       "Suriname": "sr",
                       "Sweden": "se",
                       "Switzerland": "ch",
                       "Taiwan": "tw",
                       "Tajikistan": "tj",
                       "Tanzania": "tz",
                       "Thailand": "th",
                       "Tonga": "to",
                       "Trinidad and Tobago": "tt",
                       "Tunisia": "tn",
                       "Turkey": "tr",
                       "Turkmenistan": "tm",
                       "Turks and Caicos": "tc",
                       "UAE": "ae",
                       "Uganda": "ug",
                       "Ukraine": "ua",
                       "United Kingdom": "gb",
                       "United States": "us",
                       "Uruguay": "uy",
                       "Uzbekistan": "uz",
                       "Vanuatu": "vu",
                       "Venezuela": "ve",
                       "Vietnam": "vn",
                       "Yemen": "ye",
                       "Zambia": "zm",
                       "Zimbabwe": "zw" ]

    static let instance: Music = Music()
    var callbacks = [MusicCallback]()
    var wasSetup = false

    // This is called once at init to set our observer
    func setup() {
        if !wasSetup {
            if PrefsInfo.musicProvider == "Apple Music" {
                DistributedNotificationCenter.default.addObserver(self,
                    selector: #selector(Music.musicCallback(_:)),
                    name: NSNotification.Name("com.apple.Music.playerInfo"), object: nil)

            } else {
                // Spotify
                DistributedNotificationCenter.default.addObserver(self,
                    selector: #selector(Music.spotifyCallback(_:)),
                    name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"), object: nil)
            }
            wasSetup = true
        }
    }

    @objc func musicCallback(_ aNotification: Notification) {
        var album = ""
        var name = ""
        var artist = ""
        var songId = ""

        if let userInfo = aNotification.userInfo {
            if userInfo.keys.contains("Album") {
                album = userInfo["Album"] as! String
            }
            if userInfo.keys.contains("Name") {
                name = userInfo["Name"] as! String
            }
            if userInfo.keys.contains("Artist") {
                artist = userInfo["Artist"] as! String
            }
            if userInfo.keys.contains("Store URL") {
                songId = fetchId(id: userInfo["Store URL"] as! String)
            }

            print(userInfo)

            // Let everyone who wants to know that we have a new song playing !
            for callback in callbacks {
                callback(SongInfo(name: name, artist: artist, album: album, id: songId))
            }
        }
    }

    @objc func spotifyCallback(_ aNotification: Notification) {
        print(aNotification)
        var album = ""
        var name = ""
        var artist = ""
        var songId = ""

        if let userInfo = aNotification.userInfo {
            if userInfo.keys.contains("Album") {
                album = userInfo["Album"] as! String
            }
            if userInfo.keys.contains("Name") {
                name = userInfo["Name"] as! String
            }
            if userInfo.keys.contains("Artist") {
                artist = userInfo["Artist"] as! String
            }
            if userInfo.keys.contains("Track ID") {
                songId = userInfo["Track ID"] as! String
            }

            // Let everyone who wants to know that we have a new song playing !
            for callback in callbacks {
                callback(SongInfo(name: name, artist: artist, album: album, id: songId))
            }
        }
    }

    func fetchId(id: String) -> String {
        let arr = id.split(separator: "=")
        return String(arr.last ?? "")
    }

    // We can't use async/await before macOS 12... yay
    // swiftlint:disable:next cyclomatic_complexity
    func getArtworkUrl(id: String, completion: @escaping (String?) -> Void) {
        // Spotify is a bit easier
        if PrefsInfo.musicProvider == "Spotify" {
            let embedUrl = URL(string: "https://embed.spotify.com/oembed/?url=" + id)!

            var request = URLRequest(url: embedUrl)
            request.httpMethod = "GET"

            let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
                // Did we get a result ?
                if let songData = data {
                    guard let spotifySong = try? newJSONDecoder().decode(SpotifySong.self, from: songData) else {
                        debugLog("Can't decode SpotifySong")
                        completion(nil)
                        return
                    }

                    guard let artworkUrl = spotifySong.thumbnailURL else {
                        debugLog("No artwork in SpotifySong")
                        print(spotifySong)
                        completion(nil)
                        return
                    }

                    // Now we return
                    completion(artworkUrl)
                    return
                }

                completion(nil)
            }

            dataTask.resume()
            return
        }

        var searchUrl: URL
        if Int(id) != nil {
            // So if we have a valid ID (this seems to happen if the song is in user's library,
            // we can use that to query Apple Music
            //
            // A JWT token is required for this
            //
            // The storefront must be correctly configured for most songs to work
            searchUrl = URL(string: "https://api.music.apple.com/v1/catalog/"
                                + (Music.instance.storefronts[PrefsInfo.appleMusicStoreFront] ?? "us")
                                + "/songs/" + id)!
            print(searchUrl)
        } else {
            // This likely happens when you play songs outside of your library (Explore tab, etc)
            //
            // A JWT token is required for this
            //
            // The storefront must be correctly configured for most songs to work
            searchUrl = URL(string: "https://api.music.apple.com/v1/catalog/"
                                + (Music.instance.storefronts[PrefsInfo.appleMusicStoreFront] ?? "us")
                                + "/search?term=" + id + "&types=albums")!
            print(searchUrl)
        }

        var request = URLRequest(url: searchUrl)
        request.httpMethod = "GET"
        request.addValue("Bearer \(APISecrets.appleMusicToken)", forHTTPHeaderField: "Authorization")

        let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
            if Int(id) != nil {
                // This is the regular library path... This needs to be split up !
                // Did we get a result ?
                if let songData = data {
                    guard let appleMusicSong = try? newJSONDecoder().decode(AppleMusicSong.self, from: songData) else {
                        debugLog("Can't decode AppleMusicSong")
                        completion(nil)
                        return
                    }

                    guard var artworkUrl = appleMusicSong.data?[0].attributes?.artwork?.url else {
                        debugLog("No artwork in AppleMusicSong")
                        print(appleMusicSong)
                        completion(nil)
                        return
                    }

                    // We make a 200x200 url
                    artworkUrl = artworkUrl
                        .replacingOccurrences(of: "{w}", with: "200")
                        .replacingOccurrences(of: "{h}", with: "200")
                    completion(artworkUrl)
                    return
                }
            } else {
                // This is the out of library path, it reaaally need to be split up
                if let songData = data {
                    guard let appleMusicSearch = try? newJSONDecoder().decode(AppleMusicSearch.self, from: songData) else {
                        debugLog("Can't decode AppleMusicSearch")
                        completion(nil)
                        return
                    }

                    guard var artworkUrl = appleMusicSearch.results?.albums?.data?[0].attributes?.artwork?.url else {
                        debugLog("No artwork in AppleMusicSearch")
                        print(appleMusicSearch)
                        completion(nil)
                        return
                    }

                    // We make a 200x200 url
                    artworkUrl = artworkUrl
                        .replacingOccurrences(of: "{w}", with: "200")
                        .replacingOccurrences(of: "{h}", with: "200")
                    completion(artworkUrl)
                    return
                }
            }

            completion(nil)
        }

        dataTask.resume()
    }

    // MARK: - Callbacks
    func addCallback(_ callback:@escaping MusicCallback) {
        debugLog("Adding music callback")
        callbacks.append(callback)
    }
}
