//
//  TimeViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 19/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class TimeViewController: NSViewController {
    // All the radios
    @IBOutlet var timeLocationRadio: NSButton!
    @IBOutlet var timeCalculateRadio: NSButton!
    @IBOutlet var timeNightShiftRadio: NSButton!
    @IBOutlet var timeManualRadio: NSButton!
    @IBOutlet var timeLightDarkModeRadio: NSButton!
    @IBOutlet var timeDisabledRadio: NSButton!

    // Calculate mode
    @IBOutlet var latitudeTextField: NSTextField!
    @IBOutlet var longitudeTextField: NSTextField!
    @IBOutlet var latitudeFormatter: NumberFormatter!
    @IBOutlet var longitudeFormatter: NumberFormatter!

    @IBOutlet var calculateCoordinatesLabel: NSTextField!

    // Night Shift
    @IBOutlet var nightShiftLabel: NSTextField!

    // Manual
    @IBOutlet var sunriseTime: NSDatePicker!
    @IBOutlet var sunsetTime: NSDatePicker!

    // Light/dark
    @IBOutlet var lightDarkModeLabel: NSTextField!

    // Advanced
    @IBOutlet var solarModePopup: NSPopUpButton!
    @IBOutlet var darkModeNightOverride: NSButton!

    @IBOutlet var myLocationImageView: NSImageView!

    @IBOutlet var popoverCalcMode: NSPopover!

    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let timeManagement = TimeManagement.sharedInstance
        latitudeFormatter.maximumSignificantDigits = 10
        longitudeFormatter.maximumSignificantDigits = 10

        setupDarkMode()
        setupNightShift()

        let (_, reason) = timeManagement.calculateFromCoordinates()
        calculateCoordinatesLabel.stringValue = reason

        if let dateSunrise = timeFormatter.date(from: PrefsTime.manualSunrise) {
            sunriseTime.dateValue = dateSunrise
        }
        if let dateSunset = timeFormatter.date(from: PrefsTime.manualSunset) {
            sunsetTime.dateValue = dateSunset
        }
        latitudeTextField.stringValue = PrefsTime.latitude
        longitudeTextField.stringValue = PrefsTime.longitude

        // Handle the time radios
        switch PrefsTime.timeMode {
        case .nightShift:
            timeNightShiftRadio.state = .on
        case .manual:
            timeManualRadio.state = .on
        case .lightDarkMode:
            timeLightDarkModeRadio.state = .on
        case .coordinates:
            timeCalculateRadio.state = .on
        case .disabled:
            timeDisabledRadio.state = .on
        case .locationService:
            timeLocationRadio.state = .on
        }

        myLocationImageView.image = Aerial.getSymbol("mappin.and.ellipse")?.tinting(with: .secondaryLabelColor)
        solarModePopup.selectItem(at: PrefsTime.solarMode.rawValue)
    }

    func setupDarkMode() {
        // Dark Mode is Mojave+
        if #available(OSX 10.14, *) {
            if PrefsTime.darkModeNightOverride {
                darkModeNightOverride.state = .on
            }
            // We disable the checkbox if we are on nightShift mode
            if PrefsTime.timeMode == .lightDarkMode {
                darkModeNightOverride.isEnabled = false
            }
        } else {
            darkModeNightOverride.isEnabled = false
        }

        // Light/Dark mode only available on Mojave+
        let (isLDMCapable, reason: LDMReason) = DarkMode.isAvailable()
        if !isLDMCapable {
            timeLightDarkModeRadio.isEnabled = false
        }
        lightDarkModeLabel.stringValue = LDMReason
    }

    func setupNightShift() {
        // Night Shift requires 10.12.4+ and a compatible Mac
        let (isNSCapable, reason: NSReason) = NightShift.isAvailable()
        if !isNSCapable {
            timeNightShiftRadio.isEnabled = false
        }
        nightShiftLabel.stringValue = NSReason
    }

    @IBAction func timeModeChange(_ sender: NSButton) {
        if sender == timeLightDarkModeRadio {
            darkModeNightOverride.isEnabled = false
        } else {
            if #available(OSX 10.14, *) {
                darkModeNightOverride.isEnabled = true
            }
        }

        switch sender {
        case timeDisabledRadio:
            PrefsTime.timeMode = .disabled
        case timeNightShiftRadio:
            PrefsTime.timeMode = .nightShift
        case timeManualRadio:
            PrefsTime.timeMode = .manual
        case timeLightDarkModeRadio:
            PrefsTime.timeMode = .lightDarkMode
        case timeCalculateRadio:
            PrefsTime.timeMode = .coordinates
        case timeLocationRadio:
            PrefsTime.timeMode = .locationService
        default:
            ()
        }
    }

    @IBAction func latitudeChange(_ sender: NSTextField) {
        PrefsTime.latitude = sender.stringValue
        updateLatitudeLongitude()
    }

    @IBAction func longitudeChange(_ sender: NSTextField) {
        PrefsTime.longitude = sender.stringValue
        updateLatitudeLongitude()
    }

    func updateLatitudeLongitude() {
        let timeManagement = TimeManagement.sharedInstance
        let (_, reason) = timeManagement.calculateFromCoordinates()
        calculateCoordinatesLabel.stringValue = reason
    }

    @IBAction func sunriseChange(_ sender: NSDatePicker?) {
        guard let date = sender?.dateValue else { return }
        PrefsTime.manualSunrise = timeFormatter.string(from: date)
    }

    @IBAction func sunsetChange(_ sender: NSDatePicker?) {
        guard let date = sender?.dateValue else { return }
        PrefsTime.manualSunset = timeFormatter.string(from: date)
    }

    @IBAction func solarPopupChange(_ sender: NSPopUpButton) {
        PrefsTime.solarMode = SolarMode(rawValue: sender.indexOfSelectedItem)!
        updateLatitudeLongitude()
    }

    @IBAction func darkModeNightOverrideClick(_ sender: NSButton) {
        PrefsTime.darkModeNightOverride = sender.state == .on
    }

    @IBAction func testLocationClick(_ sender: Any) {
        // Get the location
        let location = Locations.sharedInstance

        location.getCoordinates(failure: { (_) in
            // swiftlint:disable:next line_length
            Aerial.showInfoAlert(title: "Could not get your location", text: "Make sure you enabled location services on your Mac, and that Aerial (or legacyScreenSaver on macOS 10.15 and later) is allowed to use your location.", button1: "OK", caution: true)
        }, success: { (coordinates) in
            let lat = String(format: "%.2f", coordinates.latitude)
            let lon = String(format: "%.2f", coordinates.longitude)

            // swiftlint:disable:next line_length
            Aerial.showInfoAlert(title: "Success", text: "Aerial can access your location (latitude: \(lat), longitude: \(lon)) and will use it to show you the correct videos.")
        })
    }

    @IBAction func helpCalcModeClick(_ sender: NSButton) {
        popoverCalcMode.show(relativeTo: sender.preparedContentRect, of: sender, preferredEdge: .maxY)
    }
}
