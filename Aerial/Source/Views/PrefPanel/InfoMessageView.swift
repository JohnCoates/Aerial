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

    func setStates() {
        messageTextField.stringValue = PrefsInfo.message.message
    }

    @IBAction func messageChange(_ sender: NSTextField) {
        PrefsInfo.message.message = sender.stringValue
    }

    @IBAction func messageExtraClick(_ sender: Any) {
        // TODO
    }
}
