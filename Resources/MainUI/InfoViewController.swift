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

        versionLabel.stringValue = Aerial.getVersionString()
    }

    @IBAction func donateButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://www.paypal.me/glouel/")!
        workspace.open(url)
    }

    @IBAction func translationButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/issues/792")!
        workspace.open(url)
    }

    @IBAction func faqButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/blob/master/Documentation/Troubleshooting.md")!
        workspace.open(url)
    }

    @IBAction func issuesButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/issues")!
        workspace.open(url)
    }

    @IBAction func projectButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial")!
        workspace.open(url)
    }
}
