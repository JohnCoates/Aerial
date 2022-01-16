//
//  CustomVideoController.swift
//  Aerial
//
//  Created by Guillaume Louel on 21/05/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import AppKit
import AVKit

class CustomVideoController: NSWindowController, NSWindowDelegate, NSDraggingDestination {
    @IBOutlet var mainPanel: NSWindow!

    // This is the panel workaround for Catalina
    @IBOutlet var addFolderCatalinaPanel: NSPanel!
    @IBOutlet var addFolderTextField: NSTextField!

    @IBOutlet var folderOutlineView: NSOutlineView!
    @IBOutlet var topPathControl: NSPathControl!

    @IBOutlet var folderView: NSView!
    @IBOutlet var fileView: NSView!
    @IBOutlet var onboardingLabel: NSTextField!

    @IBOutlet var folderShortNameTextField: NSTextField!
    @IBOutlet var timePopUpButton: NSPopUpButton!
    @IBOutlet var editPlayerView: AVPlayerView!
    @IBOutlet var videoNameTextField: NSTextField!

    @IBOutlet var poiTableView: NSTableView!
    @IBOutlet var addPoi: NSButton!
    @IBOutlet var removePoi: NSButton!

    @IBOutlet var addPoiPopover: NSPopover!
    @IBOutlet var timeTextField: NSTextField!
    @IBOutlet var timeTextStepper: NSStepper!
    @IBOutlet var timeTextFormatter: NumberFormatter!
    @IBOutlet var descriptionTextField: NSTextField!

    @IBOutlet var durationLabel: NSTextField!
    @IBOutlet var resolutionLabel: NSTextField!
    @IBOutlet var cvcMenu: NSMenu!

    @IBOutlet var menuRemoveFolderAndVideos: NSMenuItem!
    @IBOutlet var menuRemoveVideo: NSMenuItem!
    var currentFolder: Folder?
    var currentAsset: Asset?
    var currentAssetDuration: Int?

    var hasAwokenAlready = false
    var sw: NSWindow?
    var controller: SourcesViewController?

    // MARK: - Lifecycle
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        debugLog("cvcinit")
    }

    override init(window: NSWindow?) {
        super.init(window: window)
        self.sw = window
        debugLog("cvcinit2")
    }

    override func awakeFromNib() {
        if !hasAwokenAlready {
            debugLog("cvcawake")
            // self.menu = cvcMenu

            folderOutlineView.dataSource = self
            folderOutlineView.delegate = self
            folderOutlineView.menu = cvcMenu
            cvcMenu.delegate = self

            if #available(OSX 10.13, *) {
                folderOutlineView.registerForDraggedTypes([.fileURL, .URL])
            } else {
                // Fallback on earlier versions
            }

            poiTableView.dataSource = self
            poiTableView.delegate = self

            hasAwokenAlready = true
            editPlayerView.player = AVPlayer()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.windowWillClose(_:)),
                name: NSWindow.willCloseNotification,
                object: nil)
        }
    }

    // We will receive this notification for every panel/window so we need to ensure it's the correct one
    func windowWillClose(_ notification: Notification) {
        if let wobj = notification.object as? NSPanel {
            if wobj.title == "Manage Custom Videos" {
                debugLog("Closing cvc")
                // TODO 2.0
                /*
                let manifestInstance = ManifestLoader.instance
                manifestInstance.saveCustomVideos()

                manifestInstance.addCallback { manifestVideos in
                    if let contr = self.controller {
                        contr.loaded(manifestVideos: [])
                    }
                }
                manifestInstance.loadManifestsFromLoadedFiles() */
            }
        }
    }

    // This is the public function to make this visible
    func show(sender: NSButton, controller: SourcesViewController) {
        self.controller = controller
        if !mainPanel.isVisible {
            mainPanel.makeKeyAndOrderFront(sender)
            folderOutlineView.expandItem(nil, expandChildren: true)
            folderOutlineView.deselectAll(self)
            folderView.isHidden = true
            fileView.isHidden = true
            topPathControl.isHidden = true
        }
    }

    // MARK: - Edit Folders
    @IBAction func folderNameChange(_ sender: NSTextField) {
        if let folder = currentFolder {
            folder.label = sender.stringValue
            folderOutlineView.reloadData()
        }
    }

    // MARK: - Add a new folder of videos to parse
    @IBAction func addFolderButton(_ sender: NSButton) {
        debugLog("addFolder")
        if #available(OSX 10.15, *) {
            // On Catalina, we can't use NSOpenPanel right now
            addFolderTextField.stringValue = ""
            addFolderCatalinaPanel.makeKeyAndOrderFront(self)
        } else {
            let addFolderPanel = NSOpenPanel()
            addFolderPanel.allowsMultipleSelection = false
            addFolderPanel.canChooseDirectories = true
            addFolderPanel.canCreateDirectories = false
            addFolderPanel.canChooseFiles = false
            addFolderPanel.title = "Select a folder containing videos"

            addFolderPanel.begin { (response) in
                if response.rawValue == NSFileHandlingPanelOKButton {
                    self.processPathForVideos(url: addFolderPanel.url!)
                }
                addFolderPanel.close()
            }
        }
    }

    @IBAction func addFolderCatalinaConfirm(_ sender: Any) {
        let strFolder = addFolderTextField.stringValue

        if FileManager.default.fileExists(atPath: strFolder as String) {
            self.processPathForVideos(url: URL(fileURLWithPath: strFolder, isDirectory: true))
        }

        addFolderCatalinaPanel.close()
    }

    func processPathForVideos(url: URL) {
        debugLog("processing url for videos : \(url) ")
        let folderName = url.lastPathComponent
        // let manifestInstance = ManifestLoader.instance

        do {
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            var assets = [VideoAsset]()

            for lurl in urls {
                if lurl.path.lowercased().hasSuffix(".mp4") || lurl.path.lowercased().hasSuffix(".mov") {
                    assets.append(VideoAsset(accessibilityLabel: folderName,
                                             id: NSUUID().uuidString,
                                             title: lurl.lastPathComponent,
                                             timeOfDay: "day",
                                             scene: "",
                                             pointsOfInterest: [:],
                                             url4KHDR: "",
                                             url4KSDR: lurl.path,
                                             url1080H264: "",
                                             url1080HDR: "",
                                             url1080SDR: "",
                                             url: "",
                                             type: "nature"))
                }
            }

            // ...
            if SourceList.hasNamed(name: url.lastPathComponent) {
                Aerial.showInfoAlert(title: "Source name mismatch",
                                     text: "A source with this name already exists. Try renaming your folder and try again.")
            } else {
                debugLog("Creating source \(url.lastPathComponent)")

                // Generate and save the Source
                let source = Source(name: url.lastPathComponent,
                                    description: "Local files from \(url.path)",
                                    manifestUrl: "manifest.json",
                                    type: .local,
                                    scenes: [.nature],
                                    isCachable: false,
                                    license: "",
                                    more: "")

                SourceList.saveSource(source)

                // Then the entries
                let videoManifest = VideoManifest(assets: assets, initialAssetCount: 1, version: 1)

                SourceList.saveEntries(source: source, manifest: videoManifest)
            }
/*
            if let cvf = manifestInstance.customVideoFolders {
                // check if we have this folder already ?
                if !cvf.hasFolder(withUrl: url.path) && !assets.isEmpty {
                    cvf.folders.append(Folder(url: url.path, label: folderName, assets: assets))
                } else if !assets.isEmpty {
                    // We need to append in place those that don't exist yet
                    let folderIndex = cvf.getFolderIndex(withUrl: url.path)
                    for asset in assets {
                        if !cvf.folders[folderIndex].hasAsset(withUrl: asset.url) {
                            cvf.folders[folderIndex].assets.append(asset)
                        }
                    }
                }
            } else {
                // Create our initial CVF with the parsed folder
                manifestInstance.customVideoFolders = CustomVideoFolders(folders: [Folder(url: url.path, label: folderName, assets: assets)])
            }*/

            folderOutlineView.reloadData()
            folderOutlineView.expandItem(nil, expandChildren: true)
            folderOutlineView.deselectAll(self)

        } catch {
            errorLog("Could not process directory")
        }
    }

    // MARK: - Edit Files
    @IBAction func videoNameChange(_ sender: NSTextField) {
        if let asset = currentAsset {
            asset.accessibilityLabel = sender.stringValue
            folderOutlineView.reloadData()
        }
    }

    @IBAction func timePopUpChange(_ sender: NSPopUpButton) {
        if let asset = currentAsset {
            if sender.indexOfSelectedItem == 0 {
                asset.time = "day"
            } else {
                asset.time = "night"
            }
        }
    }

    // MARK: - Add/Remove POIs
    @IBAction func addPoiClick(_ sender: NSButton) {
        addPoiPopover.show(relativeTo: sender.preparedContentRect, of: sender, preferredEdge: .maxY)
    }

    @IBAction func removePoiClick(_ sender: NSButton) {
        if let asset = currentAsset {
            let keys = asset.pointsOfInterest.keys.map { Int($0)!}.sorted()
            asset.pointsOfInterest.removeValue(forKey: String(keys[poiTableView.selectedRow]))
            poiTableView.reloadData()
        }
    }

    @IBAction func addPoiValidate(_ sender: NSButton) {
        if let asset = currentAsset {
            if timeTextField.stringValue != "" && descriptionTextField.stringValue != "" {
                if asset.pointsOfInterest[timeTextField.stringValue] == nil {
                    asset.pointsOfInterest[timeTextField.stringValue] = descriptionTextField.stringValue

                    // We also reset the popup so it's clean for next poi
                    timeTextField.stringValue = ""
                    descriptionTextField.stringValue = ""

                    poiTableView.reloadData()
                    addPoiPopover.close()
                }
            }
        }
    }

    @IBAction func timeStepperChange(_ sender: NSStepper) {
        if let player = editPlayerView.player {
            player.seek(to: CMTime(seconds: Double(sender.intValue), preferredTimescale: 1))
        }
    }

    @IBAction func timeTextChange(_ sender: NSTextField) {
        if let player = editPlayerView.player {
            player.seek(to: CMTime(seconds: Double(sender.intValue), preferredTimescale: 1))
        }
    }

    @IBAction func tableViewTimeField(_ sender: NSTextField) {
        if let asset = currentAsset {
            if poiTableView.selectedRow != -1 {
                let keys = asset.pointsOfInterest.keys.map { Int($0)!}.sorted()
                asset.pointsOfInterest.switchKey(fromKey: String(keys[poiTableView.selectedRow]), toKey: sender.stringValue)
            }
        }
    }

    @IBAction func tableViewDescField(_ sender: NSTextField) {
        if let asset = currentAsset {
            if poiTableView.selectedRow != -1 {
                let keys = asset.pointsOfInterest.keys.map { Int($0)!}.sorted()
                asset.pointsOfInterest[String(keys[poiTableView.selectedRow])] = sender.stringValue
            }
        }
    }

    // MARK: - Context menu
    @IBAction func menuRemoveFolderAndVideoClick(_ sender: NSMenuItem) {
        if let folder = sender.representedObject as? Folder {
            let manifestInstance = ManifestLoader.instance

            if let cvf = manifestInstance.customVideoFolders {
                cvf.folders.remove(at: cvf.getFolderIndex(withUrl: folder.url))
            }
        }
        folderOutlineView.reloadData()
    }

    @IBAction func menuRemoveVideoClick(_ sender: NSMenuItem) {
        if let asset = sender.representedObject as? Asset {
            let manifestInstance = ManifestLoader.instance

            if let cvf = manifestInstance.customVideoFolders {
                for fld in cvf.folders {
                    let index = fld.getAssetIndex(withUrl: asset.url)
                    if index > -1 {
                        fld.assets.remove(at: index)
                    }
                }
            }
        }
        folderOutlineView.reloadData()
    }
}

// MARK: - Data source for side bar
extension CustomVideoController: NSOutlineViewDataSource {
    // Find and return the child of an item. If item == nil, we need to return a child of the
    // root node otherwise we find and return the child of the parent node indicated by 'item'
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let manifestInstance = ManifestLoader.instance

        if let source = item as? Source {
            return VideoList.instance.videos.filter({ $0.source.name == source.name })[index]
        }

        // Return a source
        return SourceList.foundSources.filter({ $0.type == .local })[index]
    }

    // Tell the view controller whether an item can be expanded (i.e. it has children) or not
    // (i.e. it doesn't)
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        // A folder may have childs if it's not empty
        if let folder = item as? Folder {
            return !folder.assets.isEmpty
        }

        // But not assets
        return false
    }

    // Tell the view how many children an item has
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        let manifestInstance = ManifestLoader.instance

        // A folder may have childs
        if let source = item as? Source {
            return VideoList.instance.videos.filter({ $0.source.name == source.name }).count
        }

        return SourceList.foundSources.filter({ $0.type == .local }).count

    }
}

// MARK: - Delegate for side bar

extension CustomVideoController: NSOutlineViewDelegate {
    // Add text to the view. 'item' will either be a Creature object or a string. If it's the former we just
    // use the 'type' attribute otherwise we downcast it to a string and use that instead.
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var text = ""

        if let source = item as? Source {
            text = source.name
        } else if let video = item as? AerialVideo {
            text = video.name
        }

        // Create our table cell -- note the reference to 'creatureCell' that we set when configuring the table cell
        let tableCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "folderCell"), owner: nil) as! NSTableCellView
        tableCell.textField!.stringValue = text
        return tableCell
    }

    // We update our view here when an item is selected
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        debugLog("selected \(item)")

        if let source = item as? Source {
            topPathControl.isHidden = false
            folderView.isHidden = false
            fileView.isHidden = true
            onboardingLabel.isHidden = true

            topPathControl.url = URL(fileURLWithPath: source.manifestUrl)
            folderShortNameTextField.stringValue = source.description
            currentAsset = nil
            currentFolder = nil // folder
        } else if let file = item as? Asset {
            topPathControl.isHidden = false
            folderView.isHidden = true
            fileView.isHidden = false
            onboardingLabel.isHidden = true

            topPathControl.url = URL(fileURLWithPath: file.url)
            videoNameTextField.stringValue = file.accessibilityLabel
            if file.time == "day" {
                timePopUpButton.selectItem(at: 0)
            } else {
                timePopUpButton.selectItem(at: 1)
            }
            currentFolder = nil
            currentAsset = file     // We use this later to populate the table view
            removePoi.isEnabled = false

            if let player = editPlayerView.player {
                let localitem = AVPlayerItem(url: URL(fileURLWithPath: file.url))
                currentAssetDuration = Int(localitem.asset.duration.convertScale(1, method: .default).value)
                let currentResolution = getResolution(asset: localitem.asset)
                let crString = String(Int(currentResolution.width)) + "x" + String(Int(currentResolution.height))

                timeTextStepper.minValue = 0
                timeTextStepper.maxValue = Double(currentAssetDuration!)
                timeTextFormatter.minimum = 0
                timeTextFormatter.maximum = NSNumber(value: currentAssetDuration!)

                durationLabel.stringValue = String(currentAssetDuration!) + " seconds"
                resolutionLabel.stringValue = crString

                player.replaceCurrentItem(with: localitem)
            }

            poiTableView.reloadData()
        } else {
            topPathControl.isHidden = true
            folderView.isHidden = true
            fileView.isHidden = true
            onboardingLabel.isHidden = false
        }

        return true
    }

    func getResolution(asset: AVAsset) -> CGSize {
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return CGSize.zero }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        return NSDragOperation.copy
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {

        if let items = info.draggingPasteboard.pasteboardItems {
            for item in items {
                if #available(OSX 10.13, *) {
                    if let str = item.string(forType: .fileURL) {
                        let surl = URL(fileURLWithPath: str).standardized
                        debugLog("received drop \(surl)")
                        if surl.isDirectory {
                            debugLog("processing dir")
                            self.processPathForVideos(url: surl)
                        }
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
        }
        return true
    }
}

// MARK: - Extension for poi table view
extension CustomVideoController: NSTableViewDataSource, NSTableViewDelegate {
    // currentAsset contains the selected video asset

    func numberOfRows(in tableView: NSTableView) -> Int {
        if let asset = currentAsset {
            return asset.pointsOfInterest.count
        } else {
            return 0
        }
    }

    // This is where we populate the tableview
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let asset = currentAsset {
            var text: String
            if tableColumn!.identifier.rawValue == "timeColumn" {
                let keys = asset.pointsOfInterest.keys.map { Int($0)!}.sorted()
                text = String(keys[row])
            } else {
                let keys = asset.pointsOfInterest.keys.map { Int($0)!}.sorted()
                text = asset.pointsOfInterest[String(keys[row])]!
            }

            if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView {
                cell.textField?.stringValue = text
                cell.imageView?.image = nil
                return cell
            }
        }

        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if let asset = currentAsset {
            if poiTableView.selectedRow >= 0 {
                removePoi.isEnabled = true

                let keys = asset.pointsOfInterest.keys.map { Int($0)!}.sorted()
                if let player = editPlayerView.player {
                    player.seek(to: CMTime(seconds: Double(keys[poiTableView.selectedRow]), preferredTimescale: 1))
                }
            } else {
                removePoi.isEnabled = false
            }
        }
    }

}

extension Dictionary {
    mutating func switchKey(fromKey: Key, toKey: Key) {
        if let entry = removeValue(forKey: fromKey) {
            self[toKey] = entry
        }
    }
}

extension URL {
    /*var isDirectory: Bool? {
        do {
            let values = try self.resourceValues(
                forKeys: Set([URLResourceKey.isDirectoryKey])
            )
            return values.isDirectory
        } catch { return nil }
    }*/

    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    var subDirectories: [URL] {
        guard isDirectory else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: self,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]).filter(\.isDirectory)) ?? []
    }
}

extension CustomVideoController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let row = folderOutlineView.clickedRow
        guard row != -1 else { return }
        let rowItem = folderOutlineView.item(atRow: row)

        if (rowItem as? Folder) != nil {
            menuRemoveVideo.isHidden = true
            menuRemoveFolderAndVideos.isHidden = false
        } else if (rowItem as? Asset) != nil {
            menuRemoveVideo.isHidden = false
            menuRemoveFolderAndVideos.isHidden = true
        }

        // Mark the clicked item here
        for item in menu.items {
            item.representedObject = rowItem
        }
    }
}
