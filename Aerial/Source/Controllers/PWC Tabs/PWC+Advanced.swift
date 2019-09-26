//
//  PWC+Advanced.swift
//  Aerial
//      This is the controller code for the Advanced Tab
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Cocoa

extension PreferencesWindowController {
    func setupAdvancedTab() {
        // Advanced panel
        if preferences.debugMode {
            debugModeCheckbox.state = .on
        }
        if preferences.logToDisk {
            logToDiskCheckbox.state = .on
        }
        if preferences.logMilliseconds {
            logMillisecondsButton.state = .on
        }
        if preferences.synchronizedMode {
            synchronizedModeCheckbox.state = .on
        }
    }
    // MARK: - Advanced panel

    @IBAction func logMillisecondsClick(_ button: NSButton) {
        let onState = button.state == .on
        preferences.logMilliseconds = onState
        debugLog("UI logMilliseconds: \(onState)")
    }

    @IBAction func logButtonClick(_ sender: NSButton) {
        logTableView.reloadData()
        if logPanel.isVisible {
            logPanel.close()
        } else {
            logPanel.makeKeyAndOrderFront(sender)
        }
    }

    @IBAction func logCopyToClipboardClick(_ sender: NSButton) {
        guard !errorMessages.isEmpty else { return }

        let clipboard = errorMessages.map { dateFormatter.string(from: $0.date) + " : " + $0.message}
            .joined(separator: "\n")

        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(clipboard, forType: .string)
    }

    @IBAction func logRefreshClick(_ sender: NSButton) {
        logTableView.reloadData()
    }

    @IBAction func debugModeClick(_ button: NSButton) {
        let onState = button.state == .on
        preferences.debugMode = onState
        debugLog("UI debugMode: \(onState)")
    }

    @IBAction func logToDiskClick(_ button: NSButton) {
        let onState = button.state == .on
        preferences.logToDisk = onState
        debugLog("UI logToDisk: \(onState)")
    }

    @IBAction func showLogInFinder(_ button: NSButton!) {
        let logfile = VideoCache.appSupportDirectory!.appending("/AerialLog.txt")

        // If we don't have a log, just show the folder
        if FileManager.default.fileExists(atPath: logfile) == false {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: VideoCache.appSupportDirectory!)
        } else {
            NSWorkspace.shared.selectFile(logfile, inFileViewerRootedAtPath: VideoCache.appSupportDirectory!)
        }
    }

    func updateLogs(level: ErrorLevel) {
        logTableView.reloadData()
        if highestLevel == nil {
            highestLevel = level
        } else if level.rawValue > highestLevel!.rawValue {
            highestLevel = level
        }

        switch highestLevel! {
        case .debug:
            showLogBottomClick.title = "Show Debug"
            showLogBottomClick.image = NSImage(named: NSImage.actionTemplateName)
        case .info:
            showLogBottomClick.title = "Show Info"
            showLogBottomClick.image = NSImage(named: NSImage.infoName)
        case .warning:
            showLogBottomClick.title = "Show Warning"
            showLogBottomClick.image = NSImage(named: NSImage.cautionName)
        default:
            showLogBottomClick.title = "Show Error"
            showLogBottomClick.image = NSImage(named: NSImage.stopProgressFreestandingTemplateName)
        }

        showLogBottomClick.isHidden = false
    }

    @IBAction func synchronizedModeClick(_ sender: NSButton) {
        let onState = sender.state == .on
        preferences.synchronizedMode = onState
        debugLog("UI synchronizedMode \(onState)")
    }

    @IBAction func moveOldVideosClick(_ sender: Any) {
        ManifestLoader.instance.moveOldVideos()

        let (description, total) = ManifestLoader.instance.getOldFilesEstimation()
        videoVersionsLabel.stringValue = description
        if total > 0 {
            moveOldVideosButton.isEnabled = true
            trashOldVideosButton.isEnabled = true
        } else {
            moveOldVideosButton.isEnabled = false
            trashOldVideosButton.isEnabled = false
        }

    }

    @IBAction func trashOldVideosClick(_ sender: Any) {
        ManifestLoader.instance.trashOldVideos()

        let (description, total) = ManifestLoader.instance.getOldFilesEstimation()
        videoVersionsLabel.stringValue = description
        if total > 0 {
            moveOldVideosButton.isEnabled = true
            trashOldVideosButton.isEnabled = true
        } else {
            moveOldVideosButton.isEnabled = false
            trashOldVideosButton.isEnabled = false
        }

    }
}
