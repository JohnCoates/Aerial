//
//  PanelWindowController.swift
//  Aerial
//
//  Created by Guillaume Louel on 15/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class PanelWindowController: NSWindowController {
    var splitVC: NSSplitViewController?
    var videosVC: VideosViewController?

    var videoViewItem: NSSplitViewItem?             // Main video view
    var infoViewItem: NSSplitViewItem?              // Info

    // Settings
    var sourcesViewItem: NSSplitViewItem?
    var timeViewItem: NSSplitViewItem?
    var displaysViewItem: NSSplitViewItem?
    var brightnessViewItem: NSSplitViewItem?
    var cacheViewItem: NSSplitViewItem?
    var overlaysViewItem: NSSplitViewItem?
    var updatesViewItem: NSSplitViewItem?
    var advancedViewItem: NSSplitViewItem?

    var currentPath: String?

    convenience init() {
        debugLog("PWC2 init")
        self.init(windowNibName: "PanelWindowController")
    }

    override func windowDidLoad() {
        debugLog("PWC2 wdl")
        super.windowDidLoad()
        currentPath = "location:all"

        splitVC = NSSplitViewController()   // This is the core of ui V2, we dynamically change the right view controller based on what's on the left

        // We always need to specify a bundle manually, auto loading from bundle
        // does not work for screen savers when compiled as plugins
        let bundle = Bundle(for: PanelWindowController.self)

        videosVC = VideosViewController(nibName: .init("VideosViewController"), bundle: bundle)
        let infoVC = InfoViewController(nibName: .init("InfoViewController"), bundle: bundle)

        // Various settings
        let sourcesVC = SourcesViewController(nibName: .init("SourcesViewController"), bundle: bundle)
        let timeVC = TimeViewController(nibName: .init("TimeViewController"), bundle: bundle)
        let displaysVC = DisplaysViewController(nibName: .init("DisplaysViewController"), bundle: bundle)
        let brightnessVC = BrightnessViewController(nibName: .init("BrightnessViewController"), bundle: bundle)
        let cacheVC = CacheViewController(nibName: .init("CacheViewController"), bundle: bundle)
        let overlaysVC = OverlaysViewController(nibName: .init("OverlaysViewController"), bundle: bundle)
        let updatesVC = UpdatesViewController(nibName: .init("UpdatesViewController"), bundle: bundle)
        let advancedVC = AdvancedViewController(nibName: .init("AdvancedViewController"), bundle: bundle)

        // We do the sidebar last, as it bubble up events to the other ones
        let sidebarVC = SidebarViewController(nibName: .init("SidebarViewController"), bundle: bundle)
        sidebarVC.windowController = self

        // Create all the view items for the right panel
        videoViewItem = NSSplitViewItem(viewController: videosVC!)
        infoViewItem = NSSplitViewItem(viewController: infoVC)
        // All the settings have individual controllers
        sourcesViewItem = NSSplitViewItem(viewController: sourcesVC)
        timeViewItem = NSSplitViewItem(viewController: timeVC)
        displaysViewItem = NSSplitViewItem(viewController: displaysVC)
        brightnessViewItem = NSSplitViewItem(viewController: brightnessVC)
        cacheViewItem = NSSplitViewItem(viewController: cacheVC)
        overlaysViewItem = NSSplitViewItem(viewController: overlaysVC)
        updatesViewItem = NSSplitViewItem(viewController: updatesVC)
        advancedViewItem = NSSplitViewItem(viewController: advancedVC)

        splitVC!.addSplitViewItem(NSSplitViewItem(sidebarWithViewController: sidebarVC))
        splitVC!.addSplitViewItem(videoViewItem!)

        window?.contentViewController = splitVC

        debugLog("/PWC2 wdl")
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
        /*
        // Remove old
        switch from {
        case .videos:
            splitVC.removeSplitViewItem(videoViewItem)
        case.settings:
            splitVC.removeSplitViewItem(sourcesViewItem)
        case.infos:
            splitVC.removeSplitViewItem(infoViewItem)
        }*/

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
            switchViewItemTo(String(path[idx!...].dropFirst())) // Oh Swift...
        }

        // Save the new path
        self.currentPath = path
    }

    func switchViewItemTo(_ path: String) {
        guard let splitVC = splitVC else {
            return
        }
        // Remove the old one
        splitVC.removeChild(at: 1)

        if path == "sources" {
            splitVC.addSplitViewItem(sourcesViewItem!)
        } else if path == "time" {
            splitVC.addSplitViewItem(timeViewItem!)
        } else if path == "displays" {
            splitVC.addSplitViewItem(displaysViewItem!)
        } else if path == "brightness" {
            splitVC.addSplitViewItem(brightnessViewItem!)
        } else if path == "cache" {
            splitVC.addSplitViewItem(cacheViewItem!)
        } else if path == "overlays" {
            splitVC.addSplitViewItem(overlaysViewItem!)
        } else if path == "updates" {
            splitVC.addSplitViewItem(updatesViewItem!)
        } else if path == "advanced" {
            splitVC.addSplitViewItem(advancedViewItem!)
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
