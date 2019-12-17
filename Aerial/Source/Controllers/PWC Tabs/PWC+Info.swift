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

    // We dynamically change the content here based on what's selected
    func drawInfoPanel(forType: InfoType) {
        print("should redraw : \(forType.rawValue)")
        resetInfoPanel()

        // Add the top description label
        switch forType {
        case .location:
            infoContainerView.addSubview(infoLocationView)
        case .message:
            infoContainerView.addSubview(infoMessageView)
        case .clock:
            infoContainerView.addSubview(infoClockView)
        }

        // Add the common block of features (enabled, font, position, screen)
        infoContainerView.addSubview(infoCommonView)
        infoCommonView.frame.origin.y = 30
        infoCommonView.setType(forType)

        // 
    }

    func resetInfoPanel() {
        print("should reset")
        infoContainerView.subviews.forEach({ $0.removeFromSuperview() })
        //infoContainerView
    }
}
