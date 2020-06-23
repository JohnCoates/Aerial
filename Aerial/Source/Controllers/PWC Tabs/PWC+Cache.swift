//
//  PWC+Cache.swift
//  Aerial
//      This is the controller code for the Cache Tab
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Cocoa

extension PreferencesWindowController {
    func setupCacheTab() {
        // Cache panel
        enableCacheManagementCheckbox.state = PrefsCache.enableManagement ? .on : .off

        cacheLimitTextField.doubleValue = PrefsCache.cacheLimit
        cacheLimitSlider.doubleValue = PrefsCache.cacheLimit
        cacheManagementMode.selectItem(at: PrefsCache.cacheMode.rawValue)
        cacheRotation.selectItem(at: PrefsCache.cachePeriodicity.rawValue)

        // Make sure to hide/show the periodicity pref
        updateCacheRotation()

        // And update the size of the cache
        updateCacheSize()

        // Wi-Fi restrictions
        restrictWiFiCheckbox.state = PrefsCache.restrictOnWiFi ? .on : .off
        updateNetworkStatus()

        // And the master switch
        updateCacheVisibility()

        if let cacheDirectory = VideoCache.cacheDirectory {
            cacheLocation.url = URL(fileURLWithPath: cacheDirectory as String)
        } else {
            cacheLocation.url = nil
        }
    }

    func updateNetworkStatus() {
        if PrefsCache.restrictOnWiFi {
            networkIcon.isHidden = false
            connectedToLabel.isHidden = false
            addCurrentNetworkButton.isHidden = false
            resetNetworkListButton.isHidden = false
            allowedNetworksLabel.isHidden = false
        } else {
            networkIcon.isHidden = true
            connectedToLabel.isHidden = true
            addCurrentNetworkButton.isHidden = true
            resetNetworkListButton.isHidden = true
            allowedNetworksLabel.isHidden = true
        }

        networkIcon.image = Cache.canNetwork() ?
            NSImage(named: NSImage.statusAvailableName) :
            NSImage(named: NSImage.statusUnavailableName)

        if Cache.ssid != "" {
            connectedToLabel.stringValue = "Connected to: " + Cache.ssid + " " + (Cache.canNetwork() ? "(trusted)" : "(restricted)")
        } else {
            connectedToLabel.stringValue = "Not connected to Wi-Fi"
        }

        if PrefsCache.allowedNetworks.isEmpty {
            allowedNetworksLabel.stringValue = "No network currently allowed"
        } else {
            allowedNetworksLabel.stringValue = "Allowed: " + PrefsCache.allowedNetworks.joined(separator: ", ")
        }
    }

    // This is the master switch
    @IBAction func enableCacheManagementClick(_ sender: NSButton) {
        PrefsCache.enableManagement = sender.state == .on
        updateCacheVisibility()
    }

    // Update UI depending on the master switch position
    func updateCacheVisibility() {
        if PrefsCache.enableManagement {
            cacheContainerView.isHidden = false
            cacheDisabledContainerView.isHidden = true
        } else {
            cacheContainerView.isHidden = true
            cacheDisabledContainerView.isHidden = false
        }
    }

    // Cache management mode
    @IBAction func cacheModeChange(_ sender: NSPopUpButton) {
        PrefsCache.cacheMode = CacheMode(rawValue: sender.indexOfSelectedItem)!
        updateCacheRotation()
    }

    // The cache refresh periodicity should be hidden when in manual mode
    func updateCacheRotation() {
        if PrefsCache.cacheMode == .manual {
            cacheRotation.isHidden = true
            cacheRotationLabel.isHidden = true
        } else {
            cacheRotation.isHidden = false
            cacheRotationLabel.isHidden = false
        }
    }

    // Cache refresh periodicity
    @IBAction func cacheRotationChange(_ sender: NSPopUpButton) {
        PrefsCache.cachePeriodicity = CachePeriodicity(rawValue: sender.indexOfSelectedItem)!
    }

    // Cache limit
    @IBAction func cacheLimitChange(_ sender: NSTextField) {
        PrefsCache.cacheLimit = sender.doubleValue
        cacheLimitSlider.doubleValue = sender.doubleValue
    }

    @IBAction func cacheLimitSliderChange(_ sender: NSSlider) {
        PrefsCache.cacheLimit = sender.doubleValue.rounded(toPlaces: 1)
        cacheLimitTextField.doubleValue = sender.doubleValue.rounded(toPlaces: 1)
        updateCacheSize()
    }

    func updateCacheSize() {
        let size = Cache.sizeString()

        if PrefsCache.cacheLimit == 61 {
            cacheLimitTextField.isHidden = true
            cacheLimitUnitLabel.isHidden = true
            cacheLimitContainerView.isHidden = true
        } else {
            cacheLimitTextField.isHidden = false
            cacheLimitUnitLabel.isHidden = false
            cacheLimitContainerView.isHidden = false
        }

        // Old one
        cacheSizeTextField.stringValue = "Cache all videos (Current cache size \(size))"
        // New one
        currentCacheLabel.stringValue = "(Currently \(size))"
        cacheDisabledSizeLabel.stringValue = "Your videos take \(size) of disk space"
    }

    @IBAction func showInFinder(_ button: NSButton!) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: VideoCache.cacheDirectory!)
    }

    @IBAction func showAppSupportInFinder(_ sender: Any) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: VideoCache.appSupportDirectory!)
    }

    @IBAction func userSetCacheLocation(_ button: NSButton?) {
        if #available(OSX 10.15, *) {
            // On Catalina, we can't use NSOpenPanel right now
            cacheFolderTextField.stringValue = VideoCache.cacheDirectory!
            changeCacheFolderPanel.makeKeyAndOrderFront(self)
        } else {
            let openPanel = NSOpenPanel()

            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = false
            openPanel.canCreateDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.title = "Choose Aerial Cache Directory"
            openPanel.prompt = "Choose"
            openPanel.directoryURL = cacheLocation.url

            openPanel.begin { result in
                guard result.rawValue == NSFileHandlingPanelOKButton, !openPanel.urls.isEmpty else {
                    return
                }

                let cacheDirectory = openPanel.urls[0]
                self.preferences.customCacheDirectory = cacheDirectory.path
                self.cacheLocation.url = cacheDirectory
            }
        }
    }

    // This is part of the Catalina workaround of showing a Panel
    @IBAction func validateChangeFolderButton(_ sender: Any) {
        debugLog("Changed cache Folder to : \(cacheFolderTextField.stringValue)")
        self.preferences.customCacheDirectory = cacheFolderTextField.stringValue
        self.cacheLocation.url = URL(fileURLWithPath: cacheFolderTextField.stringValue)
        changeCacheFolderPanel.close()
    }

    @IBAction func resetCacheLocation(_ button: NSButton?) {
        preferences.customCacheDirectory = nil
        if let cacheDirectory = VideoCache.appSupportDirectory {
            preferences.customCacheDirectory = cacheDirectory
            cacheLocation.url = URL(fileURLWithPath: cacheDirectory as String)
        }
    }

    @IBAction func downloadNowButton(_ sender: Any) {
        downloadNowButton.isEnabled = false
        prefTabView.selectTabViewItem(at: 0)
        downloadAllVideos()
    }

    // Wi-Fi restrictions
    @IBAction func restrictWiFiCheckboxClick(_ sender: NSButton) {
        PrefsCache.restrictOnWiFi = sender.state == .on
        updateNetworkStatus()
    }

    @IBAction func addCurrentNetworkClick(_ sender: NSButton) {
        if !PrefsCache.allowedNetworks.contains(Cache.ssid) {
            PrefsCache.allowedNetworks.append(Cache.ssid)
        }
        updateNetworkStatus()
    }

    @IBAction func resetNetworkListClick(_ sender: NSButton) {
        PrefsCache.allowedNetworks.removeAll()
        updateNetworkStatus()
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
