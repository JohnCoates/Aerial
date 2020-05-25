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

    // Init(ish)
    func setStates() {
        locationMode.selectItem(at: PrefsInfo.weather.locationMode.rawValue)
        degreePopup.selectItem(at: PrefsInfo.weather.degree.rawValue)
        iconsPopup.selectItem(at: PrefsInfo.weather.icons.rawValue)

        locationString.stringValue = PrefsInfo.weather.locationString
        locationLabel.stringValue = ""
        locationString.delegate = self
        updateLocationMode()
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

            /*
            if PrefsInfo.weather.locationCoords != "" {
                locationLabel.stringValue = PrefsInfo.weather.locationCoords
            } else {
                locationLabel.stringValue = "No cached location"
            }*/
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
        if PrefsInfo.weather.locationMode == .manuallySpecify {
            Weather.fetch(failure: { (error) in
                print(error.localizedDescription)
            }, success: { (_) in
                let pwc = self.window!.windowController as! PreferencesWindowController
                pwc.openWeatherPreview()
            })
        } else {
            // Get the location
            let location = Locations.sharedInstance

            location.getCoordinates(failure: { (error) in
                self.locationLabel.stringValue = error
            }, success: { (coordinates) in
                let lat = String(format: "%.2f", coordinates.latitude)
                let lon = String(format: "%.2f", coordinates.longitude)
                self.locationLabel.stringValue = "Latiture: \(lat) Longitude: \(lon)"

                Weather.fetch(failure: { (error) in
                    print(error.localizedDescription)
                }, success: { (_) in
                    let pwc = self.window!.windowController as! PreferencesWindowController
                    pwc.openWeatherPreview()
                })
            })
        }
    }

    @IBAction func yahooWeatherButtonClick(_ sender: Any) {
        // Logo must link here, per Yahoo!'s attribution guidelines
        NSWorkspace.shared.open(URL(string: "https://www.yahoo.com/?ilc=401")!)
    }
}

extension InfoWeatherView: NSTextFieldDelegate {
    // We need the delegate to intercept changes without the
    // enter key being pressed on the textfield
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        // Just in case...
        if textField == locationString {
            print(textField.stringValue)
            PrefsInfo.weather.locationString = textField.stringValue
        }
    }
}
