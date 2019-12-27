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
    var controller: PreferencesWindowController?

    @IBOutlet var descriptionLabel: NSTextField!

    @IBOutlet var enabledButton: NSButton!
    @IBOutlet var fontLabel: NSTextField!

    @IBOutlet var displaysPopup: NSPopUpButton!

    @IBOutlet var posTopLeft: NSButton!
    @IBOutlet var posTopCenter: NSButton!
    @IBOutlet var posTopRight: NSButton!
    @IBOutlet var posBottomLeft: NSButton!
    @IBOutlet var posBottomCenter: NSButton!
    @IBOutlet var posBottomRight: NSButton!
    @IBOutlet var posScreenCenter: NSButton!
    @IBOutlet var posRandom: NSButton!

    // MARK: - init(ish)
    // This is what tells us what we are editing exactly
    func setType(_ forType: InfoType, controller: PreferencesWindowController) {
        // We need the controller for callbacks, when we update the isEnabled state,
        // we need to update the list view on the left too
        self.controller = controller

        // Store type
        self.forType = forType

        // Update our states
        switch forType {
        case .location:
            descriptionLabel.stringValue = "Localized information about the video location."
            enabledButton.state = PrefsInfo.location.isEnabled ? .on : .off
            setPosition(PrefsInfo.location.corner)
            posRandom.isHidden = false
            displaysPopup.selectItem(at: PrefsInfo.location.displays.rawValue)
            fontLabel.stringValue = PrefsInfo.location.fontName + ", \(PrefsInfo.location.fontSize) pt"
        case .message:
            descriptionLabel.stringValue = "Add a custom message (e-mail, name...)."
            enabledButton.state = PrefsInfo.message.isEnabled ? .on : .off
            setPosition(PrefsInfo.message.corner)
            posRandom.isHidden = true
            displaysPopup.selectItem(at: PrefsInfo.message.displays.rawValue)
            fontLabel.stringValue = PrefsInfo.message.fontName + ", \(PrefsInfo.message.fontSize) pt"
        case .clock:
            descriptionLabel.stringValue = "Add a clock."
            enabledButton.state = PrefsInfo.clock.isEnabled ? .on : .off
            setPosition(PrefsInfo.clock.corner)
            posRandom.isHidden = true
            displaysPopup.selectItem(at: PrefsInfo.clock.displays.rawValue)
            fontLabel.stringValue = PrefsInfo.clock.fontName + ", \(PrefsInfo.clock.fontSize) pt"
        case .battery:
            descriptionLabel.stringValue = "Show current battery status."
            enabledButton.state = PrefsInfo.battery.isEnabled ? .on : .off
            setPosition(PrefsInfo.battery.corner)
            posRandom.isHidden = true
            displaysPopup.selectItem(at: PrefsInfo.battery.displays.rawValue)
            fontLabel.stringValue = PrefsInfo.battery.fontName + ", \(PrefsInfo.battery.fontSize) pt"
        }
    }

    // MARK: - Position on screen

    func setPosition(_ corner: InfoCorner) {
        switch corner {
        case .topLeft:
            posTopLeft.state = .on
        case .topCenter:
            posTopCenter.state = .on
        case .topRight:
            posTopRight.state = .on
        case .bottomLeft:
            posBottomLeft.state = .on
        case .bottomCenter:
            posBottomCenter.state = .on
        case .bottomRight:
            posBottomRight.state = .on
        case .screenCenter:
            posScreenCenter.state = .on
        case .random:
            posRandom.state = .on
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    @IBAction func changePosition(_ sender: NSButton) {
        var pos: InfoCorner

        // Which button ?
        switch sender {
        case posTopLeft:
            pos = .topLeft
        case posTopCenter:
            pos = .topCenter
        case posTopRight:
            pos = .topRight
        case posBottomLeft:
            pos = .bottomLeft
        case posBottomCenter:
            pos = .bottomCenter
        case posBottomRight:
            pos = .bottomRight
        case posScreenCenter:
            pos = .screenCenter
        case posRandom:
            pos = .random
        default:
            pos = .bottomLeft
        }

        // Then set pref
        switch forType {
        case .location:
            PrefsInfo.location.corner = pos
        case .message:
            PrefsInfo.message.corner = pos
        case .clock:
            PrefsInfo.clock.corner = pos
        case .battery:
            PrefsInfo.battery.corner = pos
        }
    }

    // MARK: - Displays it should appear on

    @IBAction func changeDisplays(_ sender: NSPopUpButton) {
        switch forType {
        case .location:
            PrefsInfo.location.displays = InfoDisplays(rawValue: sender.indexOfSelectedItem)!
        case .message:
            PrefsInfo.message.displays = InfoDisplays(rawValue: sender.indexOfSelectedItem)!
        case .clock:
            PrefsInfo.clock.displays = InfoDisplays(rawValue: sender.indexOfSelectedItem)!
        case .battery:
            PrefsInfo.battery.displays = InfoDisplays(rawValue: sender.indexOfSelectedItem)!
        }
    }

    // MARK: - enabled

    @IBAction func enabledClick(_ sender: NSButton) {
        let onState = sender.state == .on
        // debugLog("enabledClick: \(onState) for \(forType)")

        switch forType {
        case .location:
            PrefsInfo.location.isEnabled = onState
        case .message:
            PrefsInfo.message.isEnabled = onState
        case .clock:
            PrefsInfo.clock.isEnabled = onState
        case .battery:
            PrefsInfo.battery.isEnabled = onState
        }

        // We need to update the side column!
        controller!.infoTableView.reloadDataKeepingSelection()
    }

    // MARK: - Font picker

    @IBAction func changeFontClick(_ sender: Any) {
        // Make sure we get the callback
        NSFontManager.shared.target = self

        // Make a panel
        if let fp = NSFontManager.shared.fontPanel(true) {
            switch forType {
            case .location:
                fp.setPanelFont(makeFont(name: PrefsInfo.location.fontName,
                                         size: PrefsInfo.location.fontSize), isMultiple: false)
            case .message:
                fp.setPanelFont(makeFont(name: PrefsInfo.message.fontName,
                                         size: PrefsInfo.message.fontSize), isMultiple: false)
            case .clock:
                fp.setPanelFont(makeFont(name: PrefsInfo.clock.fontName,
                                         size: PrefsInfo.clock.fontSize), isMultiple: false)
            case .battery:
                fp.setPanelFont(makeFont(name: PrefsInfo.battery.fontName,
                                         size: PrefsInfo.battery.fontSize), isMultiple: false)
            }

            // Push the panel
            fp.makeKeyAndOrderFront(sender)
        }
    }

    func makeFont(name: String, size: Double) -> NSFont {
        if let font = NSFont(name: name, size: CGFloat(size)) {
            return font
        } else {
            // This is probably enough
            return NSFont(name: "Helvetica Neue Medium", size: 28)!
        }
    }

    @IBAction func resetFontClick(_ sender: Any) {
        switch forType {
        case .location:
            PrefsInfo.location.fontName = "Helvetica Neue Medium"
            PrefsInfo.location.fontSize = 28
            fontLabel.stringValue = PrefsInfo.location.fontName + ", \(PrefsInfo.location.fontSize) pt"
        case .message:
            PrefsInfo.message.fontName = "Helvetica Neue Medium"
            PrefsInfo.message.fontSize = 20
            fontLabel.stringValue = PrefsInfo.message.fontName + ", \(PrefsInfo.message.fontSize) pt"
        case .clock:
            PrefsInfo.clock.fontName = "Helvetica Neue Medium"
            PrefsInfo.clock.fontSize = 50
            fontLabel.stringValue = PrefsInfo.clock.fontName + ", \(PrefsInfo.clock.fontSize) pt"
        case .battery:
            PrefsInfo.battery.fontName = "Helvetica Neue Medium"
            PrefsInfo.battery.fontSize = 20
            fontLabel.stringValue = PrefsInfo.battery.fontName + ", \(PrefsInfo.battery.fontSize) pt"
        }
    }
}

// MARK: - Font Panel Delegates

extension InfoCommonView: NSFontChanging {
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        return [.size, .collection, .face]
    }

    func changeFont(_ sender: NSFontManager?) {
        // Set current font
        let oldFont: NSFont

        switch forType {
        case .location:
            oldFont = makeFont(name: PrefsInfo.location.fontName,
                               size: PrefsInfo.location.fontSize)
        case .message:
            oldFont = makeFont(name: PrefsInfo.message.fontName,
                               size: PrefsInfo.message.fontSize)
        case .clock:
            oldFont = makeFont(name: PrefsInfo.clock.fontName,
                               size: PrefsInfo.clock.fontSize)
        case .battery:
            oldFont = makeFont(name: PrefsInfo.battery.fontName,
                               size: PrefsInfo.battery.fontSize)

        }

        if let newFont = sender?.convert(oldFont) {
            switch forType {
            case .location:
                PrefsInfo.location.fontName = newFont.fontName
                PrefsInfo.location.fontSize = Double(newFont.pointSize)
            case .message:
                PrefsInfo.message.fontName = newFont.fontName
                PrefsInfo.message.fontSize = Double(newFont.pointSize)
            case .clock:
                PrefsInfo.clock.fontName = newFont.fontName
                PrefsInfo.clock.fontSize = Double(newFont.pointSize)
            case .battery:
                PrefsInfo.battery.fontName = newFont.fontName
                PrefsInfo.battery.fontSize = Double(newFont.pointSize)
            }
            fontLabel.stringValue = newFont.fontName + ", \(Double(newFont.pointSize)) pt"
        } else {
            errorLog("New font failure")
        }
    }
}
