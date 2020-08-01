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

    @IBOutlet var sidebarOutlineView: NSOutlineView!

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
            self.sidebarOutlineView.expandItem(nil, expandChildren: true)
            self.sidebarOutlineView.selectRowIndexes([0], byExtendingSelection: false)
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
