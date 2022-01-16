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
    @IBOutlet var timeNightShiftRadio: NSButton!
    @IBOutlet var timeManualRadio: NSButton!
    @IBOutlet var timeLightDarkModeRadio: NSButton!
    @IBOutlet var timeDisabledRadio: NSButton!

    // Night Shift
    @IBOutlet var nightShiftLabel: NSTextField!

    // Manual
    @IBOutlet var sunriseTime: NSDatePicker!
    @IBOutlet var sunsetTime: NSDatePicker!

    // Advanced
    @IBOutlet var darkModeNightOverride: NSButton!

    @IBOutlet var myLocationImageView: NSImageView!

    @IBOutlet var nightShiftImageView: NSImageView!

    @IBOutlet var manualImageView: NSImageView!

    @IBOutlet var lightModeImageView: NSImageView!

    @IBOutlet var noAdaptImageView: NSImageView!
    @IBOutlet var popoverCalcMode: NSPopover!

    @IBOutlet var oSunrise: NSTextField!
    @IBOutlet var eSunrise: NSTextField!
    @IBOutlet var eSunset: NSTextField!
    @IBOutlet var oSunset: NSTextField!

    @IBOutlet var timeBarView: NSView!

    @IBOutlet var sunsetWindowPopup: NSPopUpButton!

    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    // swiftlint:disable cyclomatic_complexity
    override func viewDidLoad() {
        super.viewDidLoad()

        setupDarkMode()
        setupNightShift()

        if let dateSunrise = timeFormatter.date(from: PrefsTime.manualSunrise) {
            sunriseTime.dateValue = dateSunrise
        }
        if let dateSunset = timeFormatter.date(from: PrefsTime.manualSunset) {
            sunsetTime.dateValue = dateSunset
        }

        // Handle the time radios
        switch PrefsTime.timeMode {
        case .nightShift:
            timeNightShiftRadio.state = .on
        case .manual:
            timeManualRadio.state = .on
        case .lightDarkMode:
            timeLightDarkModeRadio.state = .on
        case .disabled:
            timeDisabledRadio.state = .on
        default:
            timeLocationRadio.state = .on
        }

        myLocationImageView.image = Aerial.getSymbol("mappin.and.ellipse")?.tinting(with: .secondaryLabelColor)

        nightShiftImageView.image = Aerial.getSymbol("house")?.tinting(with: .secondaryLabelColor)

        manualImageView.image = Aerial.getSymbol("clock")?.tinting(with: .secondaryLabelColor)

        lightModeImageView.image = Aerial.getSymbol("gear")?.tinting(with: .secondaryLabelColor)

        noAdaptImageView.image = Aerial.getSymbol("xmark.circle")?.tinting(with: .secondaryLabelColor)
        updateTimeView()

        switch PrefsTime.sunEventWindow {
        case 60*60:
            sunsetWindowPopup.selectItem(at: 0)
        case 60*90:
            sunsetWindowPopup.selectItem(at: 1)
        case 60*120:
            sunsetWindowPopup.selectItem(at: 2)
        case 60*150:
            sunsetWindowPopup.selectItem(at: 3)
        case 60*180:
            sunsetWindowPopup.selectItem(at: 4)
        case 60*210:
            sunsetWindowPopup.selectItem(at: 5)
        default:
            sunsetWindowPopup.selectItem(at: 6)
        }
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
        let (isLDMCapable, reason: _) = DarkMode.isAvailable()
        if !isLDMCapable {
            timeLightDarkModeRadio.isEnabled = false
        }
    }

    func setupNightShift() {
        // Night Shift requires 10.12.4+ and a compatible Mac
        let (isNSCapable, reason: NSReason) = NightShift.isAvailable()
        if !isNSCapable {
            timeNightShiftRadio.isEnabled = false
        }
        nightShiftLabel.stringValue = NSReason
    }

    @IBAction func sunsetSunriseWindowChange(_ sender: NSPopUpButton) {
        PrefsTime.sunEventWindow = 60 * ((2 + sender.indexOfSelectedItem) * 30)

        updateTimeView()
    }

    func updateTimeView() {
        switch PrefsTime.timeMode {
        case .disabled:
            timeBarView.isHidden = true
            return
        case .lightDarkMode:
            timeBarView.isHidden = true
            return
        case .nightShift:
            timeBarView.isHidden = false
        case .manual:
            timeBarView.isHidden = false
        case .coordinates:
            timeBarView.isHidden = true
            return
        case .locationService:
            timeBarView.isHidden = false
            _ = TimeManagement.sharedInstance.calculateFromCoordinates()
        }

        let (sunrise, sunset) = TimeManagement.sharedInstance.getSunriseSunset()

        if let lsunrise = sunrise, let lsunset = sunset {
            let esunrise = lsunrise.addingTimeInterval(TimeInterval(PrefsTime.sunEventWindow))
            let psunset = lsunset.addingTimeInterval(TimeInterval(-PrefsTime.sunEventWindow))

            oSunrise.stringValue = timeFormatter.string(from: lsunrise)
            oSunrise.sizeToFit()
            eSunrise.stringValue = timeFormatter.string(from: esunrise)
            eSunrise.sizeToFit()
            eSunset.stringValue = timeFormatter.string(from: psunset)
            eSunset.sizeToFit()
            oSunset.stringValue = timeFormatter.string(from: lsunset)
            oSunset.sizeToFit()
        }
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
        case timeLocationRadio:
            PrefsTime.timeMode = .locationService
        default:
            ()
        }
        updateTimeView()
    }

    @IBAction func sunriseChange(_ sender: NSDatePicker?) {
        guard let date = sender?.dateValue else { return }
        PrefsTime.manualSunrise = timeFormatter.string(from: date)
        updateTimeView()
    }

    @IBAction func sunsetChange(_ sender: NSDatePicker?) {
        guard let date = sender?.dateValue else { return }
        PrefsTime.manualSunset = timeFormatter.string(from: date)
        updateTimeView()
    }

    @IBAction func darkModeNightOverrideClick(_ sender: NSButton) {
        PrefsTime.darkModeNightOverride = sender.state == .on
    }

    @IBAction func testLocationClick(_ sender: Any) {
        // Get the location
        let location = Locations.sharedInstance

        location.getCoordinates(failure: { (_) in
            // swiftlint:disable:next line_length
            Aerial.showInfoAlert(title: "Could not get your location", text: "Make sure you enabled location services on your Mac (and Wi-Fi!), and that Aerial (or legacyScreenSaver on macOS 10.15 and later) is allowed to use your location.", button1: "OK", caution: true)
        }, success: { (coordinates) in
            let lat = String(format: "%.2f", coordinates.latitude)
            let lon = String(format: "%.2f", coordinates.longitude)

            Aerial.showInfoAlert(title: "Success", text: "Aerial can access your location (latitude: \(lat), longitude: \(lon)) and will use it to show you the correct videos.")

            self.updateTimeView()
        })
    }
}
