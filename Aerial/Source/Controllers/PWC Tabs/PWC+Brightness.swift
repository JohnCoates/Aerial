//
//  PWC+Brightness.swift
//  Aerial
//      This is the controller code for the Brightness Tab
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Cocoa

extension PreferencesWindowController {
    func setupBrightnessTab() {
        // Brightness panel
        if preferences.overrideDimInMinutes {
            overrideDimFadeCheckbox.state = .on
        }

        if preferences.dimBrightness {
            dimBrightness.state = .on
            changeBrightnessState(to: true)
        } else {
            changeBrightnessState(to: false)
        }

        if preferences.dimOnlyOnBattery {
            dimOnlyOnBattery.state = .on
        }
        if preferences.dimOnlyAtNight {
            dimOnlyAtNight.state = .on
        }
        dimStartFrom.doubleValue = preferences.startDim ?? 0.5
        dimFadeTo.doubleValue = preferences.endDim ?? 0.1
        dimFadeInMinutes.stringValue = String(preferences.dimInMinutes!)
        dimFadeInMinutesStepper.intValue = Int32(preferences.dimInMinutes!)

    }

    func changeBrightnessState(to: Bool) {
        dimOnlyAtNight.isEnabled = to
        dimOnlyOnBattery.isEnabled = to
        dimStartFrom.isEnabled = to
        dimFadeTo.isEnabled = to
        overrideDimFadeCheckbox.isEnabled = to
        if (to && preferences.overrideDimInMinutes) || !to {
            dimFadeInMinutes.isEnabled = to
            dimFadeInMinutesStepper.isEnabled = to
        } else {
            dimFadeInMinutes.isEnabled = false
            dimFadeInMinutesStepper.isEnabled = false
        }
    }

    @IBAction func overrideFadeDurationClick(_ sender: NSButton) {
        let onState = sender.state == .on
        preferences.overrideDimInMinutes = onState
        changeBrightnessState(to: preferences.dimBrightness)
        debugLog("UI dimBrightness: \(onState)")
    }

    @IBAction func dimBrightnessClick(_ button: NSButton) {
        let onState = button.state == .on
        preferences.dimBrightness = onState
        changeBrightnessState(to: onState)
        debugLog("UI dimBrightness: \(onState)")
    }

    @IBAction func dimOnlyAtNightClick(_ button: NSButton) {
        let onState = button.state == .on
        preferences.dimOnlyAtNight = onState
        debugLog("UI dimOnlyAtNight: \(onState)")
    }

    @IBAction func dimOnlyOnBattery(_ button: NSButton) {
        let onState = button.state == .on
        preferences.dimOnlyOnBattery = onState
        debugLog("UI dimOnlyOnBattery: \(onState)")
    }

    @IBAction func dimStartFromChange(_ sender: NSSliderCell) {
        guard let event = NSApplication.shared.currentEvent else { return }

        guard [.leftMouseUp, .leftMouseDown, .leftMouseDragged].contains(event.type) else {
            //warnLog("Unexepected event type \(event.type)")
            return
        }

        let timeManagement = TimeManagement.sharedInstance
        if event.type == .leftMouseUp {
            if let brightness = savedBrightness {
                timeManagement.setBrightness(level: brightness)
                savedBrightness = nil
            }
            preferences.startDim = sender.doubleValue
            debugLog("UI startDim: \(sender.doubleValue)")
        } else {
            if savedBrightness == nil {
                savedBrightness = timeManagement.getBrightness()
            }
            timeManagement.setBrightness(level: sender.floatValue)
        }
    }

    @IBAction func dimFadeToChange(_ sender: NSSliderCell) {
        guard let event = NSApplication.shared.currentEvent else { return }

        if ![.leftMouseUp, .leftMouseDown, .leftMouseDragged].contains(event.type) {
            //warnLog("Unexepected event type \(event.type)")
        }

        let timeManagement = TimeManagement.sharedInstance
        if event.type == .leftMouseUp {
            if let brightness = savedBrightness {
                timeManagement.setBrightness(level: brightness)
                savedBrightness = nil
            }
            preferences.endDim = sender.doubleValue
            debugLog("UI endDim: \(sender.doubleValue)")
        } else {
            if savedBrightness == nil {
                savedBrightness = timeManagement.getBrightness()
            }
            timeManagement.setBrightness(level: sender.floatValue)
        }
    }

    @IBAction func dimInMinutes(_ sender: NSControl) {
        if sender == dimFadeInMinutes {
            if let intValue = Int(sender.stringValue) {
                preferences.dimInMinutes = intValue
                dimFadeInMinutesStepper.intValue = Int32(intValue)
            }
        } else {
            preferences.dimInMinutes = Int(sender.intValue)
            dimFadeInMinutes.stringValue = String(sender.intValue)
        }
        debugLog("UI dimInMinutes \(sender.stringValue)")
    }
}
