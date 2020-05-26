//
//  PWC+Info.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

extension PreferencesWindowController {

    func setupInfoTab() {
        // This may be a temp workaround, will depend on where it goes
        // We periodically add new types so we must add them
        if !PrefsInfo.layers.contains(.battery) {
            PrefsInfo.layers.append(.battery)
        }

        if !PrefsInfo.layers.contains(.countdown) {
            PrefsInfo.layers.append(.countdown)
        }

        if !PrefsInfo.layers.contains(.timer) {
            PrefsInfo.layers.append(.timer)
        }

        if !PrefsInfo.layers.contains(.date) {
            PrefsInfo.layers.append(.date)
        }

        if !PrefsInfo.layers.contains(.weather) {
            PrefsInfo.layers.append(.weather)
        }

        // Annnd for backward compatibility with 1.7.2 betas, remove the updates that was once here ;)
        if PrefsInfo.layers.contains(.updates) {
            PrefsInfo.layers.remove(at: PrefsInfo.layers.firstIndex(of: .updates)!)
        }

        infoSource = InfoTableSource()
        infoSource?.setController(self)
        infoTableView.dataSource = infoSource
        infoTableView.delegate = infoSource
        infoTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "private.table-row")])

        infoSettingsSource = InfoSettingsTableSource()
        infoSettingsSource?.setController(self)
        infoSettingsTableView.dataSource = infoSettingsSource
        infoSettingsTableView.delegate = infoSettingsSource
    }

    func drawInfoSettingsPanel() {
        resetInfoPanel()

        // Add the common block of features (enabled, font, position, screen)
        infoContainerView.addSubview(infoSettingsView)
        infoBox.title = "Advanced text settings"
        infoSettingsView.setStates()
    }

    // We dynamically change the content here, based on what's selected
    func drawInfoPanel(forType: InfoType) {
        resetInfoPanel()

        // Add the common block of features (enabled, font, position, screen)
        infoContainerView.addSubview(infoCommonView)
        infoCommonView.setType(forType, controller: self)

        // Then the per-type blocks if any
        switch forType {
        case .location:
            infoContainerView.addSubview(infoLocationView)
            infoLocationView.frame.origin.y = infoCommonView.frame.height
            infoLocationView.setStates()
        case .message:
            infoContainerView.addSubview(infoMessageView)
            infoMessageView.frame.origin.y = infoCommonView.frame.height
            infoMessageView.setStates()
        case .clock:
            infoContainerView.addSubview(infoClockView)
            infoClockView.frame.origin.y = infoCommonView.frame.height
            infoClockView.setStates()
        case .date:
            infoContainerView.addSubview(infoDateView)
            infoDateView.frame.origin.y = infoCommonView.frame.height
            infoDateView.setStates()
        case .battery:
            infoContainerView.addSubview(infoBatteryView)
            infoBatteryView.frame.origin.y = infoCommonView.frame.height
            infoBatteryView.setStates()
        case .updates:
            break
        case .weather:
            infoContainerView.addSubview(infoWeatherView)
            infoWeatherView.frame.origin.y = infoCommonView.frame.height
            infoWeatherView.setStates()
        case .countdown:
            infoContainerView.addSubview(infoCountdownView)
            infoCountdownView.frame.origin.y = infoCommonView.frame.height
            infoCountdownView.setStates()
        case .timer:
            infoContainerView.addSubview(infoTimerView)
            infoTimerView.frame.origin.y = infoCommonView.frame.height
            infoTimerView.setStates()
        }
    }

    // Clear the panel
    func resetInfoPanel() {
        infoContainerView.subviews.forEach({ $0.removeFromSuperview() })
    }

    func openWeatherPreview() {
        if !weatherPanel.isVisible {
            weatherPanel.makeKeyAndOrderFront(self)
        }

        if Weather.info != nil {
            weatherLabel.stringValue = "\(Weather.info!.location) \n\n \(Weather.info!.currentObservation)"
            let cond = ConditionLayer(condition: Weather.info!.currentObservation.condition)

            weatherCustomView.layer = cond
            weatherCustomView.wantsLayer = true
        } else {
            weatherLabel.stringValue = "City not found, please try again"
        }
    }

    @IBAction func helpWeatherButtonClick(_ button: NSButton) {
        popoverWeather.show(relativeTo: button.preparedContentRect, of: button, preferredEdge: .maxY)
    }
}
