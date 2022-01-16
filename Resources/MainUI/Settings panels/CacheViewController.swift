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
    @IBOutlet var packsBox: NSBox!

    // Manual mode
    @IBOutlet var cacheSize: NSTextField!
    @IBOutlet var makeTimeMachineIgnore: NSButton!
    @IBOutlet var makeTimeMachineIgnore2: NSButton!

    @IBOutlet var manuallyPick: NSButton!
    @IBOutlet var pickFolder: NSButton!
    @IBOutlet var manuallyPickLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        makeTimeMachineIgnore.state = TimeMachine.isExcluded() ? .on : .off
        makeTimeMachineIgnore2.state = makeTimeMachineIgnore.state

        manuallyPick.state = PrefsCache.overrideCache ? .on : .off
        if #available(OSX 12, *) {
            updateCachePath()
        } else if #available(OSX 10.15, *) {
            manuallyPick.isEnabled = false
            pickFolder.isHidden = true
        } else {
            updateCachePath()
        }

        // Cache panel
        automaticallyDownloadCheckbox.state = PrefsCache.enableManagement ? .on : .off

        debugLog("tm : \(TimeMachine.isExcluded())")

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

    func updateCachePath() {
        if PrefsCache.overrideCache {
            if let cachePath = Preferences.sharedInstance.customCacheDirectory {
                manuallyPickLabel.stringValue = "Using \(cachePath)"
            } else {
                manuallyPickLabel.stringValue = "Select a path using the folder picker"
            }

        } else {
            manuallyPickLabel.stringValue = "Using your Application Support directory"
        }
    }

    func updateCacheBox() {
        let usedCache = Cache.size()
        let packsSize = Cache.packsSize()

        print("pack size : \(packsSize)")

        var maxCache = PrefsCache.cacheLimit
        var freeCache = usedCache > maxCache ? 0 : maxCache - usedCache

        if PrefsCache.cacheLimit == 61 || !PrefsCache.enableManagement {
            freeCache = 0
            maxCache = usedCache
        }

        // This is the total max usage, used to draw the bar
        var totalPotentialSize = max(maxCache, usedCache) + packsSize
        if totalPotentialSize == 0 {
            totalPotentialSize = 1
        }
        // let totalUsage = usedCache

        let cacheWidth = Int(usedCache * 486 / totalPotentialSize)
        let freeWidth = Int(freeCache * 486 / totalPotentialSize)
        let packsWidth = Int(packsSize * 486 / totalPotentialSize)
        var cacheString = ""

        if usedCache > 0 {
            cacheString.append("\(usedCache.rounded(toPlaces: 1)) GB used by cached videos")
            cacheBox.isHidden = false
            cacheBox.frame.origin.x = CGFloat(206)   // We offset by 1px to make the borders overlap
            cacheBox.setFrameSize(NSSize(width: cacheWidth, height: 25))
        } else {
            cacheString.append("No space used by cached videos")
            cacheBox.isHidden = true
        }

        if freeCache > 0 {
            cacheString.append(", \(freeCache.rounded(toPlaces: 1)) GB remaining in your cache limit")
            freeBox.isHidden = false
            freeBox.frame.origin.x = CGFloat(206 + cacheWidth - 1)   // We offset by 1px to make the borders overlap
            freeBox.setFrameSize(NSSize(width: freeWidth, height: 25))
        } else {
            if PrefsCache.cacheLimit != 61 && PrefsCache.enableManagement {
                cacheString.append(", your cache is full!")
            }
            freeBox.isHidden = true
        }

        if packsSize > 0.01 {
            cacheString.append(", \(packsSize.rounded(toPlaces: 1)) GB used by packs")
            packsBox.isHidden = false
            packsBox.frame.origin.x = CGFloat(206 + cacheWidth + freeWidth - 2)   // We offset by 1px to make the borders overlap
            packsBox.setFrameSize(NSSize(width: packsWidth, height: 25))
        } else {
            packsBox.isHidden = true
        }

        // (8 GB for packs, 32 GB for the cache, still 8 GB of free cache available for more videos)

        limitLabel.stringValue = cacheString
    }

    @IBAction func showDownloadIndicatorChange(_ sender: NSButton) {
        PrefsCache.showBackgroundDownloads = sender.state == .on
    }
    @IBAction func automaticallyDownloadClick(_ sender: NSButton) {
        PrefsCache.enableManagement = sender.state == .on
        updateCacheVisibility()
        updateCacheBox()
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

        // limitLabel.stringValue = "(Currently \(size))"
        cacheSize.stringValue = "Your videos take \(size) of disk space"
    }

    // Manual mode
    @IBAction func showInFinderClick(_ sender: Any) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: VideoCache.cacheDirectory!)
    }

    @IBAction func pickFolderButton(_ sender: Any) {
        let openPanel = NSOpenPanel()

        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Choose Aerial Cache Directory"
        openPanel.prompt = "Choose"

        // Grab the supportPath
        if let customPath = PrefsCache.supportPath {
            if customPath != "" {
                openPanel.directoryURL = URL(fileURLWithPath: customPath)
            }
        }

        openPanel.begin { result in
            guard result.rawValue == NSFileHandlingPanelOKButton, !openPanel.urls.isEmpty else {
                return
            }

            let cacheDirectory = openPanel.urls[0]
            PrefsCache.supportPath = cacheDirectory.path

            // On macOS 12 we save a security scoped bookmark
            if #available(macOS 12, *) {
                do {
                    let cacheBookmark = try cacheDirectory.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil)
                    PrefsCache.supportBookmarkData = cacheBookmark
                } catch {
                    debugLog("Error saving the security scoped bookmark")
                }
            }

            Aerial.showInfoAlert(title: "Cache path changed",
                                 text: "In order for your new cache path to take effect, please close this panel and System Preferences.")
        }
    }

    @IBAction func makeTimeMachineIgnore(_ sender: NSButton) {
        if sender.state == .on {
            TimeMachine.exclude()
        } else {
            TimeMachine.reinclude()
        }
    }

    @IBAction func manuallyPIckClick(_ sender: NSButton) {
        PrefsCache.overrideCache = sender.state == .on
        updateCachePath()
    }
}
