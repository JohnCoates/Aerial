//
//  VideoHeaderView.swift
//  Aerial
//
//  Created by Guillaume Louel on 14/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import AppKit

class VideoHeaderView: NSView {

    @IBOutlet weak var sectionTitle: NSTextField!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // NSColor(calibratedWhite: 0.8, alpha: 0.8).set()
        // NSRectFillUsingOperation(dirtyRect, NSCompositingOperation.sourceOver)
    }
}
