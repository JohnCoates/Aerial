//
//  PoiStringProvider.swift
//  Aerial
//
//  Created by Guillaume Louel on 13/10/2018.
//  Copyright © 2018 John Coates. All rights reserved.
//

import Foundation

class CommunityStrings {
    let id: String
    let name: String
    let poi: [String: String]

    init(id: String, name: String, poi: [String: String]) {
        self.id = id
        self.name = name
        self.poi = poi
    }
}

class PoiStringProvider {
    static let sharedInstance = PoiStringProvider()
    var loadedDescriptions = false
    var loadedDescriptionsWasLocalized = false

    var stringBundle: Bundle?
    var stringDict: NSDictionary?

    var communityStrings = [CommunityStrings]()

    // MARK: - Lifecycle
    init() {
        debugLog("Poi Strings Provider initialized")
        loadBundle()
        loadCommunity()
    }

    // MARK: - Bundle management
    private func loadBundle() {
        // Idle string bundle
        let preferences = Preferences.sharedInstance

        var bundlePath = VideoCache.cacheDirectory!
        if preferences.localizeDescriptions {
            bundlePath.append(contentsOf: "/TVIdleScreenStrings.bundle")
        } else {
            bundlePath.append(contentsOf: "/TVIdleScreenStrings.bundle/en.lproj/")
        }

        if let sb = Bundle.init(path: bundlePath) {
            let dictPath = VideoCache.cacheDirectory!.appending("/TVIdleScreenStrings.bundle/en.lproj/Localizable.nocache.strings")

            // We could probably only work with that...
            if let sd = NSDictionary(contentsOfFile: dictPath) {
                self.stringDict = sd
            }

            self.stringBundle = sb
            self.loadedDescriptions = true
            self.loadedDescriptionsWasLocalized = preferences.localizeDescriptions
        } else {
            errorLog("TVIdleScreenStrings.bundle is missing, please remove entries.json in Cache folder to fix the issue")
        }
    }

    // Make sure we have the correct bundle loaded
    private func ensureLoadedBundle() -> Bool {
        let preferences = Preferences.sharedInstance

        if loadedDescriptions && loadedDescriptionsWasLocalized == preferences.localizeDescriptions {
            return true
        } else {
            loadBundle()
            return loadedDescriptions
        }
    }

    // Return the Localized (or english) string for a key from the Strings Bundle
    func getString(key: String, video: AerialVideo) -> String {
        if !ensureLoadedBundle() {
            return ""
        }
        let preferences = Preferences.sharedInstance
        let locale: NSLocale = NSLocale(localeIdentifier: Locale.preferredLanguages[0])

        if #available(OSX 10.12, *) {
            if preferences.localizeDescriptions && locale.languageCode != "en" {
                return stringBundle!.localizedString(forKey: key, value: "", table: "Localizable.nocache")
            }
        }

        if preferences.useCommunityDescriptions && !video.communityPoi.isEmpty {
            return key  // We directly store the string in the key
        } else {
            return stringBundle!.localizedString(forKey: key, value: "", table: "Localizable.nocache")
        }
    }

    // Return all POIs for an id
    func fetchExtraPoiForId(id: String) -> [String: String]? {
        if !ensureLoadedBundle() {
            return [:]
        }

        var found = [String: String]()
        for kv in stringDict! {
            let key = (kv.key as! String)
            if key.starts(with: id) {
                found[String(key.split(separator: "_").last!)] = key
            }
        }

        return found
    }

    //
    func getPoiKeys(video: AerialVideo) -> [String: String] {
        let preferences = Preferences.sharedInstance
        let locale: NSLocale = NSLocale(localeIdentifier: Locale.preferredLanguages[0])

        if #available(OSX 10.12, *) {
            if preferences.localizeDescriptions && locale.languageCode != "en" {
                return video.poi
            }
        }

        if preferences.useCommunityDescriptions && !video.communityPoi.isEmpty {
            return video.communityPoi
        } else {
            return video.poi
        }
    }

    // MARK: - Community data

    // Load the community strings
    private func loadCommunity() {
        let preferences = Preferences.sharedInstance

        var bundlePath: String
        if preferences.localizeDescriptions {
            bundlePath = Bundle(for: PoiStringProvider.self).path(forResource: "en", ofType: "json")!
            //bundlePath = Bundle.main.path(forResource: "en", ofType: "json")!
        } else {
            // TODO
            bundlePath = Bundle(for: PoiStringProvider.self).path(forResource: "en", ofType: "json")!
            //bundlePath = Bundle.main.path(forResource: "en", ofType: "json")!
        }
        debugLog("path : \(bundlePath)")
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: bundlePath), options: .mappedIfSafe)
            let batches = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

            guard let batch = batches as? NSDictionary else {
                errorLog("Community : Encountered unexpected content type for batch, please report !")
                return
            }

            let assets = batch["assets"] as! [NSDictionary]
            for item in assets {
                let id = item["id"] as! String
                let name = item["name"] as! String
                let poi = item["pointsOfInterest"] as? [String: String]

                communityStrings.append(CommunityStrings(id: id, name: name, poi: poi ?? [:]))
            }
        } catch {
            // handle error
            errorLog("Community JSON ERROR")
        }
        debugLog("Community JSON : \(communityStrings.count)")
    }

    func getCommunityName(id: String) -> String? {
        return communityStrings.first(where: { $0.id == id }).map { $0.name }
    }

    func getCommunityPoi(id: String) -> [String: String] {
        return communityStrings.first(where: { $0.id == id }).map { $0.poi } ?? [:]
    }
}
