//
//  UpdateReleaseController.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/02/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AppKit
import WebKit

class UpdateReleaseController: NSWindowController {
    var controller: UpdatesViewController?

    @IBOutlet var updateWindow: NSWindow!

    @IBOutlet var noUpdateWindow: NSWindow!

    @IBOutlet var versionTextField: NSTextField!
    @IBOutlet var releaseNotesWKWebView: WKWebView!

    @IBOutlet var helpPopover: NSPopover!

    // MARK: - Update available
    func show(sender: NSButton, controller: UpdatesViewController) {
        self.controller = controller

    }

    @IBAction func visitReleasePageClick(_ sender: NSButton) {
    }

    @IBAction func helpButtonClick(_ sender: NSButton) {
        helpPopover.show(relativeTo: sender.preparedContentRect, of: sender, preferredEdge: .maxY)
    }

    @IBAction func closeClick(_ sender: NSButton) {
        updateWindow.close()
    }

    // MARK: - No update available
    func showNoUpdate() {
        if !noUpdateWindow.isVisible {
            noUpdateWindow.makeKeyAndOrderFront(nil)
        }
    }

    @IBAction func noUpdateCloseClick(_ sender: Any) {
        noUpdateWindow.close()
    }
}
