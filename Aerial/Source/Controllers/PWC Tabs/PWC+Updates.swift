//
//  PWC+Updates.swift
//  Aerial
//      This is the controller code for the Updates Tab
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Cocoa

extension PreferencesWindowController {
    func setupUpdatesTab() {
        newVideosModePopup.selectItem(at: preferences.newVideosMode!)

        betaCheckFrequencyPopup.selectItem(at: preferences.betaCheckFrequency!)

        lastCheckedVideosLabel.stringValue = "Last checked on " + preferences.lastVideoCheck!

        // Format date
        if sparkleUpdater!.lastUpdateCheckDate != nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd 'at' HH:mm"
            let sparkleDate = dateFormatter.string(from: sparkleUpdater!.lastUpdateCheckDate)
            lastCheckedSparkle.stringValue = "Last checked on " + sparkleDate
        } else {
            lastCheckedSparkle.stringValue = "Never checked for update"
        }

        if PrefsUpdates.checkForUpdates {
            automaticallyCheckForUpdatesCheckbox.state = .on
        }
        if preferences.updateWhileSaverMode {
            allowScreenSaverModeUpdateCheckbox.state = .on
        }
        if preferences.allowBetas {
            allowBetasCheckbox.state = .on
            betaCheckFrequencyPopup.isEnabled = true
        }

        sparkleScreenSaverMode.selectItem(at: PrefsUpdates.sparkleUpdateMode.rawValue)

        // We disable silent installs in Catalina
        if #available(OSX 10.15, *) {
            silentInstallMenuItem.isEnabled = false
        }
    }

    // MARK: - Update panel
    @IBAction func newVideosModeChange(_ sender: NSPopUpButton) {
        debugLog("UI newVideosMode: \(sender.indexOfSelectedItem)")
        preferences.newVideosMode = sender.indexOfSelectedItem
    }

    @IBAction func betaCheckFrequencyChange(_ sender: NSPopUpButton) {
        debugLog("UI betaCheckFrequency: \(sender.indexOfSelectedItem)")
        preferences.betaCheckFrequency = sender.indexOfSelectedItem
    }

    @IBAction func popoverUpdateClick(_ button: NSButton) {
        popoverUpdate.show(relativeTo: button.preparedContentRect, of: button, preferredEdge: .maxY)
    }

    // Sparkle updates
    @IBAction func automaticallyCheckForUpdatesChange(_ button: NSButton) {
        let onState = button.state == .on
        PrefsUpdates.checkForUpdates = onState
        //sparkleUpdater!.automaticallyChecksForUpdates = onState
        debugLog("UI automaticallyCheckForUpdatesChange: \(onState)")
    }

    @IBAction func allowScreenSaverModeUpdatesChange(_ button: NSButton) {
        let onState = button.state == .on
        preferences.updateWhileSaverMode = onState
        debugLog("UI allowScreenSaverModeUpdatesChange: \(onState)")
    }

    @IBAction func sparkleScreenSaverModeChange(_ sender: NSPopUpButton) {
        PrefsUpdates.sparkleUpdateMode = UpdateMode(rawValue: sender.indexOfSelectedItem) ?? .notify
    }

    @IBAction func allowBetasChange(_ button: NSButton) {
        let onState = button.state == .on
        preferences.allowBetas = onState
        debugLog("UI allowBetasChange: \(onState)")

        // We also update the feed url so subsequent checks go to the right feed
        if preferences.allowBetas {
            betaCheckFrequencyPopup.isEnabled = true
            sparkleUpdater?.feedURL = URL(string: "https://raw.githubusercontent.com/JohnCoates/Aerial/master/beta-appcast.xml")
        } else {
            betaCheckFrequencyPopup.isEnabled = false
            sparkleUpdater?.feedURL = URL(string: "https://raw.githubusercontent.com/JohnCoates/Aerial/master/appcast.xml")
        }
    }

    @IBAction func checkForUpdatesButton(_ sender: NSButton) {
        if #available(OSX 10.15, *) {
            debugLog("check for updates (using Catalina probe)")

            let autoUpdates = AutoUpdates.sharedInstance

            if !autoUpdates.didProbeForUpdate {
                // Let's probe
                autoUpdates.doProbingCheck()

                _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { (_) in
                    self.checkForProbeResults(silent: false)
                })
            } else {
                // If we already probed, show the results !
                checkForProbeResults(silent: false)
            }

        } else {
            debugLog("check for updates (using Sparkle's auto)")
            sparkleUpdater!.checkForUpdates(self)

            lastCheckedSparkle.stringValue = "Last checked today"
        }
    }

    func checkForProbeResults(silent: Bool) {
        let autoUpdates = AutoUpdates.sharedInstance

        if !autoUpdates.didProbeForUpdate {
            // Try again in 2s
            if #available(OSX 10.12, *) {
                _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { (_) in
                    self.checkForProbeResults(silent: silent)
                })
            } else {
                // We should only come here in Catalina anyway
                errorLog("checkForProbeResults called in macOS < 10.12")
            }
        } else {
            if autoUpdates.isAnUpdateAvailable() {
                updateReleaseController.show(sender: self.versionButton, controller: self)
            } else {
                if !silent {
                    updateReleaseController.showNoUpdate()
                }
            }
        }
    }

    // Json updates
    @IBAction func checkNowButtonClick(_ sender: NSButton) {
        checkNowButton.isEnabled = false
        ManifestLoader.instance.addCallback(reloadJSONCallback)
        ManifestLoader.instance.reloadFiles()
    }

    func reloadJSONCallback(manifestVideos: [AerialVideo]) {
        checkNowButton.isEnabled = true
        lastCheckedVideosLabel.stringValue = "Last checked on " + preferences.lastVideoCheck!
    }
}
