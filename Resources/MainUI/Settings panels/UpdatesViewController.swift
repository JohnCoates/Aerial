//
//  UpdatesViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class UpdatesViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func goToAerialUpdater(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://aerialscreensaver.github.io")!
        workspace.open(url)
    }

    @IBAction func goToExtendedInstructions(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://aerialscreensaver.github.io/installation.html")!
        workspace.open(url)
    }
}
