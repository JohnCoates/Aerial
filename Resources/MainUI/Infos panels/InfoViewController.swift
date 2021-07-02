//
//  InfoViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoViewController: NSViewController {

    @IBOutlet var versionLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        versionLabel.stringValue = Aerial.version
    }

    @IBAction func donateButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://ko-fi.com/A0A32385Y")!
        workspace.open(url)
    }

    @IBAction func iconWebsiteButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://infernodesign.com")!
        workspace.open(url)
    }
}
