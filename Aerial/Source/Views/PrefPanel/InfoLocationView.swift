//
//  InfoLocationView.swift
//  Aerial
//
//  Created by Guillaume Louel on 19/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoLocationView: NSView {

    @IBOutlet var showTimePopup: NSPopUpButton!

    // Init(ish)
    func setStates() {
        showTimePopup.selectItem(at: PrefsInfo.location.time.rawValue)
    }

    @IBAction func showTimeChange(_ sender: NSPopUpButton) {
        PrefsInfo.location.time = InfoTime(rawValue: sender.indexOfSelectedItem)!
    }

}
