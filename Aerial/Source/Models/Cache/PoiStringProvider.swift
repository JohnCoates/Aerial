//
//  PoiStringProvider.swift
//  Aerial
//
//  Created by Guillaume Louel on 13/10/2018.
//  Copyright © 2018 John Coates. All rights reserved.
//

import Foundation

class PoiStringProvider {
    static let sharedInstance = PoiStringProvider()
    var loadedDescriptions = false
    var loadedDescriptionsWasLocalized = false
    
    var stringBundle: Bundle?
    var stringDict: NSDictionary?
    init() {
        loadBundle()
    }
    
    private func loadBundle() {
        // Idle string bundle
        let preferences = Preferences.sharedInstance
        
        var bundlePath = VideoCache.cacheDirectory!
        if (preferences.localizeDescriptions) {
            bundlePath.append(contentsOf: "/TVIdleScreenStrings.bundle")
        }
        else {
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
    func getString(key:String) -> String {
        if !ensureLoadedBundle() {
            return ""
        }
        return stringBundle!.localizedString(forKey: key, value: "", table: "Localizable.nocache")
    }
    
    // Return all POIs for an id
    func fetchExtraPoiForId(id: String) -> [String:String]? {
        if !ensureLoadedBundle() {
            return [:]
        }
        
        var found = [String:String]()
        for kv in stringDict! {
            let key = (kv.key as! String)
            if key.starts(with: id)
            {
                found[String(key.split(separator: "_").last!)] = key
            }
        }
        
        return found
    }
}

