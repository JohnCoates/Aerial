//
//  InfoCommonView.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoCommonView: NSView {
    var forType: InfoType = .location

    @IBOutlet var enabledButton: NSButton!
    @IBOutlet var fontLabel: NSTextField!

    func setType(_ forType: InfoType) {
        print("setType")
        self.forType = forType

        // Update Enabled button
        switch forType {
        case .location:
            enabledButton.state = PrefsInfo.location.isEnabled ? .on : .off
            fontLabel.stringValue = PrefsInfo.location.fontName + ", \(PrefsInfo.location.fontSize) pt"
        case .message:
            enabledButton.state = PrefsInfo.message.isEnabled ? .on : .off
            fontLabel.stringValue = PrefsInfo.message.fontName + ", \(PrefsInfo.message.fontSize) pt"
        case .clock:
            enabledButton.state = PrefsInfo.clock.isEnabled ? .on : .off
            fontLabel.stringValue = PrefsInfo.clock.fontName + ", \(PrefsInfo.clock.fontSize) pt"
        }

        // Update font
//        fontLabel.stringValue = forType.rawValue

    }

    @IBAction func enabledClick(_ sender: NSButton) {
        let onState = sender.state == .on
        debugLog("enabledClick: \(onState) for \(forType)")

        switch forType {
        case .location:
            PrefsInfo.location.isEnabled = onState
        case .message:
            PrefsInfo.message.isEnabled = onState
        case .clock:
            PrefsInfo.clock.isEnabled = onState
        }
    }

    @IBAction func changeFontClick(_ sender: Any) {
    }

    @IBAction func resetFontClick(_ sender: Any) {
    }
}
