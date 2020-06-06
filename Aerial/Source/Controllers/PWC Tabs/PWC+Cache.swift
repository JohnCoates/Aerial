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
        cacheLimitTextField.doubleValue = PrefsCache.cacheLimit
        cacheManagementMode.selectItem(at: PrefsCache.cacheMode.rawValue)
        cacheRotation.selectItem(at: PrefsCache.cachePeriodicity.rawValue)
        //currentCacheLabel.stringValue = "(Currently 0 GiB)"

        // Make sure to hide/show the periodicity pref
        updateCacheRotation()

        // And update the size of the cache
        updateCacheSize()

        // (old stuff)
        if preferences.neverStreamVideos {
            neverStreamVideosCheckbox.state = .on
        }
        if preferences.neverStreamPreviews {
            neverStreamPreviewsCheckbox.state = .on
        }
        if !preferences.cacheAerials {
            cacheAerialsAsTheyPlayCheckbox.state = .off
        }

        if let cacheDirectory = VideoCache.cacheDirectory {
            cacheLocation.url = URL(fileURLWithPath: cacheDirectory as String)
        } else {
            cacheLocation.url = nil
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
    }

    func updateCacheSize() {
        let size = Cache.sizeString()

        // Old one
        cacheSizeTextField.stringValue = "Cache all videos (Current cache size \(size))"
        // New one
        currentCacheLabel.stringValue = "(Currently \(size))"

        print("Is full : \(Cache.isFull())")
    }

    @IBAction func cacheAerialsAsTheyPlayClick(_ button: NSButton!) {
        let onState = button.state == .on
        preferences.cacheAerials = onState
        debugLog("UI cacheAerialAsTheyPlay: \(onState)")
    }

    @IBAction func neverStreamVideosClick(_ button: NSButton!) {
        let onState = button.state == .on
        preferences.neverStreamVideos = onState
        debugLog("UI neverStreamVideos: \(onState)")
    }

    @IBAction func neverStreamPreviewsClick(_ button: NSButton!) {
        let onState = button.state == .on
        preferences.neverStreamPreviews = onState
        debugLog("UI neverStreamPreviews: \(onState)")
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
}
