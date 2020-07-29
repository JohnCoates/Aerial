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
        let url = URL(string: "https://github.com/glouel/AerialUpdater")!
        workspace.open(url)
    }

    @IBAction func goToExtendedInstructions(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/blob/master/Documentation/Installation.md")!
        workspace.open(url)
    }
}
