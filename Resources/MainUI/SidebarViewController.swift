//
//  SidebarViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 15/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

enum SidebarMenus {
    case videos, settings, infos
}

class SidebarViewController: NSViewController {

    @IBOutlet var sidebarOutlineView: SidebarOutlineView!

    @IBOutlet var videosButton: NSButton!
    @IBOutlet var settingsButton: NSButton!
    @IBOutlet var infoButton: NSButton!

    // For the download indicator
    @IBOutlet var downloadIndicatorProgress: NSProgressIndicator!
    @IBOutlet var downloadIndicatorLabel: NSTextField!
    @IBOutlet var downloadCancelButton: NSButton!

    var windowController: PanelWindowController?

    // Always start with the videos panel selected
    var menuSelection: SidebarMenus = .videos

    @IBOutlet var closeButton: NSButton!

    var menuPath = ""   // eh...

    override func viewDidLoad() {
        super.viewDidLoad()

        closeButton.isHighlighted = true
        sidebarOutlineView.delegate = self
        sidebarOutlineView.dataSource = self

        // Setup the updates for the download status
        let videoManager = VideoManager.sharedInstance
        videoManager.addCallback { done, total in
            self.updateDownloads(done: done, total: total, progress: 0)
        }
        videoManager.addProgressCallback { done, total, progress in
            self.updateDownloads(done: done, total: total, progress: progress)
        }

        videosButton.image = Aerial.getSymbol("film")?.tinting(with: NSColor.secondaryLabelColor)
        videosButton.alternateImage = Aerial.getAccentedSymbol("film")

        settingsButton.image = Aerial.getSymbol("gear")?.tinting(with: NSColor.secondaryLabelColor)
        settingsButton.alternateImage = Aerial.getAccentedSymbol("gear")

        infoButton.image = Aerial.getSymbol("info.circle")?.tinting(with: NSColor.secondaryLabelColor)
        infoButton.alternateImage = Aerial.getAccentedSymbol("info.circle")
    }

    override func viewDidAppear() {
        // When we are really there, we can look for the data
        // This will trigger the refresh of the VideosViewController
        VideoList.instance.addCallback {
            Sidebar.instance.refreshVideos()
            self.sidebarOutlineView.reloadData()
            self.sidebarOutlineView.expandItem(nil, expandChildren: true)
            self.sidebarOutlineView.selectRowIndexes([0], byExtendingSelection: false)
        }
    }

    // This is used to simulate the radio switch on the top left, this switch the sidebar into different modes
    @IBAction func menuButtonClick(_ sender: NSButton) {
        if sender == videosButton {
            videosButton.state = .on
            settingsButton.state = .off
            infoButton.state = .off
            updateSidebarMenu(.videos)
        } else if sender == settingsButton {
            videosButton.state = .off
            settingsButton.state = .on
            infoButton.state = .off
            updateSidebarMenu(.settings)
        } else {
            videosButton.state = .off
            settingsButton.state = .off
            infoButton.state = .on
            updateSidebarMenu(.infos)
        }
    }

    private func updateSidebarMenu(_ menu: SidebarMenus) {
        if menu != menuSelection {
            windowController?.switchFrom(menuSelection, to: menu)

            // Make sure we mark the current one
            menuSelection = menu

            sidebarOutlineView.reloadData()
            sidebarOutlineView.expandItem(nil, expandChildren: true)
            sidebarOutlineView.selectRowIndexes([0], byExtendingSelection: false)
        }
    }

    @IBAction func closeButton(_ sender: Any) {
        // This seems needed for screensavers as our lifecycle is different
        // from a regular app and we may be kept in memory by System Preferences
        // and our settings won't get saved as they should be
        Preferences.sharedInstance.synchronize()

        if Aerial.instance.appMode {
            NSApplication.shared.terminate(nil)
        } else {
            windowController!.window?.sheetParent?.endSheet(windowController!.window!)
        }
    }

    // MARK: Download indicator
    // Update the status of the download bar at the bottom of the sidebar
    func updateDownloads(done: Int, total: Int, progress: Double) {
        if total == 0 {
            downloadIndicatorProgress.isHidden = true
            downloadIndicatorLabel.isHidden = true
            downloadCancelButton.isHidden = true
            windowController!.updateViewInPlace()
        } else if progress == 0 {
            downloadIndicatorProgress.isHidden = false
            downloadIndicatorLabel.isHidden = false
            downloadCancelButton.isHidden = false
            downloadIndicatorProgress.doubleValue = Double(done)
            downloadIndicatorProgress.maxValue = Double(total)
            downloadIndicatorProgress.toolTip = "\(done) / \(total) queued"
            downloadIndicatorLabel.stringValue = "\(done) / \(total) queued"
        } else {
            downloadIndicatorProgress.doubleValue = Double(done) + progress
        }
    }

    @IBAction func cancelDownloads(_ sender: Any) {
        let videoManager = VideoManager.sharedInstance
        videoManager.cancelAll()
    }
}

extension SidebarViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let header = item as? Sidebar.Header {
            return header.entries.count
        }

        switch menuSelection {
        case .videos:
            return Sidebar.instance.videos.count
        case .settings:
            return Sidebar.instance.settings.count
        case .infos:
            return Sidebar.instance.infos.count
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let header = item as? Sidebar.Header {
            return header.entries[index]
        }

        switch menuSelection {
        case .videos:
            return Sidebar.instance.videos[index]
        case .settings:
            return Sidebar.instance.settings[index]
        case .infos:
            return Sidebar.instance.infos[index]
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is Sidebar.Header {
            return true
        }

        return false
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is Sidebar.Header {
            return 24
        } else {
            return 30
        }
    }
}

extension SidebarViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?

        if let header = item as? Sidebar.Header {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = header.name
            }
        } else if let entry = item as? Sidebar.MenuEntry {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = entry.name
            }
            if let imageView = view?.imageView {
                imageView.image = Sidebar.iconFor(entry.path, name: entry.name)
                imageView.image?.isTemplate = true
                imageView.sizeThatFits(CGSize(width: 24, height: 24))   // Hmm
            }
        }

        // More code here
        return view
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView else {
            return
        }

        let selectedIndex = outlineView.selectedRow
        if let entry = outlineView.item(atRow: selectedIndex) as? Sidebar.MenuEntry {
            windowController!.switchTo(entry.path)
        }
    }

    @available(OSX 10.16, *)
    func outlineView(_ outlineView: NSOutlineView, tintConfigurationForItem item: Any) -> NSTintConfiguration? {
        if let entry = item as? Sidebar.MenuEntry {
            if entry.name == "Favorites" {
                return NSTintConfiguration(fixedColor: .init(red: 0.996, green: 0.741, blue: 0.066, alpha: 1.0))
            } else {
                return NSTintConfiguration.default
            }
        }

        return nil
    }

}

// Right click menu
extension SidebarViewController: SidebarOutlineViewDelegate {

    func outlineView(outlineView: NSOutlineView, menuForItem item: Any) -> NSMenu? {
        print("menu")
        // Make sure we're right clicking a menu entry
        if let entry = item as? Sidebar.MenuEntry {
            if entry.path.starts(with: "videos:") {
                let idx = entry.path.firstIndex(of: ":")
                let path = String(entry.path[idx!...].dropFirst()) // Oh Swift...

                menuPath = path         // Store it for later use in selectors, it's ugly I know

                // Grab all the videos
                var videos: [AerialVideo]

                if let mode = VideoList.instance.modeFromPath(path) {
                    if mode == .hidden {
                        // No menu for hidden mode
                        return nil
                    }

                    let index = Int(path.split(separator: ":")[1])!
                    videos = VideoList.instance.getVideosForSource(index, mode: mode)
                } else {
                    // all
                    videos = VideoList.instance.videos.sorted { $0.secondaryName < $1.secondaryName }
                }

                guard !videos.isEmpty else {
                    return nil
                }

                let menu = NSMenu()

                var hasUnfavs = false
                var hasFavs = false

                // Add/remove favorites
                if !videos.filter({ !PrefsVideos.favorites.contains($0.id) }).isEmpty {
                    let item = NSMenuItem(title: "Favorite videos", action: #selector(favoriteVideos(_:)), keyEquivalent: "")
                    item.setIcons("star.fill")
                    menu.addItem(item)
                    hasUnfavs = true
                }

                if !videos.filter({ PrefsVideos.favorites.contains($0.id) }).isEmpty {
                    let item = NSMenuItem(title: "Unfavorite videos", action: #selector(unfavoriteVideos(_:)), keyEquivalent: "")
                    item.setIcons("star")
                    menu.addItem(item)
                    hasFavs = true
                }

                // Don't show the hide videos option if we only have favs in that list
                if !(hasFavs && !hasUnfavs) {
                    menu.addItem(NSMenuItem.separator())

                    let item = NSMenuItem(title: "Hide videos", action: #selector(hideVideos(_:)), keyEquivalent: "")
                    item.setIcons("eye.slash")
                    menu.addItem(item)
                }

                // Do we have uncached videos in here ?
                if !videos.filter({!$0.isAvailableOffline}).isEmpty {
                    menu.addItem(NSMenuItem.separator())
                    let item = NSMenuItem(title: "Cache missing videos", action: #selector(cacheMissingVideos(_:)), keyEquivalent: "")
                    item.setIcons("arrow.down.circle")
                    menu.addItem(item)
                }

                if !videos.filter({ PrefsVideos.vibrance.keys.contains($0.id) }).isEmpty {
                    let item = NSMenuItem(title: "Reset vibrance", action: #selector(resetVibrance(_:)), keyEquivalent: "")
                    item.setIcons("slider.horizontal.3")
                    menu.addItem(item)
                    hasFavs = true
                }

                return menu
            }
        }

        return nil
    }

    @objc func cacheMissingVideos(_ sender: Any) {
        if menuPath == "" {
            errorLog("Right click cache missing with no menu")
            return
        }

        Cache.ensureDownload {
            let videos = VideoList.instance.getVideosForPath(self.menuPath)

            for video in videos.filter({ !$0.isAvailableOffline }) {
                VideoManager.sharedInstance.queueDownload(video)
            }
        }
    }

    @objc func favoriteVideos(_ sender: Any) {
        if menuPath == "" {
            errorLog("Right click missing path")
            return
        }
        let videos = VideoList.instance.getVideosForPath(self.menuPath)

        for video in videos.filter({ !PrefsVideos.favorites.contains($0.id) }) {
            PrefsVideos.favorites.append(video.id)
        }
        windowController!.updateViewInPlace()
    }

    @objc func unfavoriteVideos(_ sender: Any) {
        if menuPath == "" {
            errorLog("Right click missing path")
            return
        }
        let videos = VideoList.instance.getVideosForPath(self.menuPath)

        for video in videos.filter({ PrefsVideos.favorites.contains($0.id) }) {
            PrefsVideos.favorites.remove(at: PrefsVideos.favorites.firstIndex(of: video.id)!)
        }
        windowController!.updateViewInPlace()
    }

    @objc func hideVideos(_ sender: Any) {
        if menuPath == "" {
            errorLog("Right click missing path")
            return
        }
        let videos = VideoList.instance.getVideosForPath(self.menuPath)

        for video in videos.filter({ !PrefsVideos.hidden.contains($0.id) }) {
            PrefsVideos.hidden.append(video.id)
        }

        // We need to reload our sidebar
        Sidebar.instance.refreshVideos()
        sidebarOutlineView.reloadData()
        sidebarOutlineView.expandItem(nil, expandChildren: true)
        sidebarOutlineView.selectRowIndexes([0], byExtendingSelection: false)
    }

    @objc func resetVibrance(_ sender: Any) {
        if menuPath == "" {
            errorLog("Right click missing path")
            return
        }
        let videos = VideoList.instance.getVideosForPath(self.menuPath)

        for video in videos.filter({ PrefsVideos.vibrance.keys.contains($0.id) }) {
            PrefsVideos.vibrance.removeValue(forKey: video.id)
        }

        windowController!.updateViewInPlace()
    }
}
