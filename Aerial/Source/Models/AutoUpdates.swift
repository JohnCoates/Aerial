//
//  AutoUpdates.swift
//  Aerial
//
//  Created by Guillaume Louel on 06/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import Sparkle

class AutoUpdates: NSObject, SUUpdaterDelegate {
    static let sharedInstance = AutoUpdates()

    var didProbeForUpdate = false
    private var updateAvailable = false
    private var updateVersion: String = ""
    private var updateDescription: String = ""

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
                // We manually ensure the correct amount of time passed since last check
                var distance = -86400       // 1 day

                // We may need to change the feed for betas
                if preferences.allowBetas {
                    suu.feedURL = URL(string: "https://raw.githubusercontent.com/JohnCoates/Aerial/master/beta-appcast.xml")

                    if preferences.betaCheckFrequency == 0 {
                        distance = -3600        // 1 hour
                    } else if preferences.betaCheckFrequency == 1 {
                        distance = -43200       // 12 hours
                    }
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

    func shouldCheckForUpdates(_ updater: SUUpdater) -> Bool {
        let preferences = Preferences.sharedInstance

        // We manually ensure the correct amount of time passed since last check
        var distance = -86400       // 1 day

        // On betas, we may have a shorter time check
        if preferences.allowBetas {
            if preferences.betaCheckFrequency == 0 {
                distance = -3600        // 1 hour
            } else if preferences.betaCheckFrequency == 1 {
                distance = -43200       // 12 hours
            }
        }

        // If we never went into System Preferences, we may not have a lastUpdateCheckDate
        if updater.lastUpdateCheckDate != nil {
            if updater.lastUpdateCheckDate.timeIntervalSinceNow.distance(to: Double(distance)) > 0 {
                // Then force check/install udpates
                debugLog("Update check time elapsed")

                return true
            }
        }

        return false
    }

    // Probing update check
    func doProbingCheck() {
        let preferences = Preferences.sharedInstance

        debugLog("Probing availability of an update")

        let suup = SUUpdater.init(for: Bundle(for: AerialView.self))

        // Make sure we can create SUUpdater
        if let suu = suup {
            suu.delegate = self

            // We may need to change the feed for betas
            if preferences.allowBetas {
                suu.feedURL = URL(string: "https://raw.githubusercontent.com/JohnCoates/Aerial/master/beta-appcast.xml")
            }

            // Then we probe !
            debugLog("Checking for update (probe mode)")
            suu.checkForUpdateInformation()

            // Note: The result is asynchronously available later
        }
    }

    func getUpdateString() -> String {
        if updateAvailable {
            return "A new version of Aerial (\(updateVersion)) is available"
        } else {
            return ""
        }
    }

    func updaterDidNotFindUpdate(_ updater: SUUpdater) {
        debugLog("//////// No update is available !")
        didProbeForUpdate = true
    }

    func updater(_ updater: SUUpdater, didFindValidUpdate item: SUAppcastItem) {
        debugLog("//////// An update is available !")
        didProbeForUpdate = true
        updateAvailable = true

        // Grab the new version number
        if let versionString = item.displayVersionString {
            self.updateVersion = versionString
        }

        // And the description
        self.updateDescription = item.itemDescription
    }

    func isAnUpdateAvailable() -> Bool {
        return updateAvailable
    }

    func getVersion() -> String {
        return updateVersion
    }

    func getReleaseNotes() -> String {
        return updateDescription
    }
}
