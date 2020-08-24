//
//  CacheViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

class CacheViewController: NSViewController {

    @IBOutlet var automaticallyDownloadCheckbox: NSButton!

    // We use two views for two available modes
    @IBOutlet var automaticContainerView: NSView!
    @IBOutlet var manualContainerView: NSView!

    @IBOutlet var limitSlider: NSSlider!
    @IBOutlet var limitTextField: NSTextField!
    @IBOutlet var limitLabel: NSTextField!
    @IBOutlet var limitUnitLabel: NSTextField!

    @IBOutlet var rotateFrequencyLabel: NSTextField!
    @IBOutlet var rotateFrequencyPopup: NSPopUpButton!

    @IBOutlet var restrictWiFiCheckbox: NSButton!

    @IBOutlet var connectedIcon: NSButton!
    @IBOutlet var connectedLabel: NSTextField!

    @IBOutlet var addCurrentNetworkButton: NSButton!

    @IBOutlet var resetListButton: NSButton!
    @IBOutlet var allowedListLabel: NSTextField!

    @IBOutlet var showDownloadIndicator: NSButton!

    @IBOutlet var cacheBox: NSBox!
    @IBOutlet var freeBox: NSBox!

    // Manual mode
    @IBOutlet var cacheSize: NSTextField!
    @IBOutlet var makeTimeMachineIgnore: NSButton!

    @IBOutlet var manuallyPick: NSButton!
    @IBOutlet var pickFolder: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        makeTimeMachineIgnore.state = PrefsCache.hideFromTimeMachine ? .on : .off
        manuallyPick.state = PrefsCache.overrideCache ? .on : .off
        if #available(OSX 10.15, *) {
            manuallyPick.isEnabled = false
            pickFolder.isHidden = true
        }

        // Cache panel
        automaticallyDownloadCheckbox.state = PrefsCache.enableManagement ? .on : .off

        limitTextField.doubleValue = PrefsCache.cacheLimit
        limitSlider.doubleValue = PrefsCache.cacheLimit
        rotateFrequencyPopup.selectItem(at: PrefsCache.cachePeriodicity.rawValue)

        // Update the size of the cache and associated controls
        updateCacheSize()

        // Wi-Fi restrictions?
        restrictWiFiCheckbox.state = PrefsCache.restrictOnWiFi ? .on : .off
        updateNetworkStatus()

        // And the master switch!
        updateCacheVisibility()

        showDownloadIndicator.state = PrefsCache.showBackgroundDownloads ? .on : .off

        updateCacheBox()
    }

    func updateCacheBox() {
        let usedCache = Cache.size()

        let maxCache = PrefsCache.cacheLimit
        let freeCache = usedCache > maxCache ? 0 : maxCache - usedCache

        // This is the total max usage, used to draw the bar
        let totalPotentialSize = max(maxCache, usedCache)
        let totalUsage = usedCache
        let cacheWidth = Int(usedCache * 486 / totalPotentialSize)
        let freeWidth = Int(freeCache * 486 / totalPotentialSize)

        var cacheString = ""

        if usedCache > 0 {
            cacheString.append("\(usedCache.rounded(toPlaces: 1)) GB used by cached videos, ")
            cacheBox.isHidden = false
            cacheBox.frame.origin.x = CGFloat(206 )   // We offset by 1px to make the borders overlap
            cacheBox.setFrameSize(NSSize(width: cacheWidth, height: 23))
        } else {
            cacheBox.isHidden = true
        }

        if freeCache > 0 {
            cacheString.append("\(freeCache.rounded(toPlaces: 1)) GB remaining in your cache limit")
            freeBox.isHidden = false
            freeBox.frame.origin.x = CGFloat(206 + cacheWidth - 1)   // We offset by 1px to make the borders overlap
            freeBox.setFrameSize(NSSize(width: freeWidth, height: 23))
        } else {
            cacheString.append("your cache is full!")
            freeBox.isHidden = true
        }

        // (8 GB for packs, 32 GB for the cache, still 8 GB of free cache available for more videos)
        print(cacheString)

        limitLabel.stringValue = cacheString
        print(Cache.size())
    }

    @IBAction func showDownloadIndicatorChange(_ sender: NSButton) {
        PrefsCache.showBackgroundDownloads = sender.state == .on
    }
    @IBAction func automaticallyDownloadClick(_ sender: NSButton) {
        PrefsCache.enableManagement = sender.state == .on
        updateCacheVisibility()
    }

    @IBAction func limitSliderChange(_ sender: NSSlider) {
        PrefsCache.cacheLimit = sender.doubleValue.rounded(toPlaces: 1)
        limitTextField.doubleValue = sender.doubleValue.rounded(toPlaces: 1)
        updateCacheSize()
        updateCacheBox()
    }

    @IBAction func limitTextFieldChange(_ sender: NSTextField) {
        PrefsCache.cacheLimit = sender.doubleValue
        limitSlider.doubleValue = sender.doubleValue
    }

    @IBAction func rotateFrequencyChange(_ sender: NSPopUpButton) {
        PrefsCache.cachePeriodicity = CachePeriodicity(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func restrictWiFiCheck(_ sender: NSButton) {
        PrefsCache.restrictOnWiFi = sender.state == .on
        updateNetworkStatus()
    }

    @IBAction func addCurrentNetworkClick(_ sender: Any) {
        if !PrefsCache.allowedNetworks.contains(Cache.ssid) {
            PrefsCache.allowedNetworks.append(Cache.ssid)
        }
        updateNetworkStatus()
    }
    @IBAction func resetListClick(_ sender: Any) {
        PrefsCache.allowedNetworks.removeAll()
        updateNetworkStatus()
    }

    // Helpers
    func updateNetworkStatus() {
        if PrefsCache.restrictOnWiFi {
            connectedIcon.isHidden = false
            connectedLabel.isHidden = false
            addCurrentNetworkButton.isHidden = false
            resetListButton.isHidden = false
            allowedListLabel.isHidden = false
        } else {
            connectedIcon.isHidden = true
            connectedLabel.isHidden = true
            addCurrentNetworkButton.isHidden = true
            resetListButton.isHidden = true
            allowedListLabel.isHidden = true
        }

        connectedIcon.image = Cache.canNetwork() ?
            NSImage(named: NSImage.statusAvailableName) :
            NSImage(named: NSImage.statusUnavailableName)

        if Cache.ssid != "" {
            connectedLabel.stringValue = "Connected to: " + Cache.ssid + " " + (Cache.canNetwork() ? "(trusted)" : "(restricted)")
        } else {
            connectedLabel.stringValue = "Not connected to Wi-Fi"
        }

        if PrefsCache.allowedNetworks.isEmpty {
            allowedListLabel.stringValue = "No network currently allowed"
        } else {
            allowedListLabel.stringValue = "Allowed: " + PrefsCache.allowedNetworks.joined(separator: ", ")
        }
    }

    // Update UI depending on the master switch position
    func updateCacheVisibility() {
        if PrefsCache.enableManagement {
            automaticContainerView.isHidden = false
            manualContainerView.isHidden = true
        } else {
            automaticContainerView.isHidden = true
            manualContainerView.isHidden = false
        }
    }

    func updateCacheSize() {
        let size = Cache.sizeString()

        if PrefsCache.cacheLimit == 61 {
            limitTextField.isHidden = true
            limitUnitLabel.isHidden = true
            rotateFrequencyPopup.isEnabled = false
            rotateFrequencyLabel.isEnabled = false
        } else {
            limitTextField.isHidden = false
            limitUnitLabel.isHidden = false
            rotateFrequencyPopup.isEnabled = true
            rotateFrequencyLabel.isEnabled = true
        }

        //limitLabel.stringValue = "(Currently \(size))"
        cacheSize.stringValue = "Your videos take \(size) of disk space"
    }

    // Manual mode
    @IBAction func showInFinderClick(_ sender: Any) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: VideoCache.cacheDirectory!)
    }

    @IBAction func pickFolderButton(_ sender: Any) {
        if #available(OSX 10.15, *) {
            errorLog("How did you get in here?")
        } else {
            let openPanel = NSOpenPanel()

            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = false
            openPanel.canCreateDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.title = "Choose Aerial Cache Directory"
            openPanel.prompt = "Choose"
            if Preferences.sharedInstance.customCacheDirectory != "" {
                openPanel.directoryURL = URL(fileURLWithPath: Preferences.sharedInstance.customCacheDirectory!)
            }

            openPanel.begin { result in
                guard result.rawValue == NSFileHandlingPanelOKButton, !openPanel.urls.isEmpty else {
                    return
                }

                let cacheDirectory = openPanel.urls[0]
                Preferences.sharedInstance.customCacheDirectory = cacheDirectory.path
            }
        }
    }

    @IBAction func makeTimeMachineIgnore(_ sender: NSButton) {
        if sender.state == .on {
            // swiftlint:disable:next line_length
            if Aerial.showAlert(question: "Make Time Machine ignore your cache", text: "If you enable this setting, Aerial will move its cache to a Caches folder on your computer. This will have the effect to make Time Machine ignore it on backups\n\nPlease note however that Caches folder can and will be wiped at will by macOS, or other cleanup tools and your videos may disappear.", button1: "I understand the tradeoffs, do it!", button2: "Let me think it over a bit...") {
                // Ok, well you asked for it, don't you dare open an issue about video disappearing :D
                Cache.migrateToCaches()
                // swiftlint:disable:next line_length
                Aerial.showInfoAlert(title: "Cache migration done", text: "Your cache was migrated. You need to close this panel and close System Preferences in order for your new cache settings to work")
            } else {
                sender.state = .off
            }
        } else {
            Cache.migrate()
            // swiftlint:disable:next line_length
            Aerial.showInfoAlert(title: "Cache migration done", text: "Your cache was migrated. You need to close this panel and close System Preferences in order for your new cache settings to work")
        }

        PrefsCache.hideFromTimeMachine = sender.state == .on
    }

    @IBAction func manuallyPIckClick(_ sender: NSButton) {
        PrefsCache.overrideCache = sender.state == .on
    }
}
