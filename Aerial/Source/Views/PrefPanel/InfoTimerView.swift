//
//  InfoTimerView.swift
//  Aerial
//
//  Created by Guillaume Louel on 19/03/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoTimerView: NSView {
    @IBOutlet var durationTimePicker: NSDatePicker!
    @IBOutlet var withSecondsCheckbox: NSButton!
    @IBOutlet var disableWhenElapsedCheckbox: NSButton!
    @IBOutlet var replaceWithMessageCheckbox: NSButton!
    @IBOutlet var customMessageTextField: NSTextField!

    // Init(ish)
    func setStates() {
        durationTimePicker.dateValue = PrefsInfo.timer.duration
        durationTimePicker.locale = Locale(identifier: "fr_FR")
        withSecondsCheckbox.state = PrefsInfo.timer.showSeconds ? .on : .off
        disableWhenElapsedCheckbox.state = PrefsInfo.timer.disableWhenElapsed ? .on : .off
        replaceWithMessageCheckbox.state = PrefsInfo.timer.replaceWithMessage ? .on : .off
        customMessageTextField.stringValue = PrefsInfo.timer.customMessage
        customMessageTextField.isEnabled = PrefsInfo.timer.replaceWithMessage
    }

    @IBAction func durationChange(_ sender: NSDatePicker) {
        PrefsInfo.timer.duration = sender.dateValue
    }

    @IBAction func withSecondsClick(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.timer.showSeconds = onState
    }

    @IBAction func disableWhenElapsedClick(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.timer.disableWhenElapsed = onState
    }

    @IBAction func replaceWithMessageClick(_ sender: NSButton) {
        let onState = sender.state == .on
        PrefsInfo.timer.replaceWithMessage = onState
        customMessageTextField.isEnabled = onState
    }

    @IBAction func customMessageTextFieldChange(_ sender: NSTextField) {
        PrefsInfo.timer.customMessage = sender.stringValue
    }
}
