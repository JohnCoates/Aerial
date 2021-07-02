//
//  InfoMessageView.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoMessageView: NSView, NSTextViewDelegate {
    @IBOutlet var messageType: NSPopUpButton!

    // Basic text view
    @IBOutlet var messageTextView: NSTextView!

    // Shell script view
    @IBOutlet weak var shellScript: NSTextField!
    @IBOutlet weak var shellScriptTest: NSButton!

    @IBOutlet weak var shellRefreshPeriodicity: NSPopUpButton!
    @IBOutlet weak var shellScriptLabel: NSTextField!

    func setStates() {
        messageType.selectItem(at: PrefsInfo.message.messageType.rawValue)

        messageTextView.delegate = self
        messageTextView.string = PrefsInfo.message.message

        shellScript.stringValue = PrefsInfo.message.shellScript
        shellRefreshPeriodicity.selectItem(at: PrefsInfo.message.refreshPeriodicity.rawValue)
        shellScriptLabel.stringValue = ""
    }

    @IBAction func messageTypeChange(_ sender: NSPopUpButton) {
        PrefsInfo.message.messageType = InfoMessageType(rawValue: sender.indexOfSelectedItem)!

        guard let overlayController = self.parentViewController as? OverlaysViewController else {
            return
        }

        overlayController.switchSubMessagePanel()
    }

    // Basic text
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        PrefsInfo.message.message = textView.string
    }

    // Shell script
    @IBAction func shellScriptChange(_ sender: NSTextField) {
        PrefsInfo.message.shellScript = sender.stringValue
    }

    @IBAction func shellScriptTestClick(_ sender: Any) {
        PrefsInfo.message.shellScript = shellScript.stringValue

        if PrefsInfo.message.shellScript != "" {
            if FileManager.default.fileExists(atPath: PrefsInfo.message.shellScript) {
                let (result, code) = Aerial.shell(launchPath: PrefsInfo.message.shellScript)

                if let res = result {
                    shellScriptLabel.stringValue = res
                } else {
                    shellScriptLabel.stringValue = "Empty return value, return code: \(code)"
                }
            } else {
                shellScriptLabel.stringValue = "No file found at your location, please check your path"
            }
        } else {
            shellScriptLabel.stringValue = "Script location empty"
        }
    }

    @IBAction func shellRefreshPeriodicityChange(_ sender: NSPopUpButton) {
        PrefsInfo.message.refreshPeriodicity = InfoRefreshPeriodicity(rawValue: sender.indexOfSelectedItem)!
    }
}
