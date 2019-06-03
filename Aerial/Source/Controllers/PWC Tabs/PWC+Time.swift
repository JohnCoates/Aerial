//
//  PWC+Time.swift
//  Aerial
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Cocoa
import CoreLocation

extension PreferencesWindowController {
    // swiftlint:disable:next cyclomatic_complexity
    func setupTimeTab() {
        let timeManagement = TimeManagement.sharedInstance

        // Some better icons are 10.12.2+ only
        if #available(OSX 10.12.2, *) {
            iconTime1.image = NSImage(named: NSImage.touchBarHistoryTemplateName)
            iconTime2.image = NSImage(named: NSImage.touchBarComposeTemplateName)
            iconTime3.image = NSImage(named: NSImage.touchBarOpenInBrowserTemplateName)
            findCoordinatesButton.image = NSImage(named: NSImage.touchBarOpenInBrowserTemplateName)
        }

        // Dark Mode is Mojave+
        if #available(OSX 10.14, *) {
            if preferences.darkModeNightOverride {
                overrideNightOnDarkMode.state = .on
            }
            // We disable the checkbox if we are on nightShift mode
            if preferences.timeMode == Preferences.TimeMode.lightDarkMode.rawValue {
                overrideNightOnDarkMode.isEnabled = false
            }
        } else {
            overrideNightOnDarkMode.isEnabled = false
        }

        // Light/Dark mode only available on Mojave+
        let (isLDMCapable, reason: LDMReason) = timeManagement.isLightDarkModeAvailable()
        if !isLDMCapable {
            timeLightDarkModeRadio.isEnabled = false
        }
        lightDarkModeLabel.stringValue = LDMReason

        // Night Shift requires 10.12.4+ and a compatible Mac
        let (isNSCapable, reason: NSReason) = timeManagement.isNightShiftAvailable()
        if !isNSCapable {
            timeNightShiftRadio.isEnabled = false
        }
        nightShiftLabel.stringValue = NSReason

        let (_, reason) = timeManagement.calculateFromCoordinates()
        calculateCoordinatesLabel.stringValue = reason

        if let dateSunrise = timeFormatter.date(from: preferences.manualSunrise!) {
            sunriseTime.dateValue = dateSunrise
        }
        if let dateSunset = timeFormatter.date(from: preferences.manualSunset!) {
            sunsetTime.dateValue = dateSunset
        }
        latitudeTextField.stringValue = preferences.latitude!
        longitudeTextField.stringValue = preferences.longitude!
        extraLatitudeTextField.stringValue = preferences.latitude!
        extraLongitudeTextField.stringValue = preferences.longitude!

        // Handle the time radios
        switch preferences.timeMode {
        case Preferences.TimeMode.nightShift.rawValue:
            timeNightShiftRadio.state = .on
        case Preferences.TimeMode.manual.rawValue:
            timeManualRadio.state = .on
        case Preferences.TimeMode.lightDarkMode.rawValue:
            timeLightDarkModeRadio.state = .on
        case Preferences.TimeMode.coordinates.rawValue:
            timeCalculateRadio.state = .on
        default:
            timeDisabledRadio.state = .on
        }

        let sleepTime = timeManagement.getCurrentSleepTime()
        if sleepTime != 0 {
            sleepAfterLabel.stringValue = "Your Mac currently goes to sleep after \(sleepTime) minutes"
        } else {
            sleepAfterLabel.stringValue = "Unable to determine your Mac sleep settings"
        }

        solarModePopup.selectItem(at: preferences.solarMode!)
    }

    @IBAction func overrideNightOnDarkModeClick(_ button: NSButton) {
        let onState = button.state == .on
        preferences.darkModeNightOverride = onState
        debugLog("UI overrideNightDarkMode: \(onState)")
    }

    @IBAction func enterCoordinatesButtonClick(_ sender: Any) {
        if enterCoordinatesPanel.isVisible {
            enterCoordinatesPanel.close()
        } else {
            enterCoordinatesPanel.makeKeyAndOrderFront(sender)
        }
    }

    @IBAction func closeCoordinatesPanel(_ sender: Any) {
        enterCoordinatesPanel.close()
    }

    @IBAction func timeModeChange(_ sender: NSButton?) {
        debugLog("UI timeModeChange")
        if sender == timeLightDarkModeRadio {
            print("dis")
            overrideNightOnDarkMode.isEnabled = false
        } else {
            if #available(OSX 10.14, *) {
                overrideNightOnDarkMode.isEnabled = true
            }
        }

        switch sender {
        case timeDisabledRadio:
            preferences.timeMode = Preferences.TimeMode.disabled.rawValue
        case timeNightShiftRadio:
            preferences.timeMode = Preferences.TimeMode.nightShift.rawValue
        case timeManualRadio:
            preferences.timeMode = Preferences.TimeMode.manual.rawValue
        case timeLightDarkModeRadio:
            preferences.timeMode = Preferences.TimeMode.lightDarkMode.rawValue
        case timeCalculateRadio:
            preferences.timeMode = Preferences.TimeMode.coordinates.rawValue
        default:
            ()
        }
    }

    @IBAction func sunriseChange(_ sender: NSDatePicker?) {
        guard let date = sender?.dateValue else { return }
        preferences.manualSunrise = timeFormatter.string(from: date)
    }

    @IBAction func sunsetChange(_ sender: NSDatePicker?) {
        guard let date = sender?.dateValue else { return }
        preferences.manualSunset = timeFormatter.string(from: date)
    }

    @IBAction func latitudeChange(_ sender: NSTextField) {
        preferences.latitude = sender.stringValue
        if sender == extraLatitudeTextField {
            latitudeTextField.stringValue = sender.stringValue
        }
        updateLatitudeLongitude()
    }

    @IBAction func longitudeChange(_ sender: NSTextField) {
        debugLog("longitudechange")
        preferences.longitude = sender.stringValue
        if sender == extraLongitudeTextField {
            longitudeTextField.stringValue = sender.stringValue
        }
        updateLatitudeLongitude()
    }

    func updateLatitudeLongitude() {
        let timeManagement = TimeManagement.sharedInstance
        let (_, reason) = timeManagement.calculateFromCoordinates()
        calculateCoordinatesLabel.stringValue = reason
    }

    @IBAction func solarModePopupChange(_ sender: NSPopUpButton) {
        preferences.solarMode = sender.indexOfSelectedItem
        debugLog("UI solarModePopupChange: \(sender.indexOfSelectedItem)")
        updateLatitudeLongitude()
    }

    @IBAction func helpTimeButtonClick(_ button: NSButton) {
        popoverTime.show(relativeTo: button.preparedContentRect, of: button, preferredEdge: .maxY)
    }

    @IBAction func linkToWikipediaTimeClick(_ sender: NSButton) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://en.wikipedia.org/wiki/Twilight")!
        workspace.open(url)
    }

    @IBAction func findCoordinatesButtonClick(_ sender: NSButton) {
        debugLog("UI findCoordinatesButton")

        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager!.purpose = "Aerial uses your location to calculate sunrise and sunset times"

        if CLLocationManager.locationServicesEnabled() {
            debugLog("Location services enabled")

            _ = CLLocationManager.authorizationStatus()

            locationManager!.startUpdatingLocation()
        } else {
            errorLog("Location services are disabled, please check your macOS settings!")
            return
        }
    }

    func pushCoordinates(_ coordinates: CLLocationCoordinate2D) {
        latitudeTextField.stringValue = String(format: "%.3f", coordinates.latitude)
        longitudeTextField.stringValue = String(format: "%.3f", coordinates.longitude)

        preferences.latitude = String(format: "%.3f", coordinates.latitude)
        preferences.longitude = String(format: "%.3f", coordinates.longitude)
        updateLatitudeLongitude()
    }
}

// MARK: - Core Location Delegates

extension PreferencesWindowController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        debugLog("LM Coordinates")
        let currentLocation = locations[locations.count - 1]
        pushCoordinates(currentLocation.coordinate)
        locationManager!.stopUpdatingLocation()     // We only want them once
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        debugLog("LMauth status change : \(status.rawValue)")
    }

    /*func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
     errorLog("Location Manager error : \(error)")
     }*/
}
