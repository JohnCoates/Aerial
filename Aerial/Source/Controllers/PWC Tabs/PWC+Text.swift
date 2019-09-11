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
    // swiftlint:disable:next cyclomatic_complexity
    func setupTextTab() {
        self.fontManager.target = self
        latitudeFormatter.maximumSignificantDigits = 10
        longitudeFormatter.maximumSignificantDigits = 10
        extraLatitudeFormatter.maximumSignificantDigits = 10
        extraLongitudeFormatter.maximumSignificantDigits = 10

        // Fonts for descriptions and extra (clock/msg)
        currentFontLabel.stringValue = preferences.fontName! + ", \(preferences.fontSize!) pt"
        extraMessageFontLabel.stringValue = preferences.extraFontName! + ", \(preferences.extraFontSize!) pt"

        // Extra message
        extraMessageTextField.stringValue = preferences.showMessageString!
        secondaryExtraMessageTextField.stringValue = preferences.showMessageString!

        // Grab preferred language as proper string
        currentLocaleLabel.stringValue = getPreferredLanguage()

        // Should we override the community language ?
        let poisp = PoiStringProvider.sharedInstance
        ciOverrideLanguagePopup.selectItem(at: poisp.getLanguagePosition())

        if #available(OSX 10.12, *) {
        } else {
            showClockCheckbox.isEnabled = false
        }

        // Text panel
        if preferences.showClock {
            showClockCheckbox.state = .on
            withSecondsCheckbox.isEnabled = true
        }
        if preferences.withSeconds {
            withSecondsCheckbox.state = .on
        }
        if preferences.showMessage {
            showExtraMessage.state = .on
            editExtraMessageButton.isEnabled = true
            extraMessageTextField.isEnabled = true
        }
        if preferences.showDescriptions {
            showDescriptionsCheckbox.state = .on
            changeTextState(to: true)
        } else {
            changeTextState(to: false)
        }
        if preferences.overrideMargins {
            changeCornerMargins.state = .on
            marginHorizontalTextfield.isEnabled = true
            marginVerticalTextfield.isEnabled = true
            editMarginButton.isEnabled = true
        }

        marginHorizontalTextfield.stringValue = String(preferences.marginX!)
        marginVerticalTextfield.stringValue = String(preferences.marginY!)
        secondaryMarginHorizontalTextfield.stringValue = String(preferences.marginX!)
        secondaryMarginVerticalTextfield.stringValue = String(preferences.marginY!)

        // Handle the corner radios
        switch preferences.descriptionCorner {
        case Preferences.DescriptionCorner.topLeft.rawValue:
            cornerTopLeft.state = .on
        case Preferences.DescriptionCorner.topRight.rawValue:
            cornerTopRight.state = .on
        case Preferences.DescriptionCorner.bottomLeft.rawValue:
            cornerBottomLeft.state = .on
        case Preferences.DescriptionCorner.bottomRight.rawValue:
            cornerBottomRight.state = .on
        default:
            cornerRandom.state = .on
        }

        descriptionModePopup.selectItem(at: preferences.showDescriptionsMode!)
        fadeInOutTextModePopup.selectItem(at: preferences.fadeModeText!)
        extraCornerPopup.selectItem(at: preferences.extraCorner!)
    }

    func getPreferredLanguage() -> String {
        let printOutputLocale: NSLocale = NSLocale(localeIdentifier: Locale.preferredLanguages[0])
        if let deviceLanguageName: String = printOutputLocale.displayName(forKey: .identifier, value: Locale.preferredLanguages[0]) {
            if #available(OSX 10.12, *) {
                return "Preferred language: \(deviceLanguageName) [\(printOutputLocale.languageCode)]"
            } else {
                return "Preferred language: \(deviceLanguageName)"
            }
        } else {
            return ""
        }
    }

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
            extraMessageTextField.isEnabled = to
            editExtraMessageButton.isEnabled = to
        }
        extraFontPickerButton.isEnabled = to
        extraFontResetButton.isEnabled = to
        extraMessageFontLabel.isEnabled = to
        extraCornerPopup.isEnabled = to
    }

    @IBAction func communityLanguagePopupChange(_ sender: NSPopUpButton) {
        debugLog("UI communityLanguagePopupChange: \(sender.indexOfSelectedItem)")
        let poisp = PoiStringProvider.sharedInstance
        preferences.ciOverrideLanguage = poisp.getLanguageStringFromPosition(pos: sender.indexOfSelectedItem)
    }

    @IBAction func descriptionModePopupChange(_ sender: NSPopUpButton) {
        debugLog("UI descriptionMode: \(sender.indexOfSelectedItem)")
        preferences.showDescriptionsMode = sender.indexOfSelectedItem
        preferences.synchronize()
    }

    @IBAction func fontPickerClick(_ sender: NSButton?) {
        // Make a panel
        let fp = self.fontManager.fontPanel(true)

        // Set current font
        if let font = NSFont(name: preferences.fontName!, size: CGFloat(preferences.fontSize!)) {
            fp?.setPanelFont(font, isMultiple: false)

        } else {
            fp?.setPanelFont(NSFont(name: "Helvetica Neue Medium", size: 28)!, isMultiple: false)
        }

        // push the panel but mark which one we are editing
        fontEditing = 0
        fp?.makeKeyAndOrderFront(sender)
    }

    @IBAction func fontResetClick(_ sender: NSButton?) {
        preferences.fontName = "Helvetica Neue Medium"
        preferences.fontSize = 28

        // Update our label
        currentFontLabel.stringValue = preferences.fontName! + ", \(preferences.fontSize!) pt"
    }

    @IBAction func extraFontPickerClick(_ sender: NSButton?) {
        // Make a panel
        let fp = self.fontManager.fontPanel(true)

        // Set current font
        if let font = NSFont(name: preferences.extraFontName!, size: CGFloat(preferences.extraFontSize!)) {
            fp?.setPanelFont(font, isMultiple: false)

        } else {
            fp?.setPanelFont(NSFont(name: "Helvetica Neue Medium", size: 28)!, isMultiple: false)
        }

        // push the panel but mark which one we are editing
        fontEditing = 1
        fp?.makeKeyAndOrderFront(sender)
    }

    @IBAction func extraFontResetClick(_ sender: NSButton?) {
        preferences.extraFontName = "Helvetica Neue Medium"
        preferences.extraFontSize = 28

        // Update our label
        extraMessageFontLabel.stringValue = preferences.extraFontName! + ", \(preferences.extraFontSize!) pt"
    }

    @IBAction func descriptionCornerChange(_ sender: NSButton?) {
        switch sender {
        case cornerTopLeft:
            preferences.descriptionCorner = Preferences.DescriptionCorner.topLeft.rawValue
        case cornerTopRight:
            preferences.descriptionCorner = Preferences.DescriptionCorner.topRight.rawValue
        case cornerBottomLeft:
            preferences.descriptionCorner = Preferences.DescriptionCorner.bottomLeft.rawValue
        case cornerBottomRight:
            preferences.descriptionCorner = Preferences.DescriptionCorner.bottomRight.rawValue
        case cornerRandom:
            preferences.descriptionCorner = Preferences.DescriptionCorner.random.rawValue
        default:
            ()
        }
    }

    @IBAction func showClockClick(_ sender: NSButton) {
        let onState = sender.state == .on
        preferences.showClock = onState
        withSecondsCheckbox.isEnabled = onState
        debugLog("UI showClock: \(onState)")
    }

    @IBAction func withSecondsClick(_ sender: NSButton) {
        let onState = sender.state == .on
        preferences.withSeconds = onState
        debugLog("UI withSeconds: \(onState)")
    }

    @IBAction func showExtraMessageClick(_ sender: NSButton) {
        let onState = sender.state == .on
        // We also need to enable/disable our message field
        extraMessageTextField.isEnabled = onState
        editExtraMessageButton.isEnabled = onState
        preferences.showMessage = onState
        debugLog("UI showExtraMessage: \(onState)")
    }

    @IBAction func fadeInOutTextModePopupChange(_ sender: NSPopUpButton) {
        debugLog("UI fadeInOutTextMode: \(sender.indexOfSelectedItem)")
        preferences.fadeModeText = sender.indexOfSelectedItem
        preferences.synchronize()
    }

    @IBAction func extraCornerPopupChange(_ sender: NSPopUpButton) {
        debugLog("UI extraCorner: \(sender.indexOfSelectedItem)")
        preferences.extraCorner = sender.indexOfSelectedItem
        preferences.synchronize()
    }

    @IBAction func changeMarginsToCornerClick(_ sender: NSButton) {
        let onState = sender.state == .on
        debugLog("UI changeMarginsToCorner: \(onState)")

        marginHorizontalTextfield.isEnabled = onState
        marginVerticalTextfield.isEnabled = onState
        preferences.overrideMargins = onState
        editExtraMessageButton.isEnabled = onState
    }

    @IBAction func marginXChange(_ sender: NSTextField) {
        preferences.marginX = Int(sender.stringValue)
        if sender == secondaryMarginHorizontalTextfield {
            marginHorizontalTextfield.stringValue = sender.stringValue
        }

        debugLog("UI marginXChange: \(sender.stringValue)")
    }

    @IBAction func marginYChange(_ sender: NSTextField) {
        preferences.marginY = Int(sender.stringValue)
        if sender == secondaryMarginVerticalTextfield {
            marginVerticalTextfield.stringValue = sender.stringValue
        }

        debugLog("UI marginYChange: \(sender.stringValue)")
    }
}

// MARK: - Font Panel Delegates

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
