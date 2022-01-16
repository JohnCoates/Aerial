//
//  SidebarViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 15/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

enum SidebarMenus {
    case modern, videos, settings, infos
}

class SidebarViewController: NSViewController {

    @IBOutlet var sidebarOutlineView: SidebarOutlineView!

    // For the download indicator
    @IBOutlet var downloadIndicator: NSVisualEffectView!
    @IBOutlet var downloadIndicatorProgress: NSProgressIndicator!
    @IBOutlet var downloadIndicatorLabel: NSTextField!
    @IBOutlet var downloadCancelButton: NSButton!

    var windowController: PanelWindowController?

    // Always start with the videos panel selected
    var menuSelection: SidebarMenus = .modern

    @IBOutlet var closeButton: NSButton!

    var menuPath = ""   // eh...

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(OSX 10.16, *) {
            closeButton.isHighlighted = true
        } else {
            // For some reason we need this on 10.12/10.13, there's a bug that somehow inverts colors in the recent Big Sur SDK for those older OSes
            sidebarOutlineView.backgroundColor = .clear
            sidebarOutlineView.gridColor = .alternateSelectedControlColor
        }

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

        downloadIndicator.isHidden = true
        downloadIndicatorProgress.doubleValue = 0
    }

    override func viewDidAppear() {
        // When we are really there, we can look for the data
        // This will trigger the refresh of the VideosViewController
        VideoList.instance.addCallback {
            print("reload")
            self.reloadSidebar()
        }
    }

    private func updateSidebarMenu(_ menu: SidebarMenus) {
        if menu != menuSelection {
            windowController?.switchFrom(menuSelection, to: menu)

            // Make sure we mark the current one
            menuSelection = menu

            sidebarOutlineView.reloadData()
            sidebarOutlineView.expandItem(nil, expandChildren: true)
            sidebarOutlineView.selectRowIndexes([1], byExtendingSelection: false)
        }
    }

    @IBAction func closeButton(_ sender: Any) {
        // This seems needed for screensavers as our lifecycle is different
        // from a regular app and we may be kept in memory by System Preferences
        // and our settings won't get saved as they should be
        Preferences.sharedInstance.synchronize()

        windowController!.stopVideo()

        if !downloadIndicator.isHidden {
            // swiftlint:disable:next line_length
            if !Aerial.showAlert(question: "Downloads still in progress", text: "Your video downloads are still in progress. Are you sure you want to quit ? This will abandon your current downloads.", button1: "Quit and Abandon Downloads", button2: "Cancel") {
                return
            }
        }

        if Aerial.appMode {
            NSApplication.shared.terminate(nil)
        } else {
            if Aerial.underCompanion {
                windowController!.window?.close()
            } else {
                windowController!.window?.sheetParent?.endSheet(windowController!.window!)
            }
        }
    }

    // MARK: Download indicator
    // Update the status of the download bar at the bottom of the sidebar
    func updateDownloads(done: Int, total: Int, progress: Double) {
        if total == 0 {
            downloadIndicator.isHidden = true
            downloadIndicatorProgress.doubleValue = 0

            windowController!.updateViewInPlace()
            // Sidebar.instance.refreshVideos()
            /*
            sidebarOutlineView.reloadData()
            sidebarOutlineView.expandItem(nil, expandChildren: true)
            sidebarOutlineView.selectRowIndexes([1], byExtendingSelection: false)
            */
        } else if progress == 0 {
            downloadIndicator.isHidden = false
            downloadIndicatorProgress.doubleValue = Double(done)
            downloadIndicatorProgress.maxValue = Double(total)
            downloadIndicatorProgress.toolTip = "Downloading \(done) / \(total)"
            downloadIndicatorLabel.stringValue = "Downloading \(done) / \(total)"
        } else {
            downloadIndicator.isHidden = false
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

        return Sidebar.instance.modern.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let header = item as? Sidebar.Header {
            return header.entries[index]
        }

        return Sidebar.instance.modern[index]
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

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        if item is Sidebar.Header {
            return false
        }

        return true
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

    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return false
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
    // swiftlint:disable cyclomatic_complexity
    func outlineView(outlineView: NSOutlineView, menuForItem item: Any) -> NSMenu? {
        // Make sure we're right clicking a menu entry
        if let entry = item as? Sidebar.MenuEntry {
            if entry.path.starts(with: "videos:") {
                let idx = entry.path.firstIndex(of: ":")
                let path = String(entry.path[idx!...].dropFirst()) // Oh Swift...

                menuPath = path         // Store it for later use in selectors, it's ugly I know

                // Grab all the videos
                var videos: [AerialVideo]

                if let mode = VideoList.instance.modeFromPath(path) {
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

                // Add a unhide menu just for the hidden category
                if let mode = VideoList.instance.modeFromPath(path) {
                    if mode == .hidden {
                        let item = NSMenuItem(title: "Show videos", action: #selector(showVideos(_:)), keyEquivalent: "")
                        item.setIcons("eye")
                        menu.addItem(item)

                        return menu
                    }
                }

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

    @objc func showVideos(_ sender: Any) {
        if menuPath == "" {
            errorLog("Right click missing path")
            return
        }
        let videos = VideoList.instance.getVideosForPath(self.menuPath)

        for video in videos.filter({ PrefsVideos.hidden.contains($0.id) }) {
            PrefsVideos.hidden.remove(at: PrefsVideos.hidden.firstIndex(of: video.id)!)
        }

        // We need to reload our sidebar
        // Sidebar.instance.refreshVideos()
        sidebarOutlineView.reloadData()
        sidebarOutlineView.expandItem(nil, expandChildren: true)
        sidebarOutlineView.selectRowIndexes([1], byExtendingSelection: false)
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
        // Sidebar.instance.refreshVideos()
        sidebarOutlineView.reloadData()
        sidebarOutlineView.expandItem(nil, expandChildren: true)
        sidebarOutlineView.selectRowIndexes([1], byExtendingSelection: false)
    }

    func reloadSidebar() {
        // We need to reload our sidebar
        // Sidebar.instance.refreshVideos()
        print("reload sidebar")
        let set = sidebarOutlineView.selectedRowIndexes

        sidebarOutlineView.reloadData()
        sidebarOutlineView.expandItem(nil, expandChildren: true)

        if set.isEmpty {
            print("empty set")
            sidebarOutlineView.selectRowIndexes([1], byExtendingSelection: false)
        } else {
            print("re set ing")
            sidebarOutlineView.selectRowIndexes(set, byExtendingSelection: false)

        }
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
