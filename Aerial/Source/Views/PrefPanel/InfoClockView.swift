//
//  InfoClockView.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoClockView: NSView {
    @IBOutlet var secondsCheckbox: NSButton!

    // Init(ish)
    func setStates() {
        secondsCheckbox.state = PrefsInfo.clock.showSeconds ? .on : .off
    }

    @IBAction func secondsClick(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.clock.showSeconds = onState

    }
}
