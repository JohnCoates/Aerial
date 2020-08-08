//
//  PanelWindowController.swift
//  Aerial
//
//  Created by Guillaume Louel on 15/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class PanelWindowController: NSWindowController {
    var firstSetupWindowController: FirstSetupWindowController?

    var splitVC: NSSplitViewController?
    var videosVC: VideosViewController?

    var videoViewItem: NSSplitViewItem?             // Main video view
    // Infos
    var infoViewItem: NSSplitViewItem?
    var creditsViewItem: NSSplitViewItem?
    var helpViewItem: NSSplitViewItem?

    // Settings
    var sourcesViewItem: NSSplitViewItem?
    var timeViewItem: NSSplitViewItem?
    var displaysViewItem: NSSplitViewItem?
    var brightnessViewItem: NSSplitViewItem?
    var cacheViewItem: NSSplitViewItem?
    var overlaysViewItem: NSSplitViewItem?
    var filtersViewItem: NSSplitViewItem?
    var updatesViewItem: NSSplitViewItem?
    var advancedViewItem: NSSplitViewItem?

    var currentPath: String?

    convenience init() {
        self.init(windowNibName: "PanelWindowController")
    }

    override func windowDidLoad() {
        debugLog("PWC2 wdl: Aerial version \(Aerial.version)")
        super.windowDidLoad()
        currentPath = "location:all"

        splitVC = NSSplitViewController()   // This is the core of ui V2, we dynamically change the right view controller based on what's on the left

        // We always need to specify a bundle manually, auto loading from bundle
        // does not work for screen savers when compiled as plugins
        let bundle = Bundle(for: PanelWindowController.self)

        videosVC = VideosViewController(nibName: .init("VideosViewController"), bundle: bundle)

        // Infos
        let infoVC = InfoViewController(nibName: .init("InfoViewController"), bundle: bundle)
        let creditsVC = CreditsViewController(nibName: .init("CreditsViewController"), bundle: bundle)
        let helpVC = HelpViewController(nibName: .init("HelpViewController"), bundle: bundle)

        // Various settings
        let sourcesVC = SourcesViewController(nibName: .init("SourcesViewController"), bundle: bundle)
        let timeVC = TimeViewController(nibName: .init("TimeViewController"), bundle: bundle)
        let displaysVC = DisplaysViewController(nibName: .init("DisplaysViewController"), bundle: bundle)
        let brightnessVC = BrightnessViewController(nibName: .init("BrightnessViewController"), bundle: bundle)
        let cacheVC = CacheViewController(nibName: .init("CacheViewController"), bundle: bundle)
        let overlaysVC = OverlaysViewController(nibName: .init("OverlaysViewController"), bundle: bundle)
        let filtersVC = FiltersViewController(nibName: .init("FiltersViewController"), bundle: bundle)
        let updatesVC = UpdatesViewController(nibName: .init("UpdatesViewController"), bundle: bundle)
        let advancedVC = AdvancedViewController(nibName: .init("AdvancedViewController"), bundle: bundle)

        // We do the sidebar last, as it bubble up events to the other ones
        let sidebarVC = SidebarViewController(nibName: .init("SidebarViewController"), bundle: bundle)
        sidebarVC.windowController = self

        // Create all the view items for the right panel
        videoViewItem = NSSplitViewItem(viewController: videosVC!)
        // Infos
        infoViewItem = NSSplitViewItem(viewController: infoVC)
        creditsViewItem = NSSplitViewItem(viewController: creditsVC)
        helpViewItem = NSSplitViewItem(viewController: helpVC)
        // All the settings have individual controllers
        sourcesViewItem = NSSplitViewItem(viewController: sourcesVC)
        timeViewItem = NSSplitViewItem(viewController: timeVC)
        displaysViewItem = NSSplitViewItem(viewController: displaysVC)
        brightnessViewItem = NSSplitViewItem(viewController: brightnessVC)
        cacheViewItem = NSSplitViewItem(viewController: cacheVC)
        overlaysViewItem = NSSplitViewItem(viewController: overlaysVC)
        filtersViewItem = NSSplitViewItem(viewController: filtersVC)
        updatesViewItem = NSSplitViewItem(viewController: updatesVC)
        advancedViewItem = NSSplitViewItem(viewController: advancedVC)

        splitVC!.addSplitViewItem(NSSplitViewItem(sidebarWithViewController: sidebarVC))
        splitVC!.addSplitViewItem(videoViewItem!)

        window?.contentViewController = splitVC

        debugLog("/PWC2 wdl")
    }

    func doFirstTimeSetup() {
        if PrefsAdvanced.firstTimeSetup == false && firstSetupWindowController == nil {
            let bundle = Bundle(for: PanelWindowController.self)
            // We also load our CustomVideos nib here

            firstSetupWindowController = FirstSetupWindowController()
            var topLevelObjects: NSArray? = NSArray()
            if !bundle.loadNibNamed(NSNib.Name("FirstSetupWindowController"),
                                owner: firstSetupWindowController,
                                topLevelObjects: &topLevelObjects) {
                errorLog("Could not load nib for CustomVideos, please report")
            }
            firstSetupWindowController!.windowDidLoad()
            firstSetupWindowController!.showWindow(self)
            firstSetupWindowController!.window!.makeKeyAndOrderFront(self)
        }
    }

    // Switch from one menu list to another
    func switchFrom(_ from: SidebarMenus, to: SidebarMenus) {
        // Ugh...
        guard let splitVC = splitVC,
              let videoViewItem = videoViewItem,
              let sourcesViewItem = sourcesViewItem,
              let infoViewItem = infoViewItem,
              from != to
              else {
            return
        }

        splitVC.removeChild(at: 1)

        // Put new
        switch to {
        case .videos:
            splitVC.addSplitViewItem(videoViewItem)
        case.settings:
            splitVC.addSplitViewItem(sourcesViewItem)
        case.infos:
            splitVC.addSplitViewItem(infoViewItem)
        }
    }

    // Switch from one source to another
    func switchTo(_ path: String) {
        guard let currentPath = currentPath,
              let videosVC = videosVC,
              path != currentPath else {
            return
        }
        print("switch to : \(path)")
        if path.starts(with: "videos:") {
            let idx = path.firstIndex(of: ":")
            videosVC.reloadFor(path: String(path[idx!...].dropFirst())) // Oh Swift...
        }

        if path.starts(with: "settings:") {
            let idx = path.firstIndex(of: ":")
            switchToSettings(String(path[idx!...].dropFirst())) // Oh Swift...
        }

        if path.starts(with: "infos:") {
            let idx = path.firstIndex(of: ":")
            switchToInfos(String(path[idx!...].dropFirst())) // Oh Swift...
        }

        // Save the new path
        self.currentPath = path
    }

    func switchToSettings(_ path: String) {
        guard let splitVC = splitVC else {
            return
        }

        // Remove the old one
        splitVC.removeChild(at: 1)
        switch path {
        case "sources":
            splitVC.addSplitViewItem(sourcesViewItem!)
        case "time":
            splitVC.addSplitViewItem(timeViewItem!)
        case "displays":
            splitVC.addSplitViewItem(displaysViewItem!)
        case "brightness":
            splitVC.addSplitViewItem(brightnessViewItem!)
        case "cache":
            splitVC.addSplitViewItem(cacheViewItem!)
        case "overlays":
            splitVC.addSplitViewItem(overlaysViewItem!)
        case "filters":
            splitVC.addSplitViewItem(filtersViewItem!)
        case "updates":
            splitVC.addSplitViewItem(updatesViewItem!)
        default: //case "advanced":
            splitVC.addSplitViewItem(advancedViewItem!)
        }
    }

    func switchToInfos(_ path: String) {
        guard let splitVC = splitVC else {
            return
        }
        // Remove the old one
        splitVC.removeChild(at: 1)

        switch path {
        // Infos
        case "about":
            splitVC.addSplitViewItem(infoViewItem!)
        case "credits":
            splitVC.addSplitViewItem(creditsViewItem!)
        default: // case "help":
            splitVC.addSplitViewItem(helpViewItem!)
        }
    }

    func updateViewInPlace() {
        if currentPath!.starts(with: "videos:") {
            videosVC!.updateInPlace()
        } else {
            debugLog("download callback happenning but we moved away")
        }
    }

}

extension PanelWindowController: NSWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        if (notification.object as? NSWindow) == self.window {
            //doFirstTimeSetup()
        }
    }
}
