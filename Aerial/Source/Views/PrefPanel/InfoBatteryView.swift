//
//  InfoBatteryView.swift
//  Aerial
//
//  Created by Guillaume Louel on 27/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoBatteryView: NSView {

    @IBOutlet var modePopup: NSPopUpButton!

    // Init(ish)
    func setStates() {
        modePopup.selectItem(at: PrefsInfo.battery.mode.rawValue)
    }

    @IBAction func modePopupChange(_ sender: NSPopUpButton) {
        PrefsInfo.battery.mode = InfoIconText(rawValue: sender.indexOfSelectedItem)!
    }
}
