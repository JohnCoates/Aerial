//
//  TimeSetupViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 12/08/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class TimeSetupViewController: NSViewController {
    @IBOutlet var imageSunrise: NSImageView!
    @IBOutlet var imageDay: NSImageView!
    @IBOutlet var imageSunset: NSImageView!
    @IBOutlet var imageNight: NSImageView!

    @IBOutlet var imageLocation: NSImageView!
    @IBOutlet var imageClock: NSImageView!
    @IBOutlet var imageXmark: NSImageView!

    @IBOutlet var locationServicesLink: NSButton!

    @IBOutlet var choice1: NSButton!
    @IBOutlet var choice2: NSButton!
    @IBOutlet var choice3: NSButton!
    @IBOutlet var sunriseTime: NSDatePicker!

    @IBOutlet var sunsetTime: NSDatePicker!

    @IBOutlet var locationLabel: NSTextField!

    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        imageSunrise.image = Aerial.getSymbol("sunrise")?.tinting(with: .secondaryLabelColor)
        imageDay.image = Aerial.getSymbol("sun.max")?.tinting(with: .secondaryLabelColor)
        imageSunset.image = Aerial.getSymbol("sunset")?.tinting(with: .secondaryLabelColor)
        imageNight.image = Aerial.getSymbol("moon.stars")?.tinting(with: .secondaryLabelColor)

        imageLocation.image = Aerial.getSymbol("mappin.and.ellipse")?.tinting(with: .secondaryLabelColor)
        imageClock.image = Aerial.getSymbol("clock")?.tinting(with: .secondaryLabelColor)
        imageXmark.image = Aerial.getSymbol("xmark.circle")?.tinting(with: .secondaryLabelColor)

        if let dateSunrise = timeFormatter.date(from: PrefsTime.manualSunrise) {
            sunriseTime.dateValue = dateSunrise
        }
        if let dateSunset = timeFormatter.date(from: PrefsTime.manualSunset) {
            sunsetTime.dateValue = dateSunset
        }

        if #available(OSX 10.15, *) {
            locationServicesLink.isHidden = true
        }

        locationLabel.stringValue = ""
        PrefsTime.timeMode = .disabled
    }

    @IBAction func choiceChange(_ sender: NSButton) {
        switch sender {
        case choice1:
            PrefsTime.timeMode = .locationService
            checkLocation()
        case choice2:
            PrefsTime.timeMode = .manual

            PrefsTime.manualSunrise = timeFormatter.string(from: sunriseTime.dateValue)
            PrefsTime.manualSunset = timeFormatter.string(from: sunsetTime.dateValue)

        default:
            PrefsTime.timeMode = .disabled
        }
    }

    func checkLocation() {
        // Get the location
        let location = Locations.sharedInstance
        locationLabel.stringValue = "Checking your location..."
        location.getCoordinates(failure: { (_) in
            // swiftlint:disable:next line_length
            Aerial.showInfoAlert(title: "Could not get your location", text: "Make sure you enabled location services on your Mac, and that Aerial (or legacyScreenSaver on macOS 10.15 and later) is allowed to use your location.", button1: "OK", caution: true)
            self.locationLabel.stringValue = "Check your Location Services settings on your mac"

        }, success: { (_) in
            // let lat = String(format: "%.2f", coordinates.latitude)
            // let lon = String(format: "%.2f", coordinates.longitude)

            _ = TimeManagement.sharedInstance.calculateFromCoordinates()
            let (sunrise, sunset) = TimeManagement.sharedInstance.getSunriseSunsetForMode(.official)

            if let vSunrise = sunrise, let vSunset = sunset {
                self.locationLabel.stringValue = "Next Sunrise : \(self.timeFormatter.string(from: vSunrise)) Next Sunset: \(self.timeFormatter.string(from: vSunset))"
            } else {
                self.locationLabel.stringValue = "Cannot calculate sunset and sunrise"
            }
        })
    }

    @IBAction func locationServicesClick(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/blob/master/Documentation/Troubleshooting.md#issues-on-macos-1014-and-earlier")!
        workspace.open(url)
    }

}
