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
    func updateCacheSize() {
        // get your directory url
        let documentsDirectoryURL = URL(fileURLWithPath: VideoCache.cacheDirectory!)

        // FileManager.default.urls(for: VideoCache.cacheDirectory, in: .userDomainMask).first!

        // check if the url is a directory
        if (try? documentsDirectoryURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            var folderSize = 0
            (FileManager.default.enumerator(at: documentsDirectoryURL, includingPropertiesForKeys: nil)?.allObjects as? [URL])?.lazy.forEach {
                folderSize += (try? $0.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0
            }
            let byteCountFormatter =  ByteCountFormatter()
            byteCountFormatter.allowedUnits = .useGB
            byteCountFormatter.countStyle = .file
            let sizeToDisplay = byteCountFormatter.string(for: folderSize) ?? ""
            debugLog("Cache size : \(sizeToDisplay)")
            cacheSizeTextField.stringValue = "Cache all videos (Current cache size \(sizeToDisplay))"
        }
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

    @IBAction func userSetCacheLocation(_ button: NSButton?) {
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

    @IBAction func resetCacheLocation(_ button: NSButton?) {
        preferences.customCacheDirectory = nil
        if let cacheDirectory = VideoCache.cacheDirectory {
            cacheLocation.url = URL(fileURLWithPath: cacheDirectory as String)
        }
    }

    @IBAction func downloadNowButton(_ sender: Any) {
        downloadNowButton.isEnabled = false
        prefTabView.selectTabViewItem(at: 0)
        downloadAllVideos()
    }
}
