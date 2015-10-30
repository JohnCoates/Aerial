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
    var preferencesWindowController:PreferencesWindowController = PreferencesWindowController()

    var topLevelObjects:NSArray?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let bundle = NSBundle.mainBundle()
        bundle.loadNibNamed("PreferencesWindow", owner: preferencesWindowController, topLevelObjects: &topLevelObjects);
        
        NSLog("objects: \(topLevelObjects)");
        
        for object in topLevelObjects! {
            if let prefWindow = object as? NSWindow {
                //            window.contentView?.addSubview(prefWindow.contentView!);
                NSLog("making key window!");
                prefWindow.makeKeyAndOrderFront(self);
                prefWindow.styleMask = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask;
                var frame = prefWindow.frame;
                frame.origin = window.frame.origin
                prefWindow.setFrame(frame, display: true);
                window.orderOut(self);
            }
        }
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }
}

