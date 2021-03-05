//
//  AppDelegate.swift
//  Aerial Test
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // So this is where we come in, when compiled as an Application
    override init() {
        super.init()

        // First thing : let our model know we are an app and not a screensaver !
        Aerial.appMode = true

        let panelWindowController = PanelWindowController()
        panelWindowController.showWindow(self)
        panelWindowController.window?.makeKeyAndOrderFront(nil)
    }
}
