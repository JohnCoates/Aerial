//
//  PWC+Videos.swift
//  Aerial
//      This is the controller code for the Videos Tab
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Cocoa
import AVFoundation
import VideoToolbox

final class TimeOfDay {
    let title: String
    var videos: [AerialVideo] = [AerialVideo]()

    init(title: String) {
        self.title = title
    }
}

final class City {
    var night: TimeOfDay = TimeOfDay(title: "night")
    var day: TimeOfDay = TimeOfDay(title: "day")
    let name: String
    //var videos: [AerialVideo] = [AerialVideo]()

    init(name: String) {
        self.name = name
    }

    func addVideoForTimeOfDay(_ timeOfDay: String, video: AerialVideo) {
        if timeOfDay.lowercased() == "night" {
            video.arrayPosition = night.videos.count
            night.videos.append(video)
        } else {
            video.arrayPosition = day.videos.count
            day.videos.append(video)
        }
    }
}

extension PreferencesWindowController {
    // swiftlint:disable:next cyclomatic_complexity
    func setupVideosTab() {
        // Help popover, GVA detection requires 10.13
        if #available(OSX 10.13, *) {
            if !VTIsHardwareDecodeSupported(kCMVideoCodecType_H264) {
                popoverH264Label.stringValue = "H264 acceleration not supported"
                popoverH264Indicator.image = NSImage(named: NSImage.statusUnavailableName)
            }
            if !VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC) {
                popoverHEVCLabel.stringValue = "HEVC Main10 acceleration not supported"
                popoverHEVCIndicator.image = NSImage(named: NSImage.statusUnavailableName)
            } else {
                let hardwareDetection = HardwareDetection.sharedInstance
                switch hardwareDetection.isHEVCMain10HWDecodingAvailable() {
                case .supported:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration is supported"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.statusAvailableName)
                case .notsupported:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration is not supported"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.statusUnavailableName)
                case .partial:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration is partially supported"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.statusPartiallyAvailableName)
                default:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration status unknown"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.cautionName)
                }
            }
        } else {
            // Fallback on earlier versions
            popoverHEVCIndicator.isHidden = true
            popoverH264Indicator.image = NSImage(named: NSImage.cautionName)
            popoverH264Label.stringValue = "macOS 10.13 or above required"
            popoverHEVCLabel.stringValue = "Hardware acceleration status unknown"
        }

        // Preview video
        playerView.player = player
        playerView.controlsStyle = .none
        if #available(OSX 10.10, *) {
            playerView.videoGravity = .resizeAspectFill
        }

        updateCacheSize()
        outlineView.floatsGroupRows = false
        outlineView.menu = videoMenu
        videoMenu.delegate = self

        // To loop playback, we catch the end of the video to rewind
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)

        if preferences.overrideOnBattery {
            overrideOnBatteryCheckbox.state = .on
            changeBatteryOverrideState(to: true)
        } else {
            changeBatteryOverrideState(to: false)
        }
        if preferences.powerSavingOnLowBattery {
            powerSavingOnLowBatteryCheckbox.state = .on
        }
        if !preferences.allowSkips {
            rightArrowKeyPlaysNextCheckbox.state = .off
        }

        if #available(OSX 10.13, *) {
            popupVideoFormat.selectItem(at: preferences.videoFormat!)
        } else {
            preferences.videoFormat = Preferences.VideoFormat.v1080pH264.rawValue
            popupVideoFormat.selectItem(at: preferences.videoFormat!)
            popupVideoFormat.isEnabled = false
        }

        alternatePopupVideoFormat.selectItem(at: preferences.alternateVideoFormat!)

        fadeInOutModePopup.selectItem(at: preferences.fadeMode!)

        // We need catalina for HDR !
        if #available(OSX 10.15, *) {
            if !preferences.useHDR {
                useHDRCheckbox.state = .off
            }
        } else {
            useHDRCheckbox.state = .off
            useHDRCheckbox.isEnabled = false
        }
    }

    @IBAction func rightArrowKeyPlaysNextClick(_ sender: NSButton) {
        let onState = sender.state == .on
        preferences.allowSkips = onState
        debugLog("UI allowSkips \(onState)")
    }

    @IBAction func overrideOnBatteryClick(_ sender: NSButton) {
        let onState = sender.state == .on
        preferences.overrideOnBattery = onState
        changeBatteryOverrideState(to: onState)
        debugLog("UI overrideOnBattery \(onState)")
    }

    @IBAction func powerSavingOnLowClick(_ sender: NSButton) {
        let onState = sender.state == .on
        preferences.powerSavingOnLowBattery = onState
        debugLog("UI powerSavingOnLow \(onState)")
    }

    @IBAction func alternateVideoFormatChange(_ sender: NSPopUpButton) {
        debugLog("UI alternatePopupVideoFormat: \(sender.indexOfSelectedItem)")
        preferences.alternateVideoFormat = sender.indexOfSelectedItem
        changeBatteryOverrideState(to: true)
    }

    func changeBatteryOverrideState(to: Bool) {
        alternatePopupVideoFormat.isEnabled = to
        if !to || (to && preferences.alternateVideoFormat != Preferences.AlternateVideoFormat.powerSaving.rawValue) {
            powerSavingOnLowBatteryCheckbox.isEnabled = to
        } else {
            powerSavingOnLowBatteryCheckbox.isEnabled = false
        }
    }

    @IBAction func popupVideoFormatChange(_ sender: NSPopUpButton) {
        debugLog("UI popupVideoFormat: \(sender.indexOfSelectedItem)")
        preferences.videoFormat = sender.indexOfSelectedItem
        preferences.synchronize()
        outlineView.reloadData()
    }

    @IBAction func useHDRChange(_ sender: NSButton) {
        let onState = sender.state == .on
        preferences.useHDR = onState
        debugLog("UI useHDR \(onState)")
    }

    @IBAction func helpButtonClick(_ button: NSButton!) {
        popover.show(relativeTo: button.preparedContentRect, of: button, preferredEdge: .maxY)
    }

    @IBAction func helpPowerButtonClick(_ button: NSButton!) {
        popoverPower.show(relativeTo: button.preparedContentRect, of: button, preferredEdge: .maxY)
    }

    @IBAction func helpHDRButtonClick(_ button: NSButton) {
        popoverHDR.show(relativeTo: button.preparedContentRect, of: button, preferredEdge: .maxY)
    }

    @IBAction func fadeInOutModePopupChange(_ sender: NSPopUpButton) {
        debugLog("UI fadeInOutMode: \(sender.indexOfSelectedItem)")
        preferences.fadeMode = sender.indexOfSelectedItem
        preferences.synchronize()
    }

    func updateDownloads(done: Int, total: Int, progress: Double) {
        print("VMQueue: done : \(done) \(total) \(progress)")

        if total == 0 {
            downloadProgressIndicator.isHidden = true
            downloadStopButton.isHidden = true
            downloadNowButton.isEnabled = true
        } else if progress == 0 {
            downloadNowButton.isEnabled = false
            downloadProgressIndicator.isHidden = false
            downloadStopButton.isHidden = false
            downloadProgressIndicator.doubleValue = Double(done)
            downloadProgressIndicator.maxValue = Double(total)
            downloadProgressIndicator.toolTip = "\(done) / \(total) video(s) downloaded"
        } else {
            downloadProgressIndicator.doubleValue = Double(done) + progress
        }
    }

    @IBAction func cancelDownloadsClick(_ sender: Any) {
        debugLog("UI cancelDownloadsClick")
        let videoManager = VideoManager.sharedInstance
        videoManager.cancelAll()
    }

    @IBAction func openInQuickTime(_ sender: NSMenuItem) {
        if let video = sender.representedObject as? AerialVideo {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: VideoCache.cachePath(forVideo: video)!)
        }
    }

    @IBAction func rightClickDownloadVideo(_ sender: NSMenuItem) {
        if let video = sender.representedObject as? AerialVideo {
            let videoManager = VideoManager.sharedInstance
            if !videoManager.isVideoQueued(id: video.id) {
                videoManager.queueDownload(video)
            }
        }
    }

    @IBAction func rightClickMoveToTrash(_ sender: NSMenuItem) {
        if let video = sender.representedObject as? AerialVideo {
            VideoCache.moveToTrash(video: video)
            let videoManager = VideoManager.sharedInstance
            videoManager.updateAllCheckCellView()
        }
    }

    // MARK: Wikipedia popup link
    @IBAction func linkToWikipediaDolbyVisionClick(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://en.wikipedia.org/wiki/Dolby_Laboratories#Video_processing")!
        workspace.open(url)
    }

    // MARK: Video playback

    // Rewind preview video when reaching end
    @objc func playerItemDidReachEnd(notification: Notification) {
        guard let playerItem: AVPlayerItem = notification.object as? AVPlayerItem,
            let asset = playerItem.asset as? AVURLAsset, asset.url.isFileURL
            else { return }
        playerItem.seek(to: .zero, completionHandler: nil)
        player.play()
    }

    // MARK: - Main Menu
    @IBAction func outlineViewSettingsClick(_ button: NSButton) {
        let menu = NSMenu()

        menu.insertItem(withTitle: "Check Only Cached",
                        action: #selector(PreferencesWindowController.outlineViewCheckCached(button:)),
                        keyEquivalent: "",
                        at: 0)
        menu.insertItem(withTitle: "Check Only 4K",
                        action: #selector(PreferencesWindowController.outlineViewCheck4K(button:)),
                        keyEquivalent: "",
                        at: 1)
        menu.insertItem(withTitle: "Check All",
                        action: #selector(PreferencesWindowController.outlineViewCheckAll(button:)),
                        keyEquivalent: "",
                        at: 2)
        menu.insertItem(withTitle: "Uncheck All",
                        action: #selector(PreferencesWindowController.outlineViewUncheckAll(button:)),
                        keyEquivalent: "",
                        at: 3)
        menu.insertItem(NSMenuItem.separator(), at: 4)
        menu.insertItem(withTitle: "Download Checked",
                        action: #selector(PreferencesWindowController.outlineViewDownloadChecked(button:)),
                        keyEquivalent: "",
                        at: 5)
        menu.insertItem(withTitle: "Download All",
                        action: #selector(PreferencesWindowController.outlineViewDownloadAll(button:)),
                        keyEquivalent: "",
                        at: 6)
        menu.insertItem(NSMenuItem.separator(), at: 7)
        menu.insertItem(withTitle: "Custom Videos...",
                        action: #selector(PreferencesWindowController.outlineViewCustomVideos(button:)),
                        keyEquivalent: "",
                        at: 8)

        let event = NSApp.currentEvent
        NSMenu.popUpContextMenu(menu, with: event!, for: button)
    }

    @objc func outlineViewCustomVideos(button: NSButton) {
        customVideosController.show(sender: button, controller: self)
    }

    @objc func outlineViewUncheckAll(button: NSButton) {
        setAllVideos(inRotation: false)
    }

    @objc func outlineViewCheckAll(button: NSButton) {
        setAllVideos(inRotation: true)
    }

    @objc func outlineViewCheck4K(button: NSButton) {
        guard let videos = videos else {
            return
        }

        for video in videos {
            if video.url4KHEVC != "" {
                preferences.setVideo(videoID: video.id,
                                     inRotation: true,
                                     synchronize: false)
            } else {
                preferences.setVideo(videoID: video.id,
                                     inRotation: false,
                                     synchronize: false)
            }
        }
        preferences.synchronize()

        outlineView.reloadData()
    }

    @objc func outlineViewCheckCached(button: NSButton) {
        guard let videos = videos else {
            return
        }

        for video in videos {
            if video.isAvailableOffline {
                preferences.setVideo(videoID: video.id,
                                     inRotation: true,
                                     synchronize: false)
            } else {
                preferences.setVideo(videoID: video.id,
                                     inRotation: false,
                                     synchronize: false)
            }
        }
        preferences.synchronize()

        outlineView.reloadData()
    }

    @objc func outlineViewDownloadChecked(button: NSButton) {
        guard let videos = videos else {
            return
        }
        let videoManager = VideoManager.sharedInstance

        for video in videos {
            if preferences.videoIsInRotation(videoID: video.id) && !video.isAvailableOffline {
                if !videoManager.isVideoQueued(id: video.id) {
                    videoManager.queueDownload(video)
                }
            }
        }
    }

    @objc func outlineViewDownloadAll(button: NSButton) {
        downloadAllVideos()
    }

    func downloadAllVideos() {
        let videoManager = VideoManager.sharedInstance
        for city in cities {
            for video in city.day.videos where !video.isAvailableOffline {
                if !videoManager.isVideoQueued(id: video.id) {
                    videoManager.queueDownload(video)
                }
            }
            for video in city.night.videos where !video.isAvailableOffline {
                if !videoManager.isVideoQueued(id: video.id) {
                    videoManager.queueDownload(video)
                }
            }
        }
    }

    func setAllVideos(inRotation: Bool) {
        guard let videos = videos else {
            return
        }

        for video in videos {
            preferences.setVideo(videoID: video.id,
                                 inRotation: inRotation,
                                 synchronize: false)
        }
        preferences.synchronize()

        outlineView.reloadData()
    }

    // MARK: - Video sets menu
    @IBAction func videoSetsButtonClick(_ sender: NSButton) {
        // First we make an array of the sorted dictionnary keys
        let sortedKeys = Array(preferences.videoSets).sorted(by: {$0.0 < $1.0})

        // We make a submenu with the current sets to save/override or create a new one
        let saveSubMenu = NSMenu()
        saveSubMenu.insertItem(withTitle: "New set...",
                               action: #selector(PreferencesWindowController.createNewVideoSet),
                               keyEquivalent: "",
                               at: 0)
        saveSubMenu.insertItem(NSMenuItem.separator(), at: 1)
        var ssi = 2
        for key in sortedKeys {
            saveSubMenu.insertItem(withTitle: key.key,
                                   action: #selector(PreferencesWindowController.updateVideoSet(menuItem:)),
                                   keyEquivalent: "",
                                   at: ssi)
            ssi += 1
        }

        // We make a submenu with the current sets to be deleted
        let deleteSubMenu = NSMenu()
        ssi = 0
        for key in sortedKeys {
            deleteSubMenu.insertItem(withTitle: key.key,
                                     action: #selector(PreferencesWindowController.deleteVideoSet(menuItem:)),
                                     keyEquivalent: "",
                                     at: ssi)
            ssi += 1
        }

        // Main menu
        let menu = NSMenu()
        let saveMenuItem = menu.insertItem(withTitle: "Save as...",
                                           action: nil,
                                           keyEquivalent: "",
                                           at: 0)
        menu.setSubmenu(saveSubMenu, for: saveMenuItem)         // We attach the submenu created above

        let deleteMenuItem = menu.insertItem(withTitle: "Delete set",
                                             action: nil,
                                             keyEquivalent: "",
                                             at: 1)

        if !preferences.videoSets.isEmpty {
            menu.setSubmenu(deleteSubMenu, for: deleteMenuItem) // We attach the submenu created above, if any
        }

        menu.insertItem(NSMenuItem.separator(), at: 2)

        ssi = 3
        for key in sortedKeys {
            menu.insertItem(withTitle: key.key,
                            action: #selector(PreferencesWindowController.activateVideoSet(menuItem:)),
                            keyEquivalent: "",
                            at: ssi)
            ssi += 1
        }
        let event = NSApp.currentEvent
        NSMenu.popUpContextMenu(menu, with: event!, for: sender)
    }

    @objc func createNewVideoSet() {
        addVideoSetPanel.makeKeyAndOrderFront(self)
    }

    @IBAction func createNewVideoSetConfirm(_ sender: Any) {
        if preferences.videoSets.keys.contains(addVideoSetTextField.stringValue) {
            addVideoSetErrorLabel.isHidden = false
        } else {
            addVideoSetErrorLabel.isHidden = true

            var playlist = [String]()
            for video in videos! {
                let isInRotation = preferences.videoIsInRotation(videoID: video.id)
                if isInRotation {
                    playlist.append(video.id)
                }
            }

            preferences.videoSets[addVideoSetTextField.stringValue] = playlist

            addVideoSetPanel.close()
        }
    }

    @IBAction func createNewVideoSetCancel(_ sender: Any) {
        addVideoSetPanel.close()
    }

    @objc func updateVideoSet(menuItem: NSMenuItem) {
        if preferences.videoSets.keys.contains(menuItem.title) {
            var playlist = [String]()
            for video in videos! {
                let isInRotation = preferences.videoIsInRotation(videoID: video.id)
                if isInRotation {
                    playlist.append(video.id)
                }
            }

            preferences.videoSets[menuItem.title] = playlist
        }
    }

    @objc func deleteVideoSet(menuItem: NSMenuItem) {
        debugLog("Deleting video set : \(menuItem.title)")
        if preferences.videoSets.keys.contains(menuItem.title) {
            preferences.videoSets.removeValue(forKey: menuItem.title)
        }
    }

    @objc func activateVideoSet(menuItem: NSMenuItem) {
        if preferences.videoSets.keys.contains(menuItem.title) {
            // First we disable every video
            setAllVideos(inRotation: false)

            // Then we enable the set
            for videoid in preferences.videoSets[menuItem.title]! {
                preferences.setVideo(videoID: videoid,
                                     inRotation: true,
                                     synchronize: false)
            }
        }
    }

    // MARK: - Outline View Delegate & Data Source
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item else { return cities.count }

        switch item {
        case let timeOfDay as TimeOfDay:
            return timeOfDay.videos.count
        case let city as City:

            var count = 0

            if !city.night.videos.isEmpty {
                count += 1
            }

            if !city.day.videos.isEmpty {
                count += 1
            }
            return count
        default:
            return 0
        }

    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        switch item {
        case is TimeOfDay:
            return true
        case is City:
            return true
        default:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item else { return cities[index] }

        switch item {
        case let city as City:

            if index == 0 && !city.day.videos.isEmpty {
                return city.day
            } else {
                return city.night
            }
            //let city = item as! City
            //return city.videos[index]

        case let timeOfDay as TimeOfDay:
            return timeOfDay.videos[index]

        default:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView,
                     objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        switch item {
        case let city as City:
            return city.name
        case let timeOfDay as TimeOfDay:
            return timeOfDay.title
        default:
            return "untitled"
        }
    }

    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, dataCellFor tableColumn: NSTableColumn?, item: Any) -> NSCell? {
        let row = outlineView.row(forItem: item)
        return tableColumn!.dataCell(forRow: row) as? NSCell
    }

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        switch item {
        case is TimeOfDay:
            return true
        case is City:
            return true
        default:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        switch item {
        case let city as City:
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"),
                                            owner: nil) as! NSTableCellView
            // note: if owner = self, awakeFromNib will be called for each created cell !
            view.textField?.stringValue = city.name

            return view
        case let timeOfDay as TimeOfDay:
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"),
                                            owner: nil) as! NSTableCellView
            // note: if owner = self, awakeFromNib will be called for each created cell !

            view.textField?.stringValue = timeOfDay.title.capitalized

            let bundle = Bundle(for: PreferencesWindowController.self)

            // Use -dark icons in macOS 10.14+ Dark Mode
            let timeManagement = TimeManagement.sharedInstance
            var postfix = ""
            if timeManagement.isDarkModeEnabled() {
                postfix = "-dark"
            }

            if let imagePath = bundle.path(forResource: "icon-\(timeOfDay.title)"+postfix,
                                           ofType: "pdf") {
                let image = NSImage(contentsOfFile: imagePath)
                image!.size.width = 13
                image!.size.height = 13
                view.imageView?.image = image
                // TODO, change the icons for dark mode

            } else {
                errorLog("\(#file) failed to find time of day icon")
            }

            return view
        case let video as AerialVideo:
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CheckCell"),
                                            owner: nil) as! CheckCellView   // if owner = self, awakeFromNib will be called for each created cell !
            // Mark the new view for this video for subsequent callbacks
            let videoManager = VideoManager.sharedInstance
            videoManager.addCheckCellView(id: video.id, checkCellView: view)

            view.setVideo(video: video)     // For our Add button
            view.adaptIndicators()

            if video.secondaryName != "" {
                view.textField?.stringValue = video.secondaryName
            } else {
                // One based index
                let number = video.arrayPosition + 1
                let numberFormatter = NumberFormatter()

                numberFormatter.numberStyle = NumberFormatter.Style.spellOut
                guard
                    let numberString = numberFormatter.string(from: number as NSNumber)
                    else {
                        errorLog("outlineView: failed to create number with formatter")
                        return nil
                }

                view.textField?.stringValue = numberString.capitalized
            }

            let isInRotation = preferences.videoIsInRotation(videoID: video.id)

            view.checkButton.state = isInRotation ? .on : .off

            view.onCheck = { checked in
                self.preferences.setVideo(videoID: video.id,
                                          inRotation: checked)
            }

            return view
        default:
            return nil
        }
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        switch item {
        case let video as AerialVideo:
            player = AVPlayer()
            playerView.player = player
            player.isMuted = true

            debugLog("Playing this preview \(video)")
            // Workaround for cached videos generating online traffic
            if video.isAvailableOffline {
                previewDisabledTextfield.isHidden = true
                let localurl = URL(fileURLWithPath: VideoCache.cachePath(forVideo: video)!)
                let localitem = AVPlayerItem(url: localurl)
                player.replaceCurrentItem(with: localitem)
                player.play()
            } else if !preferences.neverStreamPreviews {
                previewDisabledTextfield.isHidden = true
                let asset = cachedOrCachingAsset(video.url)
                let item = AVPlayerItem(asset: asset)
                player.replaceCurrentItem(with: item)
                player.play()
            } else {
                previewDisabledTextfield.isHidden = false
            }

            return true
        case is TimeOfDay:
            return false
        default:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        switch item {
        case is AerialVideo:
            return 19
        case is TimeOfDay:
            return 18
        case is City:
            return 17
        default:
            fatalError("unhandled item in heightOfRowByItem for \(item)")
        }
    }
    func outlineView(_ outlineView: NSOutlineView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
        return 0
    }
}

// MARK: - Menu delegate

extension PreferencesWindowController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let row = self.outlineView.clickedRow
        guard row != -1 else { return }
        let rowItem = self.outlineView.item(atRow: row)

        if let video = rowItem as? AerialVideo {
            if video.isAvailableOffline {
                rightClickOpenQuickTimeMenuItem.isHidden = false
                rightClickMoveToTrashMenuItem.isHidden = false
                rightClickDownloadVideoMenuItem.isHidden = true
                for item in menu.items {
                    item.representedObject = rowItem
                }
            } else {
                rightClickOpenQuickTimeMenuItem.isHidden = true
                rightClickMoveToTrashMenuItem.isHidden = true
                rightClickDownloadVideoMenuItem.isHidden = false
                for item in menu.items {
                    item.representedObject = rowItem
                }
            }
        } else {
            for item in menu.items {
                item.isHidden = true
            }
        }
    }
}

// swiftlint:disable:this file_length
