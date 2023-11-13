//
//  CompanionBridge.swift
//  Aerial
//
//  Created by Guillaume Louel on 09/10/2023.
//  Copyright © 2023 Guillaume Louel. All rights reserved.
//
// This acts as our bridge to Companion when the plugin needs data FROM companion
// Currently using DistributedNotificationCenter, until *that* breaks too...

import Foundation

struct CompanionBridge {
    static var nightShiftSunrise: Date?
    static var nightShiftSunset: Date?
    
    static var locationLat: Double?
    static var locationLong: Double?
    
    static func setNotifications() {
        debugLog("🌉 seting up CompanionBridge")

        // Get nightshift
        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("com.glouel.aerial.nightshift"), object: nil, queue: nil) { notification in
            debugLog("🌉😻 received nightshift")
            debugLog(notification.debugDescription)
            
            if let sunrise = notification.userInfo?["sunrise"] as? Date {
                debugLog("parsed sunrise")
                nightShiftSunrise = sunrise
            } else {
                debugLog("can't parse sunrise")
            }

            if let sunset = notification.userInfo?["sunset"] as? Date {
                debugLog("parsed sunset")
                nightShiftSunset = sunset
            }
        }

        // Get location
        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("com.glouel.aerial.location"), object: nil, queue: nil) { notification in
            debugLog("🌉😻 received location")
            debugLog(notification.debugDescription)
            
            if let lat = notification.userInfo?["latitude"] as? Double {
                debugLog("parsed latitude")
                locationLat = lat
            } else {
                debugLog("can't parse latitude")
            }

            if let long = notification.userInfo?["longitude"] as? Double {
                debugLog("parsed longitude")
                locationLong = long
            }
        }
        
        
        // Test request
        DistributedNotificationCenter.default().postNotificationName(NSNotification.Name("com.glouel.aerial.getnightshift"), object: nil, deliverImmediately: true)
        
        if PrefsInfo.weather.locationMode == .useCurrent || PrefsTime.timeMode == .locationService {
            debugLog("🌉 asking for location")
            DistributedNotificationCenter.default().postNotificationName(NSNotification.Name("com.glouel.aerial.getlocation"), object: nil, deliverImmediately: true)
        }
    }
}
