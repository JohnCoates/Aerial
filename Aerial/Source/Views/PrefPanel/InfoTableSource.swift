//
//  InfoTableSource.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoTableSource: NSTableView, NSTableViewDataSource, NSTableViewDelegate {

    fileprivate enum CellIdentifiers {
        static let InfoSourceCellID = "InfoSourceCellID"
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        print("info n row")
        return 10
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        print("row height")
        return 50
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        print("table view")
        let cid = NSUserInterfaceItemIdentifier(rawValue: "InfoSourceCellID")

        if let cell = tableView.makeView(withIdentifier: cid, owner: self) as? NSTableCellView {
            cell.textField?.stringValue = "Hello there!"
            //cell.imageView?.image = image ?? nil

            return cell
        }

        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let tableView = notification.object as! NSTableView
        print("selrow \(tableView.selectedRow)")
    }
}
