//
//  PWC+LogPanel.swift
//  Aerial
//      Log Panel controller code
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Cocoa

// MARK: - Log TableView Delegates

extension PreferencesWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return errorMessages.count
    }
}

extension PreferencesWindowController: NSTableViewDelegate {
    fileprivate enum CellIdentifiers {
        static let DateCell = "DateCellID"
        static let MessageCell = "MessageCellID"
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""

        let item = errorMessages[row]

        if tableColumn == tableView.tableColumns[0] {
            text = dateFormatter.string(from: item.date)
            cellIdentifier = CellIdentifiers.DateCell
        } else if tableColumn == tableView.tableColumns[1] {
            switch item.level {
            case .info:
                image = NSImage(named: NSImage.infoName)
            case .warning:
                image = NSImage(named: NSImage.cautionName)
            case .error:
                image = NSImage(named: NSImage.stopProgressFreestandingTemplateName)
            default:
                image = NSImage(named: NSImage.actionTemplateName)
            }
            //image =
            text = item.message
            cellIdentifier = CellIdentifiers.MessageCell
        }

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image ?? nil
            return cell
        }

        return nil
    }
}
