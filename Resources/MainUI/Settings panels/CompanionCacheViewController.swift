//
//  CompanionCacheViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/07/2022.
//  Copyright © 2022 Guillaume Louel. All rights reserved.
//

import Cocoa

class CompanionCacheViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func openSystemPreferences(_ sender: Any) {
        if #available(macOS 13, *) {
            _ = Aerial.helper.shell(launchPath: "/usr/bin/open", arguments: ["x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension"])
        } else {
            _ = Aerial.helper.shell(launchPath: "/usr/bin/osascript", arguments: [
            "-e", "tell application \"System Preferences\"",
            "-e","set the current pane to pane id \"com.apple.preference.desktopscreeneffect\"",
            "-e","reveal anchor \"ScreenSaverPref\" of pane id \"com.apple.preference.desktopscreeneffect\"",
            "-e","activate",
            "-e","end tell"])

        }
    }
}
