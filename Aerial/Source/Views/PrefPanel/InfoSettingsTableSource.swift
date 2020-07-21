//
//  InfoSettingsTableSource.swift
//  Aerial
//
//  Created by Guillaume Louel on 14/02/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoSettingsTableSource: NSTableView, NSTableViewDataSource, NSTableViewDelegate {
    var controller: OverlaysViewController?

    func setController(_ controller: OverlaysViewController) {
        self.controller = controller
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 1
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cid = NSUserInterfaceItemIdentifier(rawValue: "InfoSettingsCellID")

        if let cell = tableView.makeView(withIdentifier: cid, owner: self) as? NSTableCellView {
            cell.textField?.stringValue = "Text settings"

            if #available(OSX 10.12.2, *) {
                cell.imageView?.image = NSImage(named: NSImage.touchBarTextBoxTemplateName)
            } else {
                // Fallback on earlier versions
                cell.imageView?.image = NSImage(named: NSImage.fontPanelName)
            }
            return cell
        }

        return nil
    }

    // This is where selection happens
    func tableViewSelectionDidChange(_ notification: Notification) {
        let tableView = notification.object as! NSTableView
        if tableView.selectedRow >= 0 {
            controller!.drawInfoSettingsPanel()
            controller!.infoTableView.deselectAll(controller!)
        }
    }
}
