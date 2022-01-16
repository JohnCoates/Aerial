//
//  SourcesViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class SourcesViewController: NSViewController {
    var customVideoController: CustomVideoController?

    @IBOutlet var sourceOutlineView: SourceOutlineView!

    @IBOutlet var addOnlineWindow: NSWindow!
    @IBOutlet var addOnlineTextField: NSTextField!

    @IBOutlet var addLocalWindow: NSWindow!
    @IBOutlet var addLocalTextfield: NSTextField!

    @IBOutlet var addLocalButton: NSButton!
    @IBOutlet var addOnlineButton: NSButton!
    @IBOutlet var getMoreVideosButton: NSButton!
    @IBOutlet var downloadAllVideosButton: NSButton!

    @IBOutlet var refreshPeriodicity: NSPopUpButton!

    @IBOutlet var allSpinner: NSProgressIndicator!
    var selectedSource: Source?

    override func viewDidLoad() {
        super.viewDidLoad()
        allSpinner.isHidden = true
        sourceOutlineView.dataSource = self
        sourceOutlineView.delegate = self

        addLocalButton.setIcons("folder")
        addOnlineButton.setIcons("antenna.radiowaves.left.and.right")
        getMoreVideosButton.setIcons("cloud")
        downloadAllVideosButton.setIcons("arrow.down.circle")
        refreshPeriodicity.selectItem(at: PrefsVideos.intRefreshPeriodicity)

        VideoManager.sharedInstance.addCallback { done, total in
            debugLog("vmsourcecallback \(done) \(total) ")
            if total == 0 {
                self.sourceOutlineView.reloadData()
                self.allSpinner.stopAnimation(self)
                self.allSpinner.isHidden = true
                self.downloadAllVideosButton.isEnabled = true
                self.sourceOutlineView.expandItem(nil, expandChildren: true)
            }
        }

        VideoList.instance.addCallback {
            debugLog("sourcecallback")
            self.sourceOutlineView.reloadData()
            self.sourceOutlineView.expandItem(nil, expandChildren: true)
        }
    }

    @IBAction func refreshPeriodicityChange(_ sender: NSPopUpButton) {
        PrefsVideos.refreshPeriodicity = RefreshPeriodicity(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func getMoreVideosClick(_ sender: NSButton) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://aerialscreensaver.github.io/morevideos.html")!
        workspace.open(url)
        //
    }

    @IBAction func downloadAllClick(_ sender: NSButton) {
        Cache.ensureDownload {
            self.allSpinner.startAnimation(self)
            self.allSpinner.isHidden = false
            self.downloadAllVideosButton.isEnabled = false

            for video in VideoList.instance.videos.filter({ !$0.isAvailableOffline && !PrefsVideos.hidden.contains($0.id) }) {
                VideoManager.sharedInstance.queueDownload(video)
            }
        }
    }

    @IBAction func addLocalClick(_ sender: NSButton) {
        addLocalWindow.makeKeyAndOrderFront(self)
        /*
        // We also load our CustomVideos nib here
        let bundle = Bundle(for: CustomVideoController.self)

        customVideoController = CustomVideoController()
        var topLevelObjects: NSArray? = NSArray()
        if !bundle.loadNibNamed(NSNib.Name("CustomVideos"),
                            owner: customVideoController,
                            topLevelObjects: &topLevelObjects) {
            errorLog("Could not load nib for CustomVideos, please report")
        }
        DispatchQueue.main.async {
            self.customVideoController!.windowDidLoad()
            self.customVideoController!.show(sender: sender, controller: self)
            //self.customVideoController!.window!.makeKeyAndOrderFront(self)
        }*/
    }

    @IBAction func addLocalValidate(_ sender: Any) {
        let url = URL(fileURLWithPath: addLocalTextfield.stringValue)

        SourceList.processPathForVideos(url: url)
        addLocalWindow.close()
        addLocalTextfield.stringValue = ""
        sourceOutlineView.reloadData()
        sourceOutlineView.expandItem(nil, expandChildren: true)

    }

    @IBAction func findMoreVideos(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://aerialscreensaver.github.io/morevideos.html")!
        workspace.open(url)
    }

    @IBAction func addLocalCancel(_ sender: Any) {
        addLocalWindow.close()
        addLocalTextfield.stringValue = ""
    }

    @IBAction func addOnlineClick(_ sender: Any) {
        debugLog("Add online clicked")
        addOnlineWindow.makeKeyAndOrderFront(self)
    }

    @IBAction func addOnlineDownload(_ sender: Any) {
        debugLog("Add online validated")
        let trimmedString = addOnlineTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = URL(string: trimmedString) {
            debugLog("URL was parsed, fetching")
            SourceList.fetchOnlineManifest(url: url)
            addOnlineWindow.close()
            addOnlineTextField.stringValue = ""
            sourceOutlineView.reloadData()
            sourceOutlineView.expandItem(nil, expandChildren: true)
        } else {
            debugLog("URL was NOT parsed")
            Aerial.showErrorAlert(question: "Non valid URL",
                                  text: "Please type a valid URL to an Aerial source (see the more videos button), and make sure there are no trailing characters.")
        }
    }

    @IBAction func addOnlineCancel(_ sender: Any) {
        addOnlineWindow.close()
        addOnlineTextField.stringValue = ""
    }

}

extension SourcesViewController: SourceOutlineViewDelegate {

    func outlineView(outlineView: NSOutlineView, menuForItem item: Any) -> NSMenu? {
        if let source = item as? Source {
            let menu = NSMenu()

            selectedSource = source
            let mitem = NSMenuItem(title: "Remove source", action: #selector(removeSource(_:)), keyEquivalent: "")
            mitem.setIcons("eye.slash")
            menu.addItem(mitem)

            return menu
        }

        return nil
    }

    @objc func removeSource(_ sender: Any) {
        if let source = selectedSource {
            // swiftlint:disable:next line_length
            if Aerial.showAlert(question: "Remove a source", text: "This will remove all files and videos relating to this source. Are you sure you want to proceed? \n\nYou will need to restart System Preferences to complete the operation.", button1: "Remove Source", button2: "Cancel") {
                source.wipeFromDisk()
                sourceOutlineView.reloadData()
                sourceOutlineView.expandItem(nil, expandChildren: true)

            }
        }
    }
}

extension SourcesViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {

    // item == nil means it's the "root" row of the outline view, which is not visible
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return SourceList.categorizedSourceList()[index]
        } else {
            if let item = item as? SourceHeader {
                return item.sources[index]
            } else {
                return 0
            }
        }
    }

    // Tell how many children each row has:
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return SourceList.categorizedSourceList().count
        } else {
            if let item = item as? SourceHeader {
                return item.sources.count
            } else {
                return 1
            }
        }
    }

    // Tell whether the row is expandable.
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let _ = item as? SourceHeader else { return false }
        return true
    }

    // Set the content for each row/column element
    // swiftlint:disable cyclomatic_complexity
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

        guard let columnIdentifier = tableColumn?.identifier.rawValue else {
            return nil
        }

        if let sourceHeader = item as? SourceHeader {
            if columnIdentifier == "valueColumn" {
                let cell = outlineView.makeView(withIdentifier:
                                                    NSUserInterfaceItemIdentifier(rawValue: "valueColumnCell"), owner: self) as! DescriptionCellView
                cell.titleLabel.stringValue = sourceHeader.name
                cell.descriptionLabel.stringValue = ""
                cell.lastUpdatedLabel.stringValue = ""
                cell.imageScene1.isHidden = true
                cell.imageScene2.isHidden = true
                cell.imageScene3.isHidden = true
                cell.imageScene4.isHidden = true
                cell.imageScene5.isHidden = true
                cell.imageScene6.isHidden = true
                cell.videoCount.stringValue = ""
                cell.licenseButton.isHidden = true
                cell.moreButton.isHidden = true
                cell.imageFilm.isHidden = true
                cell.refreshNowButton.isHidden = true
                return cell
            } else {
                return nil
            }
        }

        let source = item as! Source

        switch columnIdentifier {
        case "isSelected":
            let cell = outlineView.makeView(withIdentifier:
                                                NSUserInterfaceItemIdentifier(rawValue: "isSelectedCell"), owner: self) as! CheckboxCellView
            cell.checkboxButton.state = source.isEnabled() ? .on : .off
            cell.delegate = self
            cell.item = item
            return cell

        case "valueColumn":
            let cell = outlineView.makeView(withIdentifier:
                                                NSUserInterfaceItemIdentifier(rawValue: "valueColumnCell"), owner: self) as! DescriptionCellView
            cell.item = source
            cell.titleLabel.stringValue = source.name
            cell.descriptionLabel.stringValue = source.description
            cell.lastUpdatedLabel.stringValue = "Last updated: " + source.lastUpdated()
            cell.imageScene1.isHidden = !source.scenes.contains(.nature)
            cell.imageScene2.isHidden = !source.scenes.contains(.city)
            cell.imageScene3.isHidden = !source.scenes.contains(.space)
            cell.imageScene4.isHidden = !source.scenes.contains(.sea)
            cell.imageScene5.isHidden = !source.scenes.contains(.beach)
            cell.imageScene6.isHidden = !source.scenes.contains(.countryside)

            if source.isEnabled() {
                cell.imageFilm.isHidden = false

                let totalCount = VideoList.instance.videos.filter({ $0.source.name == source.name }).count
                let downloadedCount = VideoList.instance.videos.filter({ $0.source.name == source.name && $0.isAvailableOffline }).count
                let size = source.diskUsage().rounded(toPlaces: 1)

                if totalCount == downloadedCount {
                    cell.videoCount.stringValue = "\(totalCount) videos"
                } else {
                    cell.videoCount.stringValue = "\(downloadedCount) of \(totalCount) videos downloaded"
                }

                if !source.isCachable && source.type != .local {
                    cell.videoCount.stringValue.append(", \(size) GB on disk")
                }
            } else {
                cell.imageFilm.isHidden = true

                cell.videoCount.stringValue = ""
            }

            cell.licenseButton.isHidden = (source.license == "")
            cell.moreButton.isHidden = (source.more == "")
            cell.refreshNowButton.isHidden = false

            return cell
        case "actionColumn":
            let cell = outlineView.makeView(withIdentifier:
                        NSUserInterfaceItemIdentifier(rawValue: columnIdentifier), owner: self) as! ActionCellView
            cell.source = source
            cell.spinner.stopAnimation(self)
            cell.spinner.isHidden = true

            if source.type == .local {
                cell.actionButton.setLargeIcon("folder")
                cell.actionButton.isEnabled = true
            } else {
                if VideoList.instance.videos.filter({ $0.source.name == source.name && !$0.isAvailableOffline }).isEmpty {
                    cell.actionButton.image = Aerial.getMiniSymbol("checkmark.circle.fill", tint: .systemGreen)
                    cell.actionButton.isEnabled = false
                } else {
                    cell.actionButton.setLargeIcon("arrow.down.circle")
                    cell.actionButton.isEnabled = true
                }
            }
            return cell

        default:
            let cell = outlineView.makeView(withIdentifier:
                        NSUserInterfaceItemIdentifier(rawValue: columnIdentifier), owner: self) as! NSTableCellView
            cell.textField?.stringValue = ""
            return cell
        }
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is SourceHeader {
            return 24
        } else {
            return 70
        }
    }

/*
    func outlineView(_ outlineView: NSOutlineView, dataCellFor tableColumn: NSTableColumn?, item: Any) -> NSCell? {
        print("dcf")
        if let item = item as? SourceHeader {
            return NSTextFieldCell(textCell: item.name)
        }

        return nil
    }*/
}

extension SourcesViewController: CheckboxCellViewDelegate {
    /// A delegate function where we can act on update from the checkbox in the "Is Selected" column
    func checkboxCellView(_ cell: CheckboxCellView, didChangeState state: NSControl.StateValue) {
        guard let item = cell.item as? Source else { return }

        // The row and its children are selected if state == .on
        item.setEnabled(state == .on)

        // This is more efficient than calling reload on every child since collapsed children are
        // not reloaded. They will be reloaded when they become visible
        DispatchQueue.main.async {
            self.sourceOutlineView.reloadItem(item, reloadChildren: true)
        }
    }
}
