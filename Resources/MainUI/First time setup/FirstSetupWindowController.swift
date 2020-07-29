//
//  FirstSetupWindowController.swift
//  Aerial
//
//  Created by Guillaume Louel on 29/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

enum Actions {
    case welcome, videoFormat, cache
}

class FirstSetupWindowController: NSWindowController {
    var welcomeViewItem: NSSplitViewItem?
    var nextViewItem: NSSplitViewItem?

    lazy var splitVC = NSSplitViewController()
    override func windowDidLoad() {
        super.windowDidLoad()

        print("*** fswc vdl")
        // We always need to specify a bundle manually, auto loading from bundle
        // does not work for screen savers when compiled as plugins
        let bundle = Bundle(for: PanelWindowController.self)

        let welcomeVC = WelcomeViewController(nibName: .init("WelcomeViewController"), bundle: bundle)

        let nextVC = NextViewController(nibName: .init("NextViewController"), bundle: bundle)
        nextVC.windowController = self

        welcomeViewItem = NSSplitViewItem(viewController: welcomeVC)
        nextViewItem = NSSplitViewItem(viewController: nextVC)

        splitVC.addSplitViewItem(welcomeViewItem!)
        splitVC.addSplitViewItem(nextViewItem!)
        window?.contentViewController = splitVC
    }

    func nextAction() {

    }
}
