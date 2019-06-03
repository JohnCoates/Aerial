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
    @IBAction func newDisplayModeClick(_ sender: NSPopUpButton) {
        debugLog("UI newDisplayModeClick: \(sender.indexOfSelectedItem)")
        preferences.newDisplayMode = sender.indexOfSelectedItem
        if preferences.newDisplayMode == Preferences.NewDisplayMode.selection.rawValue {
            displayInstructionLabel.isHidden = false
        } else {
            displayInstructionLabel.isHidden = true
        }
        displayView.needsDisplay = true
    }

    @IBAction func newViewingModeClick(_ sender: NSPopUpButton) {
        debugLog("UI newViewingModeClick: \(sender.indexOfSelectedItem)")
        preferences.newViewingMode = sender.indexOfSelectedItem
        let displayDetection = DisplayDetection.sharedInstance
        displayDetection.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true

        if preferences.newViewingMode == Preferences.NewViewingMode.spanned.rawValue {
            displayMarginBox.isHidden = false
        } else {
            displayMarginBox.isHidden = true
        }
    }

    @IBAction func horizontalDisplayMarginChange(_ sender: NSTextField) {
        debugLog("UI horizontalDisplayMarginChange \(sender.stringValue)")
        preferences.horizontalMargin = sender.doubleValue

        let displayDetection = DisplayDetection.sharedInstance
        displayDetection.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true
    }

    @IBAction func verticalDisplayMarginChange(_ sender: NSTextField) {
        debugLog("UI verticalDisplayMarginChange \(sender.stringValue)")
        preferences.verticalMargin = sender.doubleValue

        let displayDetection = DisplayDetection.sharedInstance
        displayDetection.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true
    }
}
