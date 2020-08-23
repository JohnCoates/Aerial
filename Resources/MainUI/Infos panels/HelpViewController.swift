//
//  HelpViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 25/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class HelpViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    @IBAction func faqButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://aerialscreensaver.github.io/faq.html")!
        workspace.open(url)
    }

    @IBAction func troubleshootButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://aerialscreensaver.github.io/troubleshooting.html")!
        workspace.open(url)
    }

    @IBAction func issuesButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/issues")!
        workspace.open(url)
    }

    @IBAction func visitDiscordClick(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://discord.gg/TPuA5WG")!
        workspace.open(url)
    }

}
