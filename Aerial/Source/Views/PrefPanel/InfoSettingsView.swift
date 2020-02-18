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

    // Shadows
    @IBOutlet var shadowRadiusTextField: NSTextField!
    @IBOutlet var shadowRadiusFormatter: NumberFormatter!
    @IBOutlet var shadowOpacitySlider: NSSlider!
    @IBOutlet var shadowOffsetXTextfield: NSTextField!
    @IBOutlet var shadowOffsetYTextfield: NSTextField!

    @IBOutlet var shadowOffsetXFormatter: NumberFormatter!
    @IBOutlet var shadowOffsetYFormatter: NumberFormatter!

    // High Sierra workarounds
    @IBOutlet var editMarginsPanel: NSPanel!

    @IBOutlet var editMarginButton: NSButton!
    @IBOutlet var secondaryMarginHorizontalTextfield: NSTextField!
    @IBOutlet var secondaryMarginVerticalTextfield: NSTextField!

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
        secondaryMarginHorizontalTextfield.stringValue = String(PrefsInfo.marginX)
        secondaryMarginVerticalTextfield.stringValue = String(PrefsInfo.marginY)

        fadeInOutTextModePopup.selectItem(at: PrefsInfo.fadeModeText.rawValue)

        shadowRadiusFormatter.allowsFloats = false
        shadowRadiusTextField.stringValue = String(PrefsInfo.shadowRadius)

//        shadowOffsetXFormatter.allowsFloats = true
//        shadowOffsetYFormatter.allowsFloats = true

        shadowOpacitySlider.doubleValue = Double(PrefsInfo.shadowOpacity * 100)
        shadowOffsetXTextfield.doubleValue = Double(PrefsInfo.shadowOffsetX)
        shadowOffsetYTextfield.doubleValue = Double(PrefsInfo.shadowOffsetY)

        // Workaround for textfield bug in High sierra and earlier
        if #available(OSX 10.14, *) {
            editMarginButton.isHidden = true
        } else {
            marginHorizontalTextfield.isEnabled = false
            marginVerticalTextfield.isEnabled = false
        }
    }

    // MARK: - Shadows
    @IBAction func shadowRadiusChange(_ sender: NSTextField) {
        PrefsInfo.shadowRadius = Int(sender.intValue)
    }

    @IBAction func shadowOpacityChange(_ sender: NSSlider) {
        PrefsInfo.shadowOpacity = Float(sender.intValue)/100
    }

    @IBAction func shadowOffsetXChange(_ sender: NSTextField) {
        PrefsInfo.shadowOffsetX = CGFloat(sender.doubleValue)
    }

    @IBAction func shadowOffsetYChange(_ sender: NSTextField) {
        PrefsInfo.shadowOffsetY = CGFloat(sender.doubleValue)
    }
    // MARK: - Fades
    @IBAction func fadeInOutTextModePopupChange(_ sender: NSPopUpButton) {
        debugLog("UI fadeInOutTextMode: \(sender.indexOfSelectedItem)")

        PrefsInfo.fadeModeText = FadeMode(rawValue: sender.indexOfSelectedItem)!

    }

    // MARK: - Margins
    @IBAction func changeMarginsToCornerClick(_ sender: NSButton) {
        let onState = sender.state == .on
        debugLog("UI changeMarginsToCorner: \(onState)")

        marginHorizontalTextfield.isEnabled = onState
        marginVerticalTextfield.isEnabled = onState
        PrefsInfo.overrideMargins = onState
    }

    @IBAction func marginXChange(_ sender: NSTextField) {
        PrefsInfo.marginX = Int(sender.stringValue) ?? 50
        if sender == secondaryMarginHorizontalTextfield {
            marginHorizontalTextfield.stringValue = sender.stringValue
        }

        debugLog("UI marginXChange: \(sender.stringValue)")
    }

    @IBAction func marginYChange(_ sender: NSTextField) {
        PrefsInfo.marginY = Int(sender.stringValue) ?? 50
        if sender == secondaryMarginVerticalTextfield {
            marginVerticalTextfield.stringValue = sender.stringValue
        }

        debugLog("UI marginYChange: \(sender.stringValue)")
    }

    // MARK: - High Sierra Workaround for TextFields
    @IBAction func openExtraMarginPanelClick(_ sender: Any) {
        if editMarginsPanel.isVisible {
            editMarginsPanel.close()
        } else {
            editMarginsPanel.makeKeyAndOrderFront(sender)
        }
    }

    @IBAction func closeExtraMarginPanelClick(_ sender: Any) {
        // On close we apply what's in the textfields
        marginHorizontalTextfield.stringValue = secondaryMarginHorizontalTextfield.stringValue
        PrefsInfo.marginX = Int(secondaryMarginHorizontalTextfield.stringValue) ?? 50

        marginVerticalTextfield.stringValue = secondaryMarginVerticalTextfield.stringValue
        PrefsInfo.marginY = Int(secondaryMarginVerticalTextfield.stringValue) ?? 50

        editMarginsPanel.close()
    }

}
