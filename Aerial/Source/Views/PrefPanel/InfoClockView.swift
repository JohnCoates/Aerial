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
    @IBOutlet var hideAmPmCheckbox: NSButton!

    // Init(ish)
    func setStates() {
        secondsCheckbox.state = PrefsInfo.clock.showSeconds ? .on : .off
        hideAmPmCheckbox.state = PrefsInfo.clock.hideAmPm ? .on : .off
    }

    @IBAction func secondsClick(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.clock.showSeconds = onState
    }

    @IBAction func hideAmPmCheckboxClick(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.clock.hideAmPm = onState
    }
}
