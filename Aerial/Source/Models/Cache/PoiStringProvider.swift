//
//  PoiStringProvider.swift
//  Aerial
//
//  Created by Guillaume Louel on 13/10/2018.
//  Copyright © 2018 John Coates. All rights reserved.
//

import Foundation

final class CommunityStrings {
    let id: String
    let name: String
    let poi: [String: String]

    init(id: String, name: String, poi: [String: String]) {
        self.id = id
        self.name = name
        self.poi = poi
    }
}

final class PoiStringProvider {
    static let sharedInstance = PoiStringProvider()
    var loadedDescriptions = false
    var loadedDescriptionsWasLocalized = false

    var stringBundle: Bundle?
    var stringDict: [String: String]?

    var communityStrings = [CommunityStrings]()
    var communityLanguage = ""
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

        var bundlePath = VideoCache.appSupportDirectory!
        if preferences.ciOverrideLanguage == "" {
            // We load the bundle and let system grab the closest available preferred language
            bundlePath.append(contentsOf: "/TVIdleScreenStrings13.bundle")
        } else {
            // Or we load the overriden one
            bundlePath.append(contentsOf: "/TVIdleScreenStrings13.bundle/" + preferences.ciOverrideLanguage! + ".lproj/")
        }

        if let sb = Bundle.init(path: bundlePath) {
            let dictPath = VideoCache.appSupportDirectory!.appending("/TVIdleScreenStrings13.bundle/en.lproj/Localizable.nocache.strings")

            // We could probably only work with that...
            if let sd = NSDictionary(contentsOfFile: dictPath) as? [String: String] {
                self.stringDict = sd
            }

            self.stringBundle = sb
            self.loadedDescriptions = true
        } else {
            errorLog("TVIdleScreenStrings13.bundle is missing, please remove entries.json in Cache folder to fix the issue")
        }
    }

    // Make sure we have the correct bundle loaded
    private func ensureLoadedBundle() -> Bool {
        if loadedDescriptions {
            return true
        } else {
            loadBundle()
            return loadedDescriptions
        }
    }

    // Return the Localized (or english) string for a key from the Strings Bundle
    func getString(key: String, video: AerialVideo) -> String {
        guard ensureLoadedBundle() else { return "" }

        /*let preferences = Preferences.sharedInstance
        let locale: NSLocale = NSLocale(localeIdentifier: Locale.preferredLanguages[0])

        if #available(OSX 10.12, *) {
            if preferences.localizeDescriptions && locale.languageCode != communityLanguage && preferences.ciOverrideLanguage == "" {
                return stringBundle!.localizedString(forKey: key, value: "", table: "Localizable.nocache")
            }
        }*/

        if !video.communityPoi.isEmpty {
            return key  // We directly store the string in the key
        } else {
            return stringBundle!.localizedString(forKey: key, value: "", table: "Localizable.nocache")
        }
    }

    // Return all POIs for an id
    func fetchExtraPoiForId(id: String) -> [String: String]? {
        guard let stringDict = stringDict, ensureLoadedBundle() else { return [:] }

        var found = [String: String]()
        for key in stringDict.keys where key.starts(with: id) {
            found[String(key.split(separator: "_").last!)] = key // FIXME: crash if key doesn't have "_"
        }

        return found
    }

    //
    func getPoiKeys(video: AerialVideo) -> [String: String] {
        /*let preferences = Preferences.sharedInstance
        let locale: NSLocale = NSLocale(localeIdentifier: Locale.preferredLanguages[0])
        if #available(OSX 10.12, *) {
            debugLog("locale.languageCode \(locale.languageCode)")
            if preferences.localizeDescriptions && locale.languageCode != communityLanguage && preferences.ciOverrideLanguage == "" {
                return video.poi
            }
        }*/

        if !video.communityPoi.isEmpty {
            return video.communityPoi
        } else {
            return video.poi
        }
    }

    // MARK: - Community data
    // siftlint:disable:next cyclomatic_complexity
    private func getCommunityPathForLocale() -> String {
        let preferences = Preferences.sharedInstance
        let locale: NSLocale = NSLocale(localeIdentifier: Locale.preferredLanguages[0])

        // Do we have a language override ?
        if preferences.ciOverrideLanguage != "" {
            let path = Bundle(for: PoiStringProvider.self).path(forResource: preferences.ciOverrideLanguage, ofType: "json")
            if path != nil {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: path!) {
                    debugLog("Community Language overriden to : \(preferences.ciOverrideLanguage!)")
                    communityLanguage = preferences.ciOverrideLanguage!
                    return path!
                }
            }
        }

        if #available(OSX 10.12, *) {
            // First we look in the Cache Folder for a locale directory
            let cacheDirectory = VideoCache.appSupportDirectory!
            var cacheResourcesString = cacheDirectory
            cacheResourcesString.append(contentsOf: "/locale")
            let cacheUrl = URL(fileURLWithPath: cacheResourcesString)

            if cacheUrl.hasDirectoryPath {
                debugLog("Aerial cache directory contains /locale")

                let cc = locale.languageCode
                debugLog("Looking for \(cc).json")

                let fileUrl = URL(fileURLWithPath: cacheResourcesString.appending("/\(cc).json"))
                debugLog(fileUrl.absoluteString)
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: fileUrl.path) {
                    debugLog("Locale description found")
                    communityLanguage = cc
                    return fileUrl.path
                } else {
                    debugLog("Locale description not found")
                }
            }
            debugLog("Defaulting to bundle")
            let cc = locale.languageCode

            let path = Bundle(for: PoiStringProvider.self).path(forResource: cc, ofType: "json")
            if path != nil {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: path!) {
                    communityLanguage = cc
                    return path!
                }
            }
        }

        // Fallback to english in bundle
        communityLanguage = "en"
        return Bundle(for: PoiStringProvider.self).path(forResource: "en", ofType: "json")!
    }

    // Load the community strings
    private func loadCommunity() {
        let bundlePath = getCommunityPathForLocale()
        debugLog("path : \(bundlePath)")

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: bundlePath), options: .mappedIfSafe)
            let batches = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

            guard let batch = batches as? NSDictionary else {
                errorLog("Community : Encountered unexpected content type for batch, please report !")
                return
            }

            for item in batch {
                let id = item.key as! String
                let name = (item.value as! NSDictionary)["name"] as! String
                let poi = (item.value as! NSDictionary)["pointsOfInterest"] as? [String: String]

                communityStrings.append(CommunityStrings(id: id, name: name, poi: poi ?? [:]))
            }
        } catch {
            // handle error
            errorLog("Community JSON ERROR : \(error)")
        }
        debugLog("Community JSON : \(communityStrings.count) entries")
    }

    func getCommunityName(id: String) -> String? {
        return communityStrings.first(where: { $0.id == id }).map { $0.name }
    }

    func getCommunityPoi(id: String) -> [String: String] {
        return communityStrings.first(where: { $0.id == id }).map { $0.poi } ?? [:]
    }

    // Helpers for the main popup
    // swiftlint:disable:next cyclomatic_complexity
    func getLanguagePosition() -> Int {
        let preferences = Preferences.sharedInstance
        // The list is alphabetized based on their english name in the UI
        switch preferences.ciOverrideLanguage {
        case "ar":  // Arabic
            return 1
        case "zh_CN":  // Chinese Simplified
            return 2
        case "zh_TW":  // Chinese Traditional
            return 3
        case "nl":  // Dutch
            return 4
        case "en":  // English
            return 5
        case "fr":  // French
            return 6
        case "de":  // German
            return 7
        case "he":  // Hebrew
            return 8
        case "pl":  // Polish
            return 9
        case "es":  // Spanish
            return 10
        default:    // This is the default, preferred language
            return 0
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func getLanguageStringFromPosition(pos: Int) -> String {
        switch pos {
        case 1:
            return "ar"
        case 2:
            return "zh_CN"
        case 3:
            return "zh_TW"
        case 4:
            return "nl"
        case 5:
            return "en"
        case 6:
            return "fr"
        case 7:
            return "de"
        case 8:
            return "he"
        case 9:
            return "pl"
        case 10:
            return "es"
        default:
            return ""
        }
    }
}
