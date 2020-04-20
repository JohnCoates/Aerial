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

    // Init(ish)
    func setStates() {
        locationMode.selectItem(at: PrefsInfo.weather.locationMode.rawValue)
        degreePopup.selectItem(at: PrefsInfo.weather.degree.rawValue)

        locationString.stringValue = PrefsInfo.weather.locationString
    }

    @IBAction func locationModeChange(_ sender: NSPopUpButton) {
        PrefsInfo.weather.locationMode = InfoLocationMode(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func degreePopupChange(_ sender: NSPopUpButton) {
        PrefsInfo.weather.degree = InfoDegree(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func locationStringChange(_ sender: NSTextField) {
        PrefsInfo.weather.locationString = sender.stringValue
    }

    @IBAction func testLocationButtonClick(_ sender: NSButton) {
        Weather.fetch(failure: { (error) in
            print(error.localizedDescription)
        }, success: { (_) in
            let pwc = self.window!.windowController as! PreferencesWindowController
            pwc.openWeatherPreview()
        })
    }

    @IBAction func yahooWeatherButtonClick(_ sender: Any) {
        // Logo must link here, per Yahoo!'s attribution guidelines
        NSWorkspace.shared.open(URL(string: "https://www.yahoo.com/?ilc=401")!)
    }
}
