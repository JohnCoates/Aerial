//
//  InfoMessageView.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoMessageView: NSView {
    @IBOutlet var messageTextField: NSTextField!
    @IBOutlet var messageExtraButton: NSButton!

    @IBOutlet var editExtraMessagePanel: NSPanel!
    @IBOutlet var secondaryExtraMessageTextField: NSTextField!

    func setStates() {
        messageTextField.stringValue = PrefsInfo.message.message
        secondaryExtraMessageTextField.stringValue = PrefsInfo.message.message

        // Workaround for textfield bug in High sierra and earlier
        if #available(OSX 10.14, *) {
            messageExtraButton.isHidden = true
        } else {
            messageTextField.isEnabled = false
        }
    }

    @IBAction func messageChange(_ sender: NSTextField) {
        if sender == secondaryExtraMessageTextField {
            messageTextField.stringValue = sender.stringValue
        }
        PrefsInfo.message.message = sender.stringValue
    }

    // MARK: - High Sierra Workaround for TextFields
    @IBAction func openExtraMessagePanelClick(_ sender: Any) {
        if editExtraMessagePanel.isVisible {
            editExtraMessagePanel.close()
        } else {
            editExtraMessagePanel.makeKeyAndOrderFront(sender)
        }
    }

    @IBAction func closeExtraMessagePanelClick(_ sender: Any) {
        // On close we apply what's in the textfield
        messageTextField.stringValue = secondaryExtraMessageTextField.stringValue
        PrefsInfo.message.message = secondaryExtraMessageTextField.stringValue
        editExtraMessagePanel.close()
    }
}
