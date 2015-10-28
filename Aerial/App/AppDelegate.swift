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

    @IBOutlet weak var window: NSWindow!
    @IBOutlet var preferencesWindowController:PreferencesWindowController!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        debugLog("app launched");
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

