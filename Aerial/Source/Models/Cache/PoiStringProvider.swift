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
    private func getBundleLanguages() -> [String] {
        // Might want to improve that...
        // This is a static list of what's supposed to be in the bundle
        // swiftlint:disable:next line_length
        return ["de", "he", "en_AU", "ar", "el", "ja", "en", "uk", "es_419", "zh_CN", "es", "pt_BR", "da", "it", "sk", "pt_PT", "ms", "sv", "cs", "ko", "no", "hu", "zh_HK", "tr", "pl", "zh_TW", "en_GB", "vi", "ru", "fr_CA", "fr", "fi", "id", "nl", "th", "pt", "ro", "hr", "hi", "ca"]
    }

    private func loadBundle() {
        // Idle string bundle
        let preferences = Preferences.sharedInstance
        var bundlePath = VideoCache.appSupportDirectory!.appending("/tvOS 15")
        if preferences.ciOverrideLanguage == "" {
            debugLog("Preferred languages : \(Locale.preferredLanguages)")

            let bestMatchedLanguage = Bundle.preferredLocalizations(from: getBundleLanguages(), forPreferences: Locale.preferredLanguages).first
            if let match = bestMatchedLanguage {
                debugLog("Best matched language : \(match)")
                bundlePath.append(contentsOf: "/TVIdleScreenStrings.bundle/" + match + ".lproj/")
            } else {
                debugLog("No match, reverting to english")
                // We load the bundle and let system grab the closest available preferred language
                // This no longer works in Catalina and defaults back to english
                // as legacyScreenSaver.appex, our new "mainbundle" is english only
                bundlePath.append(contentsOf: "/TVIdleScreenStrings.bundle")
            }
        } else {
            debugLog("Language overriden to \(String(describing: preferences.ciOverrideLanguage))")
            // Or we load the overriden one
            bundlePath.append(contentsOf: "/TVIdleScreenStrings.bundle/" + preferences.ciOverrideLanguage! + ".lproj/")
        }

        if let sb = Bundle.init(path: bundlePath) {
            let dictPath = VideoCache.appSupportDirectory!.appending("/tvOS 13/TVIdleScreenStrings.bundle/en.lproj/Localizable.nocache.strings")

            // We could probably only work with that...
            if let sd = NSDictionary(contentsOfFile: dictPath) as? [String: String] {
                self.stringDict = sd
            }

            self.stringBundle = sb
            self.loadedDescriptions = true
        } else {
            errorLog("TVIdleScreenStrings.bundle is missing, please remove entries.json in Cache folder to fix the issue")
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
        if !video.communityPoi.isEmpty {
            return video.communityPoi
        } else {
            return video.poi
        }
    }

    // Do we have any keys, anywhere, for said video ?
    func hasPoiKeys(video: AerialVideo) -> Bool {
        return (!video.poi.isEmpty && loadedDescriptions) ||
        (!video.communityPoi.isEmpty && !getPoiKeys(video: video).isEmpty)
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
        case "hu":  // Hungarian
            return 9
        case "it":  // Italian
            return 10
        case "ja":  // Japanese
            return 11
        case "ko":  // Korean
            return 12
        case "pl":  // Polish
            return 13
        case "pt":  // Portuguese
            return 14
        case "pt_BR":  // Portuguese (Brazil)
            return 15
        case "ru":  // Russian
            return 16
        case "es":  // Spanish
            return 17
        case "sv":  // Swedish
            return 18
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
            return "hu"
        case 10:
            return "it"
        case 11:
            return "ja"
        case 12:
            return "ko"
        case 13:
            return "pl"
        case 14:
            return "pt"
        case 15:
            return "pt_BR"
        case 16:
            return "ru"
        case 17:
            return "es"
        case 18:
            return "sv"
        default:
            return ""
        }
    }
}
