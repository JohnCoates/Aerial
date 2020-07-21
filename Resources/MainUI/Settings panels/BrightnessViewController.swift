//
//  BrightnessViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 19/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class BrightnessViewController: NSViewController {

    @IBOutlet var lowerBrightness: NSButton!

    @IBOutlet var startFromSlider: NSSlider!
    @IBOutlet var fadeToSlider: NSSlider!

    @IBOutlet var sleepAfterLabel: NSTextField!

    @IBOutlet var onlyDimAtNight: NSButton!
    @IBOutlet var onlyDimOnBattery: NSButton!

    var savedBrightness: Float?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Main switch
        if Preferences.sharedInstance.dimBrightness {
            lowerBrightness.state = .on
            changeBrightnessState(to: true)
        } else {
            changeBrightnessState(to: false)
        }

        startFromSlider.doubleValue = Preferences.sharedInstance.startDim!
        fadeToSlider.doubleValue = Preferences.sharedInstance.endDim!

        onlyDimAtNight.state = Preferences.sharedInstance.dimOnlyAtNight ? .on : .off
        onlyDimOnBattery.state = Preferences.sharedInstance.dimOnlyAtNight ? .on : .off

        let sleepTime = TimeManagement.sharedInstance.getCurrentSleepTime()
        if sleepTime != 0 {
            sleepAfterLabel.stringValue = "Your Mac currently goes to sleep after \(sleepTime) minutes"
        } else {
            sleepAfterLabel.stringValue = "Unable to determine your Mac sleep settings"
        }
    }

    func changeBrightnessState(to: Bool) {
        onlyDimAtNight.isEnabled = to
        onlyDimOnBattery.isEnabled = to
        startFromSlider.isEnabled = to
        fadeToSlider.isEnabled = to
    }

    @IBAction func lowerBrightnessClick(_ sender: NSButton) {
        Preferences.sharedInstance.dimBrightness = sender.state == .on
        changeBrightnessState(to: sender.state == .on)

    }

    @IBAction func startFromSliderChange(_ sender: NSSliderCell) {
        guard let event = NSApplication.shared.currentEvent else { return }

        guard [.leftMouseUp, .leftMouseDown, .leftMouseDragged].contains(event.type) else {
            return
        }

        if event.type == .leftMouseUp {
            if let brightness = savedBrightness {
                Brightness.set(level: brightness)
                savedBrightness = nil
            }
            Preferences.sharedInstance.startDim = sender.doubleValue
        } else {
            if savedBrightness == nil {
                savedBrightness = Brightness.get()
            }
            Brightness.set(level: sender.floatValue)
        }
    }

    @IBAction func fadeToSliderChange(_ sender: NSSliderCell) {
        guard let event = NSApplication.shared.currentEvent else { return }

        // Hmm
        if ![.leftMouseUp, .leftMouseDown, .leftMouseDragged].contains(event.type) {
        }

        if event.type == .leftMouseUp {
            if let brightness = savedBrightness {
                Brightness.set(level: brightness)
                savedBrightness = nil
            }
            Preferences.sharedInstance.endDim = sender.doubleValue
        } else {
            if savedBrightness == nil {
                savedBrightness = Brightness.get()
            }
            Brightness.set(level: sender.floatValue)
        }
    }
    @IBAction func onlyDimAtNightClick(_ sender: NSButton) {
        Preferences.sharedInstance.dimOnlyAtNight = sender.state == .on
    }
    @IBAction func onlyDimOnBatteryClick(_ sender: NSButton) {
        Preferences.sharedInstance.dimOnlyOnBattery = sender.state == .on
    }
}
