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
        //newVideosModePopup.selectItem(at: preferences.newVideosMode!)

        betaCheckFrequencyPopup.selectItem(at: preferences.betaCheckFrequency!)

        //lastCheckedVideosLabel.stringValue = "Last checked on " + preferences.lastVideoCheck!

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

    }

    @IBAction func checkForUpdatesButton(_ sender: NSButton) {

    }

    func checkForProbeResults(silent: Bool) {
     }

    // Json updates
    @IBAction func checkNowButtonClick(_ sender: NSButton) {
        /*checkNowButton.isEnabled = false
        ManifestLoader.instance.addCallback(reloadJSONCallback)
        ManifestLoader.instance.reloadFiles()*/
    }

    func reloadJSONCallback(manifestVideos: [AerialVideo]) {
        /*checkNowButton.isEnabled = true
        lastCheckedVideosLabel.stringValue = "Last checked on " + preferences.lastVideoCheck!*/
    }
}
