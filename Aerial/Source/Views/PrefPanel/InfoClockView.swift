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
    @IBOutlet var clockFormat: NSPopUpButton!

    // Init(ish)
    func setStates() {
        secondsCheckbox.state = PrefsInfo.clock.showSeconds ? .on : .off
        hideAmPmCheckbox.state = PrefsInfo.clock.hideAmPm ? .on : .off
        clockFormat.selectItem(at: PrefsInfo.clock.clockFormat.rawValue)
        updateAmPmCheckbox()
    }

    @IBAction func secondsClick(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.clock.showSeconds = onState
    }

    @IBAction func hideAmPmCheckboxClick(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.clock.hideAmPm = onState
    }

    @IBAction func clockFormatChange(_ sender: NSPopUpButton) {
        PrefsInfo.clock.clockFormat = InfoClockFormat(rawValue: sender.indexOfSelectedItem)!
        updateAmPmCheckbox()
    }

    // Update the 12/24hr visibility
    func updateAmPmCheckbox() {
        switch PrefsInfo.clock.clockFormat {
        case .tdefault:
            hideAmPmCheckbox.isHidden = false  // meh
        case .t12hours:
            hideAmPmCheckbox.isHidden = false
        case .t24hours:
            hideAmPmCheckbox.isHidden = true
        }
    }

}
