//
//  OverlaysViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 19/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class OverlaysViewController: NSViewController {
    @IBOutlet var infoTableView: NSTableView!
    @IBOutlet var infoSettingsTableView: NSTableView!
    @IBOutlet var infoBox: NSBox!
    @IBOutlet var infoContainerView: InfoContainerView!

    // Then all the individual views
    @IBOutlet var infoSettingsView: InfoSettingsView!
    @IBOutlet var infoCommonView: InfoCommonView!

    @IBOutlet var infoLocationView: InfoLocationView!
    @IBOutlet var infoClockView: InfoClockView!
    @IBOutlet var infoMessageView: InfoMessageView!
    @IBOutlet var infoBatteryView: InfoBatteryView!
    @IBOutlet var infoCountdownView: InfoCountdownView!
    @IBOutlet var infoTimerView: InfoTimerView!
    @IBOutlet var infoDateView: InfoDateView!
    @IBOutlet var infoWeatherView: InfoWeatherView!

    // And our weather panel

    @IBOutlet var weatherPanel: NSPanel!
    @IBOutlet var weatherCustomView: NSView!
    @IBOutlet var weatherLabel: NSTextField!

    var infoSource = InfoTableSource()
    var infoSettingsSource = InfoSettingsTableSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        infoSource.setController(self)
        infoTableView.dataSource = infoSource
        infoTableView.delegate = infoSource
        infoTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "private.table-row")])

        infoSettingsSource.setController(self)
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

    // MARK: Weather panel

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

    /*
    @IBAction func helpWeatherButtonClick(_ button: NSButton) {
        popoverWeather.show(relativeTo: button.preparedContentRect, of: button, preferredEdge: .maxY)
    }*/
}
