//
//  InfoWeatherView.swift
//  Aerial
//
//  Created by Guillaume Louel on 25/03/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoWeatherView: NSView {
    @IBOutlet var locationMode: NSPopUpButton!
    @IBOutlet var locationString: NSTextField!
    @IBOutlet var degreePopup: NSPopUpButton!
    @IBOutlet var iconsPopup: NSPopUpButton!
    @IBOutlet var locationLabel: NSTextField!
    @IBOutlet var weatherModePopup: NSPopUpButton!

    // Init(ish)
    func setStates() {
        locationMode.selectItem(at: PrefsInfo.weather.locationMode.rawValue)
        degreePopup.selectItem(at: PrefsInfo.weather.degree.rawValue)
        iconsPopup.selectItem(at: PrefsInfo.weather.icons.rawValue)
        weatherModePopup.selectItem(at: PrefsInfo.weather.mode.rawValue)

        // Hide the flat color icons pre Big Sur as those are not available
        if #available(macOS 11.0, *) {
        } else {
            iconsPopup.item(at: 1)?.isHidden = true
        }
        locationString.stringValue = PrefsInfo.weather.locationString
        locationLabel.stringValue = ""
        locationString.delegate = self
        updateLocationMode()
    }

    @IBAction func weatherModePopupChange(_ sender: NSPopUpButton) {
        PrefsInfo.weather.mode = InfoWeatherMode(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func locationModeChange(_ sender: NSPopUpButton) {
        PrefsInfo.weather.locationMode = InfoLocationMode(rawValue: sender.indexOfSelectedItem)!
        updateLocationMode()
    }

    func updateLocationMode() {
        if PrefsInfo.weather.locationMode == .manuallySpecify {
            locationString.isHidden = false
            locationLabel.isHidden = true
        } else {
            locationString.isHidden = true
            locationLabel.isHidden = false
        }
    }

    @IBAction func iconsChange(_ sender: NSPopUpButton) {
        PrefsInfo.weather.icons = InfoIconsWeather(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func degreePopupChange(_ sender: NSPopUpButton) {
        PrefsInfo.weather.degree = InfoDegree(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func locationStringChange(_ sender: NSTextField) {
        PrefsInfo.weather.locationString = sender.stringValue
    }

    @IBAction func testLocationButtonClick(_ sender: NSButton) {
        if PrefsInfo.weather.mode == .current {
            OpenWeather.fetch { result in
                switch result {
                case .success(let openWeather):
                    print(openWeather)
                    let ovc = self.parentViewController as! OverlaysViewController
                    ovc.openWeatherPreview(weather: openWeather)
                    //self.locationLabel.stringValue = "lat: " + openWeather.lat + "lon: " + openWeather.lon + " timezone: " + openWeather.timezone
                    if let name = openWeather.name {
                        self.locationLabel.stringValue = name
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.locationLabel.stringValue = error.localizedDescription
                }
            }
        } else {
            OneCall.fetch { result in
                switch result {
                case .success(let openWeather):
                    print(openWeather)
                    let ovc = self.parentViewController as! OverlaysViewController
                    ovc.openWeatherPreview(weather: openWeather)

                    if let lat = openWeather.lat, let lon = openWeather.lon, let timezone = openWeather.timezone {
                        self.locationLabel.stringValue = "lat: " + String(format: "%.2f", lat)
                            + " lon: " + String(format: "%.2f", lon)
                            + " timezone: " + timezone
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.locationLabel.stringValue = error.localizedDescription
                }
            }
        }
    }

    @IBAction func openWeatherLogoButton(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://openweathermap.org/")!)
    }
}

extension InfoWeatherView: NSTextFieldDelegate {
    // We need the delegate to intercept changes without the
    // enter key being pressed on the textfield
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        // Just in case...
        if textField == locationString {
            //print(textField.stringValue)
            PrefsInfo.weather.locationString = textField.stringValue
        }
    }
}

extension NSView {
    var parentViewController: NSViewController? {
        sequence(first: self) { $0.nextResponder }
            .first(where: { $0 is NSViewController })
            .flatMap { $0 as? NSViewController }
    }
}
