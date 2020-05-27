//
//  InfoBatteryView.swift
//  Aerial
//
//  Created by Guillaume Louel on 27/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoBatteryView: NSView {
    @IBOutlet var hideWhenFull: NSButton!

    // Init(ish)
    func setStates() {
        hideWhenFull.state = PrefsInfo.battery.disableWhenFull ? .on : .off
    }

    @IBAction func hideWhenFullCheck(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.battery.disableWhenFull = onState
    }
}
