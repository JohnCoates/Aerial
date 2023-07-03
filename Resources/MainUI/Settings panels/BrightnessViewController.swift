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
        if PrefsDisplays.dimBrightness {
            lowerBrightness.state = .on
            changeBrightnessState(to: true)
        } else {
            changeBrightnessState(to: false)
        }

        startFromSlider.doubleValue = PrefsDisplays.startDim
        fadeToSlider.doubleValue = PrefsDisplays.endDim

        onlyDimAtNight.state = PrefsDisplays.dimOnlyAtNight ? .on : .off
        onlyDimOnBattery.state = PrefsDisplays.dimOnlyAtNight ? .on : .off

        DispatchQueue.main.async {
            let sleepTime = TimeManagement.sharedInstance.getCurrentSleepTime()
            if sleepTime != 0 {
                self.sleepAfterLabel.stringValue = "Your Mac currently goes to sleep after \(sleepTime) minute\(sleepTime != 1 ? "s" : "")"
            } else {
                self.sleepAfterLabel.stringValue = "Unable to determine your Mac sleep settings"
            }
        }
    }

    func changeBrightnessState(to: Bool) {
        onlyDimAtNight.isEnabled = to
        onlyDimOnBattery.isEnabled = to
        startFromSlider.isEnabled = to
        fadeToSlider.isEnabled = to
    }

    @IBAction func lowerBrightnessClick(_ sender: NSButton) {
        PrefsDisplays.dimBrightness = sender.state == .on
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
            PrefsDisplays.startDim = sender.doubleValue
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
            PrefsDisplays.endDim = sender.doubleValue
        } else {
            if savedBrightness == nil {
                savedBrightness = Brightness.get()
            }
            Brightness.set(level: sender.floatValue)
        }
    }
    @IBAction func onlyDimAtNightClick(_ sender: NSButton) {
        PrefsDisplays.dimOnlyAtNight = sender.state == .on
    }
    @IBAction func onlyDimOnBatteryClick(_ sender: NSButton) {
        PrefsDisplays.dimOnlyOnBattery = sender.state == .on
    }
}
