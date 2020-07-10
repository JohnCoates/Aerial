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
        cacheRotation.selectItem(at: PrefsCache.cachePeriodicity.rawValue)

        // Update the size of the cache and associated controls
        updateCacheSize()

        // Wi-Fi restrictions?
        restrictWiFiCheckbox.state = PrefsCache.restrictOnWiFi ? .on : .off
        updateNetworkStatus()

        // And the master switch!
        updateCacheVisibility()
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
            cacheRotation.isEnabled = false
            cacheRotationLabel.isEnabled = false
        } else {
            cacheLimitTextField.isHidden = false
            cacheLimitUnitLabel.isHidden = false
            cacheRotation.isEnabled = true
            cacheRotationLabel.isEnabled = true
        }

        currentCacheLabel.stringValue = "(Currently \(size))"
        cacheDisabledSizeLabel.stringValue = "Your videos take \(size) of disk space"
    }

    @IBAction func showInFinder(_ button: NSButton!) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: VideoCache.cacheDirectory!)
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
