//
//  InfoDateView.swift
//  Aerial
//
//  Created by Guillaume Louel on 23/03/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoDateView: NSView {

    @IBOutlet var dateFormatPopup: NSPopUpButton!

    @IBOutlet var withYearCheckbox: NSButton!

    @IBOutlet var customDateFormatField: NSTextField!

    // Init(ish)
    func setStates() {
        dateFormatPopup.selectItem(at: PrefsInfo.date.format.rawValue)
        withYearCheckbox.state = PrefsInfo.date.withYear ? .on : .off
        withYearCheckbox.isHidden = (PrefsInfo.date.format == .custom)
        customDateFormatField.stringValue = PrefsInfo.customDateFormat
        customDateFormatField.isHidden = !(PrefsInfo.date.format == .custom)
    }

    @IBAction func dateFormatPopupChange(_ sender: NSPopUpButton) {
        PrefsInfo.date.format = InfoDate(rawValue: sender.indexOfSelectedItem)!

        withYearCheckbox.isHidden = (PrefsInfo.date.format == .custom)
        customDateFormatField.isHidden = !(PrefsInfo.date.format == .custom)
    }

    @IBAction func withYearCheckboxChange(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.date.withYear = onState
    }

    @IBAction func customDateFormatFieldChange(_ sender: NSTextField) {
        PrefsInfo.customDateFormat = sender.stringValue
    }
}
