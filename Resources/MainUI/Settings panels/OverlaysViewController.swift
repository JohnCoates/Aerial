//
//  OverlaysViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 19/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class OverlaysViewController: NSViewController {
    @IBOutlet var popoverWeather: NSPopover!
    @IBOutlet var infoTableView: NSTableView!
    @IBOutlet var infoSettingsTableView: NSTableView!
    //@IBOutlet var infoBox: NSBox!
    //@IBOutlet var infoContainerView: InfoContainerView!

    
    @IBOutlet var infoScrollView: NSScrollView!
    @IBOutlet var infoScrollableView: InfoContainerView!
    
    // Then all the individual views
    @IBOutlet var infoSettingsView: InfoSettingsView!
    @IBOutlet var infoCommonView: InfoCommonView!

    @IBOutlet var infoLocationView: InfoLocationView!
    @IBOutlet var infoClockView: InfoClockView!
    @IBOutlet var infoMessageView: InfoMessageView!

    // Message sub panels
    @IBOutlet var infoMessageTextView: NSView!
    @IBOutlet var infoMessageShellView: NSView!
    @IBOutlet var infoMessageTextFileView: NSView!

    @IBOutlet var infoBatteryView: InfoBatteryView!
    @IBOutlet var infoCountdownView: InfoCountdownView!
    @IBOutlet var infoTimerView: InfoTimerView!
    @IBOutlet var infoDateView: InfoDateView!
    @IBOutlet var infoWeatherView: InfoWeatherView!

    @IBOutlet var infoMusicView: InfoMusicView!
    @IBOutlet var fontButton: NSButton!
    @IBOutlet var trashButton: NSButton!

    // And our weather panel
    @IBOutlet var weatherPanel: NSPanel!
    @IBOutlet var weatherCustomView: NSView!
    @IBOutlet var weatherLabel: NSTextField!

    var infoSource = InfoTableSource()
    var infoSettingsSource = InfoSettingsTableSource()

    var currentSubMessage: NSView?

    override func viewDidLoad() {
        super.viewDidLoad()
        PrefsInfo.updateLayerList()

        // Do view setup here.
        fontButton.setIcons("textformat.alt")
        trashButton.setIcons("trash")
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
        infoScrollableView.addSubview(infoSettingsView)

        //infoContainerView.addSubview(infoSettingsView)
        //infoBox.title = "Advanced text settings"
        infoSettingsView.setStates()
    }

    // We dynamically change the content here, based on what's selected
    func drawInfoPanel(forType: InfoType) {
        resetInfoPanel()

        // Add the common block of features (enabled, font, position, screen)
        infoScrollableView.addSubview(infoCommonView)
        //infoContainerView.addSubview(infoCommonView)
        infoCommonView.setType(forType, controller: self)
        infoScrollableView.setFrameSize(NSSize(width: infoScrollableView.frame.width, height: 800))

        infoCommonView.frame.origin.y = 0

        //infoScrollView.documentView?.scroll(.zero)

        
        // Then the per-type blocks if any
        switch forType {
        case .location:
            infoScrollableView.addSubview(infoLocationView)
            infoLocationView.frame.origin.y = infoCommonView.frame.height
            infoLocationView.setStates()
            
            //infoScrollableView.setFrameSize(NSSize(width: infoScrollableView.frame.width, height: infoCommonView.frame.height + infoLocationView.frame.height))
        case .message:
            infoScrollableView.addSubview(infoMessageView)
            infoMessageView.frame.origin.y = infoCommonView.frame.height
            addSubMessagePanel()
            infoMessageView.setStates()
            //infoScrollableView.setFrameSize(NSSize(width: infoScrollableView.frame.width, height: infoCommonView.frame.height + infoLocationView.frame.height))
        case .clock:
            infoScrollableView.addSubview(infoClockView)
            infoClockView.frame.origin.y = infoCommonView.frame.height
            infoClockView.setStates()
            //infoScrollableView.setFrameSize(NSSize(width: infoScrollableView.frame.width, height: infoCommonView.frame.height + infoClockView.frame.height))
        case .date:
            infoScrollableView.addSubview(infoDateView)
            infoDateView.frame.origin.y = infoCommonView.frame.height
            infoDateView.setStates()
            //infoScrollableView.setFrameSize(NSSize(width: infoScrollableView.frame.width, height: infoCommonView.frame.height + infoDateView.frame.height))
        case .battery:
            infoScrollableView.addSubview(infoBatteryView)
            infoBatteryView.frame.origin.y = infoCommonView.frame.height
            infoBatteryView.setStates()
            //infoScrollableView.setFrameSize(NSSize(width: infoScrollableView.frame.width, height: infoCommonView.frame.height + infoBatteryView.frame.height))
        case .updates:
            break
        case .weather:
            infoScrollableView.addSubview(infoWeatherView)
            infoWeatherView.frame.origin.y = infoCommonView.frame.height
            infoWeatherView.setStates()
            //infoScrollableView.setFrameSize(NSSize(width: infoScrollableView.frame.width, height: infoCommonView.frame.height + infoWeatherView.frame.height))
        case .countdown:
            infoScrollableView.addSubview(infoCountdownView)
            infoCountdownView.frame.origin.y = infoCommonView.frame.height
            infoCountdownView.setStates()
            //infoScrollableView.setFrameSize(NSSize(width: infoScrollableView.frame.width, height: infoCommonView.frame.height + infoCountdownView.frame.height))
        case .timer:
            infoScrollableView.addSubview(infoTimerView)
            infoTimerView.frame.origin.y = infoCommonView.frame.height
            infoTimerView.setStates()
            //infoScrollableView.setFrameSize(NSSize(width: infoScrollableView.frame.width, height: infoCommonView.frame.height + infoTimerView.frame.height))
        case .music:
            infoScrollableView.addSubview(infoMusicView)
            infoMusicView.frame.origin.y = infoCommonView.frame.height
            infoMusicView.setStates()
            //infoScrollableView.setFrameSize(NSSize(width: infoScrollableView.frame.width, height: infoCommonView.frame.height + infoMusicView.frame.height))
        }
        
        infoScrollView.documentView?.scroll(.zero)

    }

    func addSubMessagePanel() {
        switch PrefsInfo.message.messageType {
        case .text:
            infoScrollableView.addSubview(infoMessageTextView)
            infoMessageTextView.frame.origin.y = infoCommonView.frame.height + infoMessageView.frame.height
            currentSubMessage = infoMessageTextView
        case .shell:
            infoScrollableView.addSubview(infoMessageShellView)
            infoMessageShellView.frame.origin.y = infoCommonView.frame.height + infoMessageView.frame.height
            currentSubMessage = infoMessageShellView
        case .textfile:
            infoScrollableView.addSubview(infoMessageTextFileView)
            infoMessageTextFileView.frame.origin.y = infoCommonView.frame.height + infoMessageView.frame.height
            currentSubMessage = infoMessageTextFileView
        }

        infoMessageTextView.frame.origin.y = infoCommonView.frame.height + infoMessageView.frame.height
    }

    // We call this when we switch from one mode  to another
    public func switchSubMessagePanel() {
        if let cMessage = currentSubMessage {
            cMessage.removeFromSuperview()
        }

        addSubMessagePanel()
    }

    // Clear the panel
    func resetInfoPanel() {
        infoScrollableView.subviews.forEach({ $0.removeFromSuperview() })
    }

    // MARK: Weather panel
    // Simple current conditions
    func openWeatherPreview(weather: OWeather) {
        if !weatherPanel.isVisible {
            weatherPanel.makeKeyAndOrderFront(self)
        }

        weatherLabel.stringValue = "\(String(describing: weather.name)) \n\n \(weather)"
        let cond = ConditionLayer(condition: weather, scale: 2.0)

        weatherCustomView.layer = cond
        weatherCustomView.wantsLayer = true
    }

    // Forecasts
    func openWeatherPreview(weather: ForecastElement) {
        if !weatherPanel.isVisible {
            weatherPanel.makeKeyAndOrderFront(self)
        }

        weatherLabel.stringValue = "\(weather)"
        let cond = ForecastLayer(condition: weather, scale: 2.0)

        weatherCustomView.layer = cond
        weatherCustomView.wantsLayer = true
    }

    @IBAction func helpWeatherButtonClick(_ button: NSButton) {
        popoverWeather.show(relativeTo: button.preparedContentRect, of: button, preferredEdge: .maxY)
    }
}
