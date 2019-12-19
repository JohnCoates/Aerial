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
        print("info source")
        infoSource = InfoTableSource()
        infoSource?.setController(self)
        infoTableView.dataSource = infoSource
        infoTableView.delegate = infoSource
        infoTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "private.table-row")])
    }

    // We dynamically change the content here, based on what's selected
    func drawInfoPanel(forType: InfoType) {
        print("should redraw : \(forType.rawValue)")
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
        }
    }

    // Clear the panel
    func resetInfoPanel() {
        infoContainerView.subviews.forEach({ $0.removeFromSuperview() })
    }
}
