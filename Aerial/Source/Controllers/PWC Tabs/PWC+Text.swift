//
//  PWC+Text.swift
//  Aerial
//      This is the controller code for the Text Tab
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Cocoa

extension PreferencesWindowController {

/*
    // We have secondary panels for entering margins and extra message as a workaround
    // for < Mojave where a swift screensaver can't get focus which makes textfields
    // unusable

    // Extra message workaround
    @IBAction func openExtraMessagePanelClick(_ sender: Any) {
        if editExtraMessagePanel.isVisible {
            editExtraMessagePanel.close()
        } else {
            editExtraMessagePanel.makeKeyAndOrderFront(sender)
        }
    }

    @IBAction func extraTextFieldChange(_ sender: NSTextField) {
        debugLog("UI extraTextField \(sender.stringValue)")
        if sender == secondaryExtraMessageTextField {
            extraMessageTextField.stringValue = sender.stringValue
        }
        preferences.showMessageString = sender.stringValue
    }

    @IBAction func closeExtraMessagePanelClick(_ sender: Any) {
        // On close we apply what's in the textfield
        extraMessageTextField.stringValue = secondaryExtraMessageTextField.stringValue
        preferences.showMessageString = secondaryExtraMessageTextField.stringValue
        editExtraMessagePanel.close()
    }

    // Extra margins workaround
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
        preferences.marginX = Int(secondaryMarginHorizontalTextfield.stringValue)

        marginVerticalTextfield.stringValue = secondaryMarginVerticalTextfield.stringValue
        preferences.marginY = Int(secondaryMarginVerticalTextfield.stringValue)

        editMarginsPanel.close()
    }

    @IBAction func showDescriptionsClick(button: NSButton?) {
        let state = showDescriptionsCheckbox.state
        let onState = state == .on
        preferences.showDescriptions = onState
        debugLog("UI showDescriptions: \(onState)")

        changeTextState(to: onState)
    }

    func changeTextState(to: Bool) {
        // Location information
        //useCommunityCheckbox.isEnabled = to
        //localizeForTvOS12Checkbox.isEnabled = to
        descriptionModePopup.isEnabled = to
        fadeInOutTextModePopup.isEnabled = to
        fontPickerButton.isEnabled = to
        fontResetButton.isEnabled = to
        currentFontLabel.isEnabled = to
        changeCornerMargins.isEnabled = to
        if (to && changeCornerMargins.state == .on) || !to {
            marginHorizontalTextfield.isEnabled = to
            marginVerticalTextfield.isEnabled = to
            editExtraMessageButton.isEnabled = to
        }
        cornerContainer.isEnabled = to
        cornerTopLeft.isEnabled = to
        cornerTopRight.isEnabled = to
        cornerBottomLeft.isEnabled = to
        cornerBottomRight.isEnabled = to
        cornerRandom.isEnabled = to

        // Extra info, linked too
        showClockCheckbox.isEnabled = to
        if (to && showClockCheckbox.state == .on) || !to {
            withSecondsCheckbox.isEnabled = to
        }
        showExtraMessage.isEnabled = to
        if (to && showExtraMessage.state == .on) || !to {
            //extraMessageTextField.isEnabled = to
            //editExtraMessageButton.isEnabled = to
        }
        extraFontPickerButton.isEnabled = to
        extraFontResetButton.isEnabled = to
        extraMessageFontLabel.isEnabled = to
        extraCornerPopup.isEnabled = to
    }*/
/*


    @IBAction func extraCornerPopupChange(_ sender: NSPopUpButton) {
        debugLog("UI extraCorner: \(sender.indexOfSelectedItem)")
        preferences.extraCorner = sender.indexOfSelectedItem
        preferences.synchronize()
    }

*/
}

// MARK: - Font Panel Delegates
/*
extension PreferencesWindowController: NSFontChanging {
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        return [.size, .collection, .face]
    }

    func changeFont(_ sender: NSFontManager?) {
        // Set current font
        var oldFont = NSFont(name: "Helvetica Neue Medium", size: 28)

        if fontEditing == 0 {
            if let tryFont = NSFont(name: preferences.fontName!, size: CGFloat(preferences.fontSize!)) {
                oldFont = tryFont
            }
        } else {
            if let tryFont = NSFont(name: preferences.extraFontName!, size: CGFloat(preferences.extraFontSize!)) {
                oldFont = tryFont
            }
        }

        let newFont = sender?.convert(oldFont!)

        if fontEditing == 0 {
            preferences.fontName = newFont?.fontName
            preferences.fontSize = Double((newFont?.pointSize)!)

            // Update our label
            currentFontLabel.stringValue = preferences.fontName! + ", \(preferences.fontSize!) pt"
        } else {
            preferences.extraFontName = newFont?.fontName
            preferences.extraFontSize = Double((newFont?.pointSize)!)

            // Update our label
            extraMessageFontLabel.stringValue = preferences.extraFontName! + ", \(preferences.extraFontSize!) pt"
        }
        preferences.synchronize()
    }
}
*/
