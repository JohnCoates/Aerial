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

    @IBOutlet var highQualityTextRendering: NSButton!
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

    func setStates() {
        // Margins override
        if PrefsInfo.overrideMargins {
            changeCornerMargins.state = .on
            marginHorizontalTextfield.isEnabled = true
            marginVerticalTextfield.isEnabled = true
        }

        highQualityTextRendering.state = PrefsInfo.highQualityTextRendering ? .on : .off

        marginHorizontalTextfield.stringValue = String(PrefsInfo.marginX)
        marginVerticalTextfield.stringValue = String(PrefsInfo.marginY)

        fadeInOutTextModePopup.selectItem(at: PrefsInfo.fadeModeText.rawValue)

        shadowRadiusFormatter.allowsFloats = false
        shadowRadiusTextField.stringValue = String(PrefsInfo.shadowRadius)

        shadowOpacitySlider.doubleValue = Double(PrefsInfo.shadowOpacity * 100)
        shadowOffsetXTextfield.doubleValue = Double(PrefsInfo.shadowOffsetX)
        shadowOffsetYTextfield.doubleValue = Double(PrefsInfo.shadowOffsetY)
    }

    // MARK: - Shadows
    @IBAction func highQualityTextRenderingChange(_ sender: NSButton) {
        PrefsInfo.highQualityTextRendering = sender.state == .on
    }

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
    }

    @IBAction func marginYChange(_ sender: NSTextField) {
        PrefsInfo.marginY = Int(sender.stringValue) ?? 50
    }
}
