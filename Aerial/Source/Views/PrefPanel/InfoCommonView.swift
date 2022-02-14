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
    var controller: OverlaysViewController?

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
    func setType(_ forType: InfoType, controller: OverlaysViewController) {
        // We need the controller for callbacks, when we update the isEnabled state,
        // we need to update the list view on the left too
        self.controller = controller
        
        // Store type
        self.forType = forType

        // Update our states
        enabledButton.state = PrefsInfo.ofType(forType).isEnabled ? .on : .off
        setPosition(PrefsInfo.ofType(forType).corner)
        displaysPopup.selectItem(at: PrefsInfo.ofType(forType).displays.rawValue)
        fontLabel.stringValue = PrefsInfo.ofType(forType).fontName + ", \(PrefsInfo.ofType(forType).fontSize) pt"

        switch forType {
        case .location:
            //controller.infoBox.title = "Video location information"
            posRandom.isHidden = false
        case .message:
            //controller.infoBox.title = "Custom message"
            posRandom.isHidden = true
        case .clock:
            //controller.infoBox.title = "Current time"
            posRandom.isHidden = true
        case .date:
            //controller.infoBox.title = "Current date"
            posRandom.isHidden = true
        case .battery:
            //controller.infoBox.title = "Battery status"
            posRandom.isHidden = true
        case .updates:
            //controller.infoBox.title = "Updates notifications"
            posRandom.isHidden = true
        case .weather:
            //controller.infoBox.title = "Weather provided by OpenWeather"
            posRandom.isHidden = true
        case .countdown:
            //controller.infoBox.title = "Countdown to a time/date"
            posRandom.isHidden = true
        case .timer:
            //controller.infoBox.title = "Timer"
            posRandom.isHidden = true
        case .music:
            //controller.infoBox.title = "Music"
            posRandom.isHidden = true
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
        case .absTopRight:
            posTopRight.state = .on
        }
    }

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
        PrefsInfo.setCorner(forType, corner: pos)
    }

    // MARK: - Displays it should appear on

    @IBAction func changeDisplays(_ sender: NSPopUpButton) {
        PrefsInfo.setDisplayMode(forType, mode: InfoDisplays(rawValue: sender.indexOfSelectedItem)!)
    }

    // MARK: - enabled

    @IBAction func enabledClick(_ sender: NSButton) {
        PrefsInfo.setEnabled(forType, value: sender.state == .on)

        // We need to update the side column!
        controller!.infoTableView.reloadDataKeepingSelection()
    }

    // MARK: - Font picker

    @IBAction func changeFontClick(_ sender: Any) {
        // Make sure we get the callback
        NSFontManager.shared.target = self

        // Make a panel
        if let fp = NSFontManager.shared.fontPanel(true) {
            fp.setPanelFont(makeFont(name: PrefsInfo.ofType(forType).fontName,
                                     size: PrefsInfo.ofType(forType).fontSize), isMultiple: false)

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
        // We use a default font for all types
        PrefsInfo.setFontName(forType, name: "Helvetica Neue Medium")

        // Default Size varies though per type
        switch forType {
        case .location:
            PrefsInfo.location.fontSize = 28
        case .message:
            PrefsInfo.message.fontSize = 20
        case .clock:
            PrefsInfo.clock.fontSize = 50
        case .date:
            PrefsInfo.date.fontSize = 20
        case .battery:
            PrefsInfo.battery.fontSize = 20
        case .updates:
            PrefsInfo.updates.fontSize = 20
        case .weather:
            PrefsInfo.weather.fontSize = 20
        case .countdown:
            PrefsInfo.countdown.fontSize = 100
        case .timer:
            PrefsInfo.timer.fontSize = 100
        case .music:
            PrefsInfo.music.fontSize = 20
        }

        fontLabel.stringValue = PrefsInfo.ofType(forType).fontName + ", \(PrefsInfo.ofType(forType).fontSize) pt"
    }
}

// MARK: - Font Panel Delegates

extension InfoCommonView: NSFontChanging {
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        return [.size, .collection, .face]
    }

    func changeFont(_ sender: NSFontManager?) {
        // Set current font
        let oldFont = makeFont(name: PrefsInfo.ofType(forType).fontName,
                           size: PrefsInfo.ofType(forType).fontSize)

        if let newFont = sender?.convert(oldFont) {
            PrefsInfo.setFontName(forType, name: newFont.fontName)
            PrefsInfo.setFontSize(forType, size: Double(newFont.pointSize))

            fontLabel.stringValue = newFont.fontName + ", \(Double(newFont.pointSize)) pt"
        } else {
            errorLog("New font failure")
        }
    }
}
