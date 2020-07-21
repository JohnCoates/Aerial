//
//  UpdatesViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
#if NOSPARKLE
#else
import Sparkle
#endif

class UpdatesViewController: NSViewController {

    @IBOutlet var autoCheckUpdates: NSButton!

    @IBOutlet var silentInstallMenuItem: NSMenuItem!
    @IBOutlet var whenSaverRunsPopup: NSPopUpButton!
    @IBOutlet var whenSaverRuns: NSButton!
    @IBOutlet var allowBeta: NSButton!
    @IBOutlet var betaFrequencyPopup: NSPopUpButton!

    @IBOutlet var lastCheckLabel: NSTextField!
    #if NOSPARKLE
    #else
    var sparkleUpdater: SUUpdater?

    lazy var updateReleaseController: UpdateReleaseController = UpdateReleaseController()
    #endif
    override func viewDidLoad() {
        super.viewDidLoad()

        #if NOSPARKLE
        #else
        // Starting the Sparkle update system
        sparkleUpdater = SUUpdater.init(for: Bundle(for: PreferencesWindowController.self))
        #endif
        autoCheckUpdates.state = PrefsUpdates.checkForUpdates ? .on : .off

        if Preferences.sharedInstance.updateWhileSaverMode {
            whenSaverRunsPopup.state = .on
        }

        whenSaverRunsPopup.selectItem(at: PrefsUpdates.sparkleUpdateMode.rawValue)

        if Preferences.sharedInstance.allowBetas {
            allowBeta.state = .on
            betaFrequencyPopup.isEnabled = true
        }

        betaFrequencyPopup.selectItem(at: Preferences.sharedInstance.betaCheckFrequency!)

        #if NOSPARKLE
        lastCheckLabel.stringValue = "Sparkle is disabled"
        #else
        // Format date
        if sparkleUpdater!.lastUpdateCheckDate != nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd 'at' HH:mm"
            let sparkleDate = dateFormatter.string(from: sparkleUpdater!.lastUpdateCheckDate)
            lastCheckLabel.stringValue = "Last checked on " + sparkleDate
        } else {
            lastCheckLabel.stringValue = "Never checked for update"
        }
        #endif

        // We disable silent installs in Catalina
        if #available(OSX 10.15, *) {
            silentInstallMenuItem.isEnabled = false
        }
    }

    @IBAction func autoCheckUpdatesChange(_ sender: NSButton) {
        PrefsUpdates.checkForUpdates = sender.state == .on
    }

    @IBAction func checkNowClick(_ sender: NSButton) {
        #if NOSPARKLE
        debugLog("Sparkle is disabled in build settings")
        #else
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

            lastCheckLabel.stringValue = "Last checked today"
        }
        #endif
    }

    func checkForProbeResults(silent: Bool) {
        #if NOSPARKLE
        debugLog("Sparkle is disabled in build settings")
        #else
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
                updateReleaseController.show(sender: self.whenSaverRuns, controller: self)
            } else {
                if !silent {
                    updateReleaseController.showNoUpdate()
                }
            }
        }
        #endif
    }

    @IBAction func whenSaverRunsChange(_ sender: NSButton) {
        Preferences.sharedInstance.updateWhileSaverMode = sender.state == .on
    }
    @IBAction func whenSaverRunsPopupChange(_ sender: NSPopUpButton) {
        PrefsUpdates.sparkleUpdateMode = UpdateMode(rawValue: sender.indexOfSelectedItem) ?? .notify
    }

    @IBAction func allowBetaChange(_ sender: NSButton) {
        Preferences.sharedInstance.allowBetas = sender.state == .on

        #if NOSPARKLE
        #else
        // We also update the feed url so subsequent checks go to the right feed
        if Preferences.sharedInstance.allowBetas {
            betaFrequencyPopup.isEnabled = true
            sparkleUpdater?.feedURL = URL(string: "https://raw.githubusercontent.com/JohnCoates/Aerial/master/beta-appcast.xml")
        } else {
            betaFrequencyPopup.isEnabled = false
            sparkleUpdater?.feedURL = URL(string: "https://raw.githubusercontent.com/JohnCoates/Aerial/master/appcast.xml")
        }
        #endif
    }

    @IBAction func betaFrequencyPopupChange(_ sender: NSPopUpButton) {
        Preferences.sharedInstance.betaCheckFrequency = sender.indexOfSelectedItem
    }
}
