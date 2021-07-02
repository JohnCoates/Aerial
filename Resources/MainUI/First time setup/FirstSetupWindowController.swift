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

class FirstSetupWindowController: NSWindowController, NSWindowDelegate {
    var welcomeViewItem: NSSplitViewItem?
    var videoFormatViewItem: NSSplitViewItem?
    var cacheSetupViewItem: NSSplitViewItem?
    var timeViewItem: NSSplitViewItem?
    var recapViewItem: NSSplitViewItem?

    var nextViewItem: NSSplitViewItem?

    lazy var splitVC = NSSplitViewController()
    var nextVC: NextViewController = {
        let bundle = Bundle(for: PanelWindowController.self)
        return NextViewController(nibName: .init("NextViewController"), bundle: bundle)
    }()

    var currentStep = 0

    override func windowDidLoad() {
        super.windowDidLoad()

        splitVC.splitView.isVertical = false
        if splitVC.splitViewItems.count == 2 {
            splitVC.removeChild(at: 0)
            splitVC.removeChild(at: 0)
        }
        // We always need to specify a bundle manually, auto loading from bundle
        // does not work for screen savers when compiled as plugins
        let bundle = Bundle(for: PanelWindowController.self)

        let welcomeVC = WelcomeViewController(nibName: .init("WelcomeViewController"), bundle: bundle)
        let videoVC = VideoFormatViewController(nibName: .init("VideoFormatViewController"), bundle: bundle)
        let cacheVC = CacheSetupViewController(nibName: .init("CacheSetupViewController"), bundle: bundle)
        let timeVC = TimeSetupViewController(nibName: .init("TimeSetupViewController"), bundle: bundle)
        let recapVC = RecapViewController(nibName: .init("RecapViewController"), bundle: bundle)

        // let nextVC = NextViewController(nibName: .init("NextViewController"), bundle: bundle)
        nextVC.windowController = self

        welcomeViewItem = NSSplitViewItem(viewController: welcomeVC)
        videoFormatViewItem = NSSplitViewItem(viewController: videoVC)
        cacheSetupViewItem = NSSplitViewItem(viewController: cacheVC)
        timeViewItem = NSSplitViewItem(viewController: timeVC)
        recapViewItem = NSSplitViewItem(viewController: recapVC)

        nextViewItem = NSSplitViewItem(viewController: nextVC)

        splitVC.addSplitViewItem(welcomeViewItem!)
        splitVC.addSplitViewItem(nextViewItem!)
        window?.contentViewController = splitVC
    }

    func windowWillClose(_ notification: Notification) {
        PrefsAdvanced.firstTimeSetup = true
    }

    func nextAction() {
        currentStep += 1
        redrawVC()
    }

    func previousAction() {
        currentStep -= 1
        redrawVC()
    }

    func redrawVC() {
        splitVC.removeChild(at: 1)
        splitVC.removeChild(at: 0)

        switch currentStep {
        case 0:
            splitVC.addSplitViewItem(welcomeViewItem!)
            splitVC.addSplitViewItem(nextViewItem!)
            nextVC.setNoPrev()
        case 1:
            splitVC.addSplitViewItem(videoFormatViewItem!)
            splitVC.addSplitViewItem(nextViewItem!)
            nextVC.setPrevNext()
        case 2:
            splitVC.addSplitViewItem(cacheSetupViewItem!)
            splitVC.addSplitViewItem(nextViewItem!)
            nextVC.setPrevNext()
        case 3:
            splitVC.addSplitViewItem(timeViewItem!)
            splitVC.addSplitViewItem(nextViewItem!)
            nextVC.setPrevNext()
        case 4:
            splitVC.addSplitViewItem(recapViewItem!)
            splitVC.addSplitViewItem(nextViewItem!)
            nextVC.setClose()
        default:
            window?.close()
            PrefsAdvanced.firstTimeSetup = true
        }
    }
}
