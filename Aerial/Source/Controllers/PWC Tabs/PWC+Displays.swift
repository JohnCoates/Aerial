//
//  PWC+Displays.swift
//  Aerial
//      This is the controller code for the Displays Tab
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Cocoa

extension PreferencesWindowController {
    func setupDisplaysTab() {
        horizontalDisplayMarginTextfield.doubleValue = PrefsDisplays.horizontalMargin
        verticalDisplayMarginTextfield.doubleValue = PrefsDisplays.verticalMargin

        if PrefsDisplays.viewingMode == .spanned {
            displayMarginBox.isHidden = false
        } else {
            displayMarginBox.isHidden = true
        }
        if PrefsDisplays.displayMarginsAdvanced {
            displayMarginAdvancedMode.state = .on
            displayMarginAdvancedEdit.isEnabled = true
        } else {
            displayMarginAdvancedMode.state = .off
            displayMarginAdvancedEdit.isEnabled = false
        }

        // Displays Tab
        newDisplayModePopup.selectItem(at: PrefsDisplays.displayMode.rawValue)
        newViewingModePopup.selectItem(at: PrefsDisplays.viewingMode.rawValue)
        aspectModePopup.selectItem(at: PrefsDisplays.aspectMode.rawValue)

        if PrefsDisplays.displayMode == .selection {
            displayInstructionLabel.isHidden = false
        }
    }

    @IBAction func newDisplayModeClick(_ sender: NSPopUpButton) {
        debugLog("UI newDisplayModeClick: \(sender.indexOfSelectedItem)")
        PrefsDisplays.displayMode = DisplayMode(rawValue: sender.indexOfSelectedItem)!
        if PrefsDisplays.displayMode == .selection {
            displayInstructionLabel.isHidden = false
        } else {
            displayInstructionLabel.isHidden = true
        }
        displayView.needsDisplay = true
    }

    @IBAction func newViewingModeClick(_ sender: NSPopUpButton) {
        debugLog("UI newViewingModeClick: \(sender.indexOfSelectedItem)")
        PrefsDisplays.viewingMode = ViewingMode(rawValue: sender.indexOfSelectedItem)!
        let displayDetection = DisplayDetection.sharedInstance
        displayDetection.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true

        if PrefsDisplays.viewingMode == .spanned {
            displayMarginBox.isHidden = false
        } else {
            displayMarginBox.isHidden = true
        }
    }

    @IBAction func aspectModePopupClick(_ sender: NSPopUpButton) {
        debugLog("UI aspectModeClick: \(sender.indexOfSelectedItem)")
        PrefsDisplays.aspectMode = AspectMode(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func horizontalDisplayMarginChange(_ sender: NSTextField) {
        debugLog("UI horizontalDisplayMarginChange \(sender.stringValue)")
        PrefsDisplays.horizontalMargin = sender.doubleValue

        let displayDetection = DisplayDetection.sharedInstance
        displayDetection.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true
    }

    @IBAction func verticalDisplayMarginChange(_ sender: NSTextField) {
        debugLog("UI verticalDisplayMarginChange \(sender.stringValue)")
        PrefsDisplays.verticalMargin = sender.doubleValue

        let displayDetection = DisplayDetection.sharedInstance
        displayDetection.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true
    }

    // This is for managing the advanced mode for spanned margins
    @IBAction func displayMarginAdvancedModeChange(_ sender: NSButton) {
        let onState = sender.state == .on

        debugLog("UI displayMarginAdvancedModeClick: \(onState)")
        PrefsDisplays.displayMarginsAdvanced = onState
        if PrefsDisplays.displayMarginsAdvanced {
            displayMarginAdvancedEdit.isEnabled = true
        } else {
            displayMarginAdvancedEdit.isEnabled = false
        }
        displayView.needsDisplay = true
    }

    // Open close the panel
    @IBAction func displayMarginAdvancedEditClick(_ sender: Any) {
        if displayMarginAdvancedPanel.isVisible {
            displayMarginAdvancedPanel.close()
        } else {
            // Grab the JSON
            let displayDetection = DisplayDetection.sharedInstance
            displayMarginAdvancedTextfield.stringValue = displayDetection.getMarginsJSON()

            displayMarginAdvancedPanel.makeKeyAndOrderFront(sender)
        }
    }

    @IBAction func displayMarginAdvancedApplyClick(_ sender: Any) {
        // We save the JSON as String
        PrefsDisplays.advancedMargins = displayMarginAdvancedTextfield.stringValue
        // And redetect
        let displayDetection = DisplayDetection.sharedInstance
        displayDetection.detectDisplays()   // Force redetection to update our margin calculations in spanned mode

        displayView.needsDisplay = true
    }

    @IBAction func displayMarginAdvancedCloseClick(_ sender: Any) {
        // We save the JSON as String
        PrefsDisplays.advancedMargins = displayMarginAdvancedTextfield.stringValue
        // And redetect
        let displayDetection = DisplayDetection.sharedInstance
        displayDetection.detectDisplays()   // Force redetection to update our margin calculations in spanned mode

        displayView.needsDisplay = true
        displayMarginAdvancedPanel.close()
    }
}
