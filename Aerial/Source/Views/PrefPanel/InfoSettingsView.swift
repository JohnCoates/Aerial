//
//  InfoSettingsView.swift
//  Aerial
//
//  Created by Guillaume Louel on 14/02/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoSettingsView: NSView {
    @IBOutlet weak var fadeInOutTextModePopup: NSPopUpButton!

    @IBOutlet var changeCornerMargins: NSButton!
    @IBOutlet var marginHorizontalTextfield: NSTextField!
    @IBOutlet var marginVerticalTextfield: NSTextField!
    @IBOutlet var editMarginButton: NSButton!

    @IBOutlet var shadowRadiusTextField: NSTextField!
    @IBOutlet var shadowRadiusFormatter: NumberFormatter!

    func setStates() {
        //messageTextField.stringValue = PrefsInfo.message.message
        // Margins override
        if PrefsInfo.overrideMargins {
            changeCornerMargins.state = .on
            marginHorizontalTextfield.isEnabled = true
            marginVerticalTextfield.isEnabled = true
            editMarginButton.isEnabled = true
        }

        marginHorizontalTextfield.stringValue = String(PrefsInfo.marginX)
        marginVerticalTextfield.stringValue = String(PrefsInfo.marginY)

        fadeInOutTextModePopup.selectItem(at: PrefsInfo.fadeModeText.rawValue)

        shadowRadiusFormatter.allowsFloats = false
        shadowRadiusTextField.stringValue = String(PrefsInfo.shadowRadius)
    }

    // MARK: - Shadows
    @IBAction func shadowRadiusChange(_ sender: NSTextField) {
        PrefsInfo.shadowRadius = Int(sender.intValue)
    }

    // MARK: - Fades
    @IBAction func fadeInOutTextModePopupChange(_ sender: NSPopUpButton) {
        debugLog("UI fadeInOutTextMode: \(sender.indexOfSelectedItem)")
//        preferences.fadeModeText = sender.indexOfSelectedItem
//        preferences.synchronize()
        PrefsInfo.fadeModeText = FadeMode(rawValue: sender.indexOfSelectedItem)!

    }

    // MARK: - Margins
    @IBAction func changeMarginsToCornerClick(_ sender: NSButton) {
        let onState = sender.state == .on
        debugLog("UI changeMarginsToCorner: \(onState)")

        marginHorizontalTextfield.isEnabled = onState
        marginVerticalTextfield.isEnabled = onState
        PrefsInfo.overrideMargins = onState
//        preferences.overrideMargins = onState
    }

    @IBAction func marginXChange(_ sender: NSTextField) {
        PrefsInfo.marginX = Int(sender.stringValue) ?? 50
//        if sender == secondaryMarginHorizontalTextfield {
//            marginHorizontalTextfield.stringValue = sender.stringValue
//        }

        debugLog("UI marginXChange: \(sender.stringValue)")
    }

    @IBAction func marginYChange(_ sender: NSTextField) {
        PrefsInfo.marginY = Int(sender.stringValue) ?? 50
//        if sender == secondaryMarginVerticalTextfield {
//            marginVerticalTextfield.stringValue = sender.stringValue
//        }

        debugLog("UI marginYChange: \(sender.stringValue)")
    }
}
