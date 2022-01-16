//
//  PrefsCache.swift
//  Aerial
//
//  Created by Guillaume Louel on 03/06/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

enum CachePeriodicity: Int, Codable {
    case daily, weekly, monthly, never
}

struct PrefsCache {
    @SimpleStorage(key: "enableManagement", defaultValue: true)
    static var enableManagement: Bool

    // Cache limit (in GiB)
    @SimpleStorage(key: "cacheLimit", defaultValue: 5)
    static var cacheLimit: Double

    // How often should cache gets refreshed
    @SimpleStorage(key: "intCachePeriodicity", defaultValue: CachePeriodicity.never.rawValue)
    static var intCachePeriodicity: Int

    // We wrap in a separate value, as we can't store an enum as a Codable in
    // macOS < 10.15
    static var cachePeriodicity: CachePeriodicity {
        get {
            return CachePeriodicity(rawValue: intCachePeriodicity)!
        }
        set(value) {
            intCachePeriodicity = value.rawValue
        }
    }

    // Do we restrict network traffic on Wi-Fi
    @SimpleStorage(key: "restrictOnWiFi", defaultValue: false)
    static var restrictOnWiFi: Bool

    // List of allowed networks (using SSID)
    @SimpleStorage(key: "allowedNetworks", defaultValue: [])
    static var allowedNetworks: [String]

    // Should we show the download indicator or not
    @SimpleStorage(key: "showBackgroundDownloads", defaultValue: false)
    static var showBackgroundDownloads: Bool

    // Should we override the cache
    @SimpleStorage(key: "overrideCache", defaultValue: false)
    static var overrideCache: Bool

    // App-scoped bookmark to cache, in NSData form
    @SimpleStorage(key: "cacheBookmarkData", defaultValue: nil)
    static var cacheBookmarkData: Data?

    // App-scoped bookmark to cache, in NSData form
    @SimpleStorage(key: "supportBookmarkData", defaultValue: nil)
    static var supportBookmarkData: Data?

    // The raw path in string form
    @SimpleStorage(key: "supportPath", defaultValue: nil)
    static var supportPath: String?

}
