//
//  PWC+About.swift
//  Aerial
//
//  Created by Guillaume Louel on 11/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import AppKit

extension PreferencesWindowController {
    func setupAboutTab() {
        if let version = Bundle(identifier: "com.johncoates.Aerial-Test")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            aboutVersionLabel.stringValue = "Version " + version
        } else if let version = Bundle(identifier: "com.JohnCoates.Aerial")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            aboutVersionLabel.stringValue = "Version " + version
        }
    }

    @IBAction func aboutTranslationButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/issues/792")!
        workspace.open(url)
    }

    @IBAction func aboutFAQButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/blob/master/Documentation/Troubleshooting.md")!
        workspace.open(url)
    }

    @IBAction func aboutGitHubIssuesButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/issues")!
        workspace.open(url)
    }

    @IBAction func aboutProjectPageButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial")!
        workspace.open(url)
    }

    @IBAction func aboutDonateButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://www.paypal.me/glouel/")!
        workspace.open(url)
    }
}
