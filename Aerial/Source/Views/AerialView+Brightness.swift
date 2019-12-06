//
//  AerialView+Brightness.swift
//  Aerial
//
//  Created by Guillaume Louel on 06/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation

extension AerialView {
    // We make sure we should dim, we're not a preview, we haven't dimmed yet (multi monitor)
    // and ensure we properly apply the night/battery restrictions !
    func checkIfShouldSetBrightness() {
        let preferences = Preferences.sharedInstance
        let timeManagement = TimeManagement.sharedInstance
        let batteryManagement = BatteryManagement()

        if preferences.dimBrightness && !isPreview && brightnessToRestore == nil {
            let (should, to) = timeManagement.shouldRestrictPlaybackToDayNightVideo()

            if !preferences.dimOnlyAtNight || (preferences.dimOnlyAtNight && should && to == "night") {
                if !preferences.dimOnlyOnBattery || (preferences.dimOnlyOnBattery && batteryManagement.isOnBattery()) {
                    brightnessToRestore = timeManagement.getBrightness()
                    debugLog("Brightness before Aerial was launched : \(String(describing: brightnessToRestore))")
                    timeManagement.setBrightness(level: min(Float(preferences.startDim!), brightnessToRestore!))
                    setDimTimers()
                }
            }
        }
    }

    // Set the timers to progressively dim the screen brightness (in 10 steps)
    // Currently, this only works with internal monitors
    func setDimTimers() {
        if #available(OSX 10.12, *) {
            let preferences = Preferences.sharedInstance
            let timeManagement = TimeManagement.sharedInstance
            let startValue = min(preferences.startDim!, Double(brightnessToRestore!))

            if preferences.dimBrightness && startValue > preferences.endDim! {
                debugLog("setting brightness timers from \(String(describing: startValue)) to \(String(describing: preferences.endDim))")
                var interval: Int
                if preferences.overrideDimInMinutes {
                    interval = preferences.dimInMinutes! * 6 // * 60 / 10, we make 10 intermediate steps
                } else {
                    interval = timeManagement.getCurrentSleepTime() * 6
                    if interval == 0 {
                        interval = 180 // Fallback to 30 mins if no sleep
                    }
                }
                debugLog("Step size: \(interval) seconds")

                for idx in 1...10 {
                    _ = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval * idx), repeats: false) { (_) in
                        let val = startValue - ((startValue - preferences.endDim!) / 10 * Double(idx))
                        debugLog("Firing event \(idx) brightness to \(val)")
                        timeManagement.setBrightness(level: Float(val))
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            warnLog("Brightness control not available < macOS 10.12")
        }
    }
}
