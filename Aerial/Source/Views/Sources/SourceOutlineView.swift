//
//  SourceOutlineView.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/08/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

protocol SourceOutlineViewDelegate: NSOutlineViewDelegate {
    func outlineView(outlineView: NSOutlineView, menuForItem item: Any) -> NSMenu?
}

class SourceOutlineView: NSOutlineView {

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = self.convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)

        if let item = self.item(atRow: row) {
            return (self.delegate as! SourceOutlineViewDelegate).outlineView(outlineView: self, menuForItem: item)

        }

        return nil
    }

}
