//
//  CreditsViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 25/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class CreditsViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    @IBAction func translationButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/issues/792")!
        workspace.open(url)
    }

    @IBAction func websiteButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://aerialscreensaver.github.io")!
        workspace.open(url)
    }

    @IBAction func projectButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial")!
        workspace.open(url)
    }

    @IBAction func discordButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://discord.gg/TPuA5WG")!
        workspace.open(url)
    }
}
