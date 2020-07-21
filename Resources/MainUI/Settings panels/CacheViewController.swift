//
//  CacheViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

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

    // Manual mode
    @IBOutlet var cacheSize: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

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
    }

    @IBAction func automaticallyDownloadClick(_ sender: NSButton) {
        PrefsCache.enableManagement = sender.state == .on
        updateCacheVisibility()
    }

    @IBAction func limitSliderChange(_ sender: NSSlider) {
        PrefsCache.cacheLimit = sender.doubleValue.rounded(toPlaces: 1)
        limitTextField.doubleValue = sender.doubleValue.rounded(toPlaces: 1)
        updateCacheSize()
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

        limitLabel.stringValue = "(Currently \(size))"
        cacheSize.stringValue = "Your videos take \(size) of disk space"
    }

    // Manual mode
    @IBAction func showInFinderClick(_ sender: Any) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: VideoCache.cacheDirectory!)
    }
}
