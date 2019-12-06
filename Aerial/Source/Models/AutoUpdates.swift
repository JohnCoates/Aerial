//
//  AutoUpdates.swift
//  Aerial
//
//  Created by Guillaume Louel on 06/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import Sparkle

struct AutoUpdates {
    // This is what we use to look for updates while the screensaver is running
    // This code is not active in Catalina+
    func doForcedUpdate() {
        let preferences = Preferences.sharedInstance

        if #available(OSX 10.15, *) {
            // Currently, we are now allowing auto updates in Catalina or above as Sparkle no longer works
            // More info here : https://github.com/sparkle-project/Sparkle/issues/1476
            debugLog("Ignoring updateWhileSaverMode in Catalina")
        } else {
            debugLog("updateWhileSaverMode check")

            let suup = SUUpdater.init(for: Bundle(for: AerialView.self))

            // Make sure we can create SUUpdater
            if let suu = suup {
                // We may need to change the feed for betas
                if preferences.allowBetas {
                    suu.feedURL = URL(string: "https://raw.githubusercontent.com/JohnCoates/Aerial/master/beta-appcast.xml")
                }

                // We manually ensure the correct amount of time passed since last check
                var distance = -86400       // 1 day
                if preferences.betaCheckFrequency == 0 {
                    distance = -3600        // 1 hour
                } else if preferences.betaCheckFrequency == 1 {
                    distance = -43200       // 12 hours
                }

                // If we never went into System Preferences, we may not have a lastUpdateCheckDate
                if suu.lastUpdateCheckDate != nil {
                    if suu.lastUpdateCheckDate.timeIntervalSinceNow.distance(to: Double(distance)) > 0 {
                        // Then force check/install udpates
                        debugLog("Checking for update (forced mode)")
                        suu.resetUpdateCycle()
                        suu.installUpdatesIfAvailable()
                    }
                }
            }
        }
    }

}
