//
//  WelcomeViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 29/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class WelcomeViewController: NSViewController {
    @IBOutlet var bigTitle: NSTextField!
    @IBOutlet var textBelow: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        if PrefsVideos.videoFormat != .v1080pH264 {
            bigTitle.stringValue = "Welcome back to Aerial"
            textBelow.stringValue = "We've changed a thing or two, so let's go over that!"
        }
    }

}
