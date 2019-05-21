//
//  CustomVideoController.swift
//  Aerial
//
//  Created by Guillaume Louel on 21/05/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import AppKit

class CustomVideoController: NSWindowController {
    @IBOutlet var mainPanel: NSWindow!
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        debugLog("cvcinit")
    }

    override init(window: NSWindow?) {
        super.init(window: window)
        //self.init(windowNibName: NSNib.Name("CustomVideos"))
        debugLog("cvcinit2")
    }

    func show() {
        if !mainPanel.isVisible {
            mainPanel.makeKeyAndOrderFront(self)
        }
    }

}
