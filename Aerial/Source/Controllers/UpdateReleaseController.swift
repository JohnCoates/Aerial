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
    var controller: PreferencesWindowController?

    @IBOutlet var updateWindow: NSWindow!

    @IBOutlet var noUpdateWindow: NSWindow!

    @IBOutlet var versionTextField: NSTextField!
    @IBOutlet var releaseNotesWKWebView: WKWebView!

    @IBOutlet var helpPopover: NSPopover!

    // MARK: - Update available
    func show(sender: NSButton, controller: PreferencesWindowController) {
        self.controller = controller

        if !updateWindow.isVisible {
            let autoUpdates = AutoUpdates.sharedInstance

            updateWindow.makeKeyAndOrderFront(nil)
            versionTextField.stringValue = autoUpdates.getVersion()

            releaseNotesWKWebView.configuration.preferences.javaScriptEnabled = false
            let html = "<html><head><style>body { font-family: -apple-system }</style></head><body>\(autoUpdates.getReleaseNotes())</body></html>"
            releaseNotesWKWebView.loadHTMLString(html, baseURL: nil)
        }
    }

    @IBAction func visitReleasePageClick(_ sender: NSButton) {
        let workspace = NSWorkspace.shared
        let autoUpdates = AutoUpdates.sharedInstance

        // We construct the URL this way... This is not great !
        let url = URL(string: "https://github.com/JohnCoates/Aerial/releases/tag/v\(autoUpdates.getVersion())")!
        workspace.open(url)

        updateWindow.close()
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
