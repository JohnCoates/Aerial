//
//  DisplaysViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class DisplaysViewController: NSViewController {
    @IBOutlet var displayView: DisplayView!
    @IBOutlet var displayInstructionLabel: NSTextField!

    @IBOutlet var displayPopup: NSPopUpButton!
    @IBOutlet var viewingModePopup: NSPopUpButton!
    @IBOutlet var aspectPopup: NSPopUpButton!

    @IBOutlet var marginBox: NSBox!
    @IBOutlet var horizontalMarginTextField: NSTextField!
    @IBOutlet var verticalMarginTextField: NSTextField!
    @IBOutlet var advancedMode: NSButton!
    @IBOutlet var advancedModeEdit: NSButton!

    // Advanced margin edit panel
    @IBOutlet var advancedEditPanel: NSPanel!
    @IBOutlet var advancedEditPanelTextfield: NSTextField!
    @IBOutlet var advancedEditApply: NSButton!
    @IBOutlet var advancedApplyClose: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // This is the label in the large display view in the top
        if PrefsDisplays.displayMode == .selection {
            displayInstructionLabel.isHidden = false
        }

        // Popups
        displayPopup.selectItem(at: PrefsDisplays.displayMode.rawValue)
        viewingModePopup.selectItem(at: PrefsDisplays.viewingMode.rawValue)
        aspectPopup.selectItem(at: PrefsDisplays.aspectMode.rawValue)

        // Margins
        if PrefsDisplays.viewingMode == .spanned {
            marginBox.isHidden = false
        } else {
            marginBox.isHidden = true
        }

        if PrefsDisplays.displayMarginsAdvanced {
            advancedMode.state = .on
            advancedModeEdit.isEnabled = true
        } else {
            advancedMode.state = .off
            advancedModeEdit.isEnabled = false
        }

        horizontalMarginTextField.doubleValue = PrefsDisplays.horizontalMargin
        verticalMarginTextField.doubleValue = PrefsDisplays.verticalMargin
    }

    @IBAction func displayPopupChange(_ sender: NSPopUpButton) {
        PrefsDisplays.displayMode = DisplayMode(rawValue: sender.indexOfSelectedItem)!
        if PrefsDisplays.displayMode == .selection {
            displayInstructionLabel.isHidden = false
        } else {
            displayInstructionLabel.isHidden = true
        }
        displayView.needsDisplay = true
    }

    @IBAction func viewingModeChange(_ sender: NSPopUpButton) {
        PrefsDisplays.viewingMode = ViewingMode(rawValue: sender.indexOfSelectedItem)!
        DisplayDetection.sharedInstance.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true

        if PrefsDisplays.viewingMode == .spanned {
            marginBox.isHidden = false
        } else {
            marginBox.isHidden = true
        }
    }

    @IBAction func aspectPopupChange(_ sender: NSPopUpButton) {
        PrefsDisplays.aspectMode = AspectMode(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func horizontalMarginChange(_ sender: NSTextField) {
        PrefsDisplays.horizontalMargin = sender.doubleValue

        DisplayDetection.sharedInstance.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true
    }

    @IBAction func verticalMarginChange(_ sender: NSTextField) {
        PrefsDisplays.verticalMargin = sender.doubleValue

        DisplayDetection.sharedInstance.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true
    }

    @IBAction func advancedModeClick(_ sender: NSButton) {
        PrefsDisplays.displayMarginsAdvanced = sender.state == .on
        if PrefsDisplays.displayMarginsAdvanced {
            advancedModeEdit.isEnabled = true
        } else {
            advancedModeEdit.isEnabled = false
        }
        displayView.needsDisplay = true
    }

    // Advanced margins panel
    @IBAction func advancedModeEditClick(_ sender: Any) {
        if advancedEditPanel.isVisible {
            advancedEditPanel.close()
        } else {
            // Grab the JSON
            advancedEditPanelTextfield.stringValue = DisplayDetection.sharedInstance.getMarginsJSON()

            advancedEditPanel.makeKeyAndOrderFront(sender)
        }
    }

    @IBAction func advancedModePanelApply(_ sender: Any) {
        // We save the JSON as String
        PrefsDisplays.advancedMargins = advancedEditPanelTextfield.stringValue

        // And redetect
        DisplayDetection.sharedInstance.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true
    }

    @IBAction func advancedModePanelApplyClose(_ sender: Any) {
        // We save the JSON as String
        PrefsDisplays.advancedMargins = advancedEditPanelTextfield.stringValue

        // And redetect
        DisplayDetection.sharedInstance.detectDisplays()   // Force redetection to update our margin calculations in spanned mode
        displayView.needsDisplay = true
        advancedEditPanel.close()
    }
}
