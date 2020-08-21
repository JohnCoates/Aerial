//
//  SourcesViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class SourcesViewController: NSViewController {

    @IBOutlet var sourceOutlineView: SourceOutlineView!

    @IBOutlet var addOnlineWindow: NSWindow!
    @IBOutlet var addOnlineTextField: NSTextField!

    @IBOutlet var addLocalButton: NSButton!
    @IBOutlet var addOnlineButton: NSButton!
    @IBOutlet var getMoreVideosButton: NSButton!
    @IBOutlet var downloadAllVideosButton: NSButton!

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

        VideoManager.sharedInstance.addCallback { done, total in
            debugLog("vmsourcecallback \(done) \(total) ")
            if total == 0 {
                self.sourceOutlineView.reloadData()
                self.allSpinner.stopAnimation(self)
                self.allSpinner.isHidden = true
                self.downloadAllVideosButton.isEnabled = true
            }
        }

        VideoList.instance.addCallback {
            debugLog("sourcecallback")
            self.sourceOutlineView.reloadData()
        }
    }

    @IBAction func getMoreVideosClick(_ sender: NSButton) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/blob/master/Documentation/MoreVideos.md")!
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

    @IBAction func addOnlineClick(_ sender: Any) {
        addOnlineWindow.makeKeyAndOrderFront(self)
    }

    @IBAction func addOnlineDownload(_ sender: Any) {
        if let url = URL(string: addOnlineTextField.stringValue) {
            SourceList.fetchOnlineManifest(url: url)
            addOnlineWindow.close()
            addOnlineTextField.stringValue = ""
            sourceOutlineView.reloadData()
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
            }
        }
    }
}

extension SourcesViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {

    // item == nil means it's the "root" row of the outline view, which is not visible
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            /*if index == 0 {
                return "CommunityVideo"
            } else {*/
                return SourceList.list.filter({ !$0.name.starts(with: "tvOS")})[index]
            //}
        } else {
            return 0
        }
    }

    // Tell how many children each row has:
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return SourceList.list.filter({ !$0.name.starts(with: "tvOS")}).count
        } else {
            return 0
        }
    }

    // Tell whether the row is expandable.
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }

    // Set the content for each row/column element
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

        guard let columnIdentifier = tableColumn?.identifier.rawValue else {
            return nil
        }

        /*if let sourceHeader = item as? String {
            print(sourceHeader)
            return nil
        }*/

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
            cell.videoCount.stringValue = String(VideoList.instance.videos.filter({ $0.source.name == source.name }).count) + " videos"

            cell.licenseButton.isHidden = (source.license == "")
            cell.moreButton.isHidden = (source.more == "")

            return cell
        case "actionColumn":
            let cell = outlineView.makeView(withIdentifier:
                        NSUserInterfaceItemIdentifier(rawValue: columnIdentifier), owner: self) as! ActionCellView
            cell.source = source
            if source.type == .local {
                cell.actionButton.setIcons("folder")
                cell.actionButton.isEnabled = true
            } else {
                if VideoList.instance.videos.filter({ $0.source.name == source.name && !$0.isAvailableOffline }).isEmpty {
                    cell.actionButton.image = Aerial.getMiniSymbol("checkmark.circle.fill", tint: .systemGreen)
                    cell.actionButton.isEnabled = false
                } else {
                    cell.actionButton.setIcons("arrow.down.circle")
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

}

extension SourcesViewController: CheckboxCellViewDelegate {
    /// A delegate function where we can act on update from the checkbox in the "Is Selected" column
    func checkboxCellView(_ cell: CheckboxCellView, didChangeState state: NSControl.StateValue) {
        guard let item = cell.item as? Source else { return }

        // The row and its children are selected if state == .on
        item.setEnabled(state == .on)

        // This is more efficient than calling reload on every child since collapsed children are
        // not reloaded. They will be reloaded when they become visible
        sourceOutlineView.reloadItem(item, reloadChildren: true)
    }
}
