//
//  InfoCountdownView.swift
//  Aerial
//
//  Created by Guillaume Louel on 12/02/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoCountdownView: NSView {

    @IBOutlet var timeModePopup: NSPopUpButton!

    @IBOutlet var withSecondsCheckbox: NSButton!
    @IBOutlet var targetTimeDatePicker: NSDatePicker!
    @IBOutlet var limitToIntervalCheckbox: NSButton!
    @IBOutlet var limitIntervalDatePicker: NSDatePicker!

    // Init(ish)
    func setStates() {
        timeModePopup.selectItem(at: PrefsInfo.countdown.mode.rawValue)
        withSecondsCheckbox.state = PrefsInfo.countdown.showSeconds ? .on : .off

        targetTimeDatePicker.dateValue = PrefsInfo.countdown.targetDate

        updatePickerFormat()

        limitToIntervalCheckbox.state = PrefsInfo.countdown.enforceInterval ? .on : .off
        limitIntervalDatePicker.dateValue = PrefsInfo.countdown.triggerDate
    }

    func updatePickerFormat() {
        switch PrefsInfo.countdown.mode {
        case .preciseDate:
            targetTimeDatePicker.datePickerElements = [.yearMonthDay, .hourMinuteSecond]
            limitIntervalDatePicker.datePickerElements = [.yearMonthDay, .hourMinuteSecond]
        case .timeOfDay:
            targetTimeDatePicker.datePickerElements = [.hourMinuteSecond]
            limitIntervalDatePicker.datePickerElements = [.hourMinuteSecond]
            // TODO hide day
        }
    }

    // UI Actions
    @IBAction func timeModePopupChange(_ sender: NSPopUpButton) {
        PrefsInfo.countdown.mode = InfoCountdownMode(rawValue: sender.indexOfSelectedItem)!
        updatePickerFormat()
    }

    @IBAction func withSecondsCheckboxClick(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.countdown.showSeconds = onState
    }

    @IBAction func targetTimeDatePickerChange(_ sender: NSDatePicker) {
        PrefsInfo.countdown.targetDate = sender.dateValue
    }

    @IBAction func limitToIntervalClick(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.countdown.enforceInterval = onState
    }

    @IBAction func limitIntervalDatePickerChange(_ sender: NSDatePicker) {
        PrefsInfo.countdown.triggerDate = sender.dateValue
    }
}
