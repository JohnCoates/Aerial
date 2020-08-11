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
    var videoFormatViewItem: NSSplitViewItem?

    var nextViewItem: NSSplitViewItem?

    lazy var splitVC = NSSplitViewController()

    var currentStep = 0

    override func windowDidLoad() {
        super.windowDidLoad()

        splitVC.splitView.isVertical = false
        print("*** fswc vdl")
        // We always need to specify a bundle manually, auto loading from bundle
        // does not work for screen savers when compiled as plugins
        let bundle = Bundle(for: PanelWindowController.self)

        let welcomeVC = WelcomeViewController(nibName: .init("WelcomeViewController"), bundle: bundle)
        let videoVC = VideoFormatViewController(nibName: .init("VideoFormatViewController"), bundle: bundle)

        let nextVC = NextViewController(nibName: .init("NextViewController"), bundle: bundle)
        nextVC.windowController = self

        welcomeViewItem = NSSplitViewItem(viewController: welcomeVC)
        videoFormatViewItem = NSSplitViewItem(viewController: videoVC)
        nextViewItem = NSSplitViewItem(viewController: nextVC)

        splitVC.addSplitViewItem(welcomeViewItem!)
        splitVC.addSplitViewItem(nextViewItem!)
        window?.contentViewController = splitVC
    }

    func nextAction() {
        currentStep += 1
        splitVC.removeChild(at: 1)
        splitVC.removeChild(at: 0)

        switch currentStep {
        case 1:
            splitVC.addSplitViewItem(videoFormatViewItem!)
            splitVC.addSplitViewItem(nextViewItem!)
        default:
            window?.close()
        }
    }
}
