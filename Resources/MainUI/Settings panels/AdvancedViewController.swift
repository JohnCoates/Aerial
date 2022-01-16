//
//  AdvancedViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import AVFoundation
import VideoToolbox

class AdvancedViewController: NSViewController {
    var windowController: PanelWindowController?
    var firstSetupWindowController: FirstSetupWindowController?

    @IBOutlet var popoverVideoFormat: NSPopover!

    @IBOutlet var popoverH264Indicator: NSButton!
    @IBOutlet var popoverHEVCIndicator: NSButton!
    @IBOutlet var popoverH264Label: NSTextField!
    @IBOutlet var popoverHEVCLabel: NSTextField!

    @IBOutlet var popoverOnBattery: NSPopover!

    @IBOutlet var videoFormatPopup: NSPopUpButton!
    // We need to hide HDR pre-Catalina
    @IBOutlet var menu1080pHDR: NSMenuItem!
    @IBOutlet var menu4KHDR: NSMenuItem!

    @IBOutlet var videoFadesPopup: NSPopUpButton!
    @IBOutlet var rightArrowSkipCheckbox: NSButton!
    @IBOutlet var muteSoundCheckbox: NSButton!

    @IBOutlet var highQualityTextCheckbox: NSButton!

    @IBOutlet var favorOrientationCheckbox: NSButton!
    @IBOutlet var autoplayPreviews: NSButton!

    @IBOutlet var onBatteryPopup: NSPopUpButton!

    @IBOutlet var languagePopup: NSPopUpButton!
    @IBOutlet var languageLabel: NSTextField!

    @IBOutlet var debugCheckbox: NSButton!

    @IBOutlet var showLogButton: NSButton!

    @IBOutlet var launchSetupAgain: NSButton!
    var originalFormat: VideoFormat?
    override func viewDidLoad() {
        super.viewDidLoad()

        // HEVC is available only in macOS 10.13+
        if #available(OSX 10.13, *) {
            videoFormatPopup.selectItem(at: PrefsVideos.videoFormat.rawValue)
        } else {
            // We reset to 1080p below 10.13
            PrefsVideos.videoFormat = VideoFormat.v1080pH264
            videoFormatPopup.selectItem(at: PrefsVideos.videoFormat.rawValue)
            videoFormatPopup.isEnabled = false
        }

        // Save this for future use
        originalFormat = PrefsVideos.videoFormat

        videoFadesPopup.selectItem(at: PrefsVideos.fadeMode.rawValue)

        // We need catalina for HDR ! And we can't use right arrow to skip in Catalina
        if #available(OSX 10.15, *) {
            rightArrowSkipCheckbox.isEnabled = false
        } else {
            menu1080pHDR.isHidden = true
            menu4KHDR.isHidden = true
        }

        if !PrefsVideos.allowSkips {
            rightArrowSkipCheckbox.state = .off
        }

        highQualityTextCheckbox.state = PrefsInfo.highQualityTextRendering ? .on : .off

        muteSoundCheckbox.state = PrefsAdvanced.muteSound ? .on : .off
        autoplayPreviews.state = PrefsAdvanced.autoPlayPreviews ? .on : .off
        favorOrientationCheckbox.state = PrefsAdvanced.favorOrientation ? .on : .off

        onBatteryPopup.selectItem(at: PrefsVideos.onBatteryMode.rawValue)

        if Preferences.sharedInstance.debugMode {
            debugCheckbox.state = .on
        }

        let poisp = PoiStringProvider.sharedInstance
        languagePopup.selectItem(at: poisp.getLanguagePosition())

        // Grab preferred language as proper string
        languageLabel.stringValue = Aerial.getPreferredLanguage()

        showLogButton.setIcons("folder")
        launchSetupAgain.setIcons("aspectratio")
        setupPopover()
    }

    func setupPopover() {
        // Help popover, GVA detection requires 10.13
        if #available(OSX 10.13, *) {
            if !VTIsHardwareDecodeSupported(kCMVideoCodecType_H264) {
                popoverH264Label.stringValue = "H264 acceleration not supported"
                popoverH264Indicator.image = NSImage(named: NSImage.statusUnavailableName)
            }
            if !VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC) {
                popoverHEVCLabel.stringValue = "HEVC Main10 acceleration not supported"
                popoverHEVCIndicator.image = NSImage(named: NSImage.statusUnavailableName)
            } else {
                let hardwareDetection = HardwareDetection.sharedInstance
                switch hardwareDetection.isHEVCMain10HWDecodingAvailable() {
                case .supported:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration is supported"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.statusAvailableName)
                case .notsupported:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration is not supported"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.statusUnavailableName)
                case .partial:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration is partially supported"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.statusPartiallyAvailableName)
                default:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration status unknown"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.cautionName)
                }
            }
        } else {
            // Fallback on earlier versions
            popoverHEVCIndicator.isHidden = true
            popoverH264Indicator.image = NSImage(named: NSImage.cautionName)
            popoverH264Label.stringValue = "macOS 10.13 or above required"
            popoverHEVCLabel.stringValue = "Hardware acceleration status unknown"
        }
    }

    @IBAction func launchSetupAgainClick(_ sender: NSButton) {
        if firstSetupWindowController == nil {
            let bundle = Bundle(for: PanelWindowController.self)
            // We also load our CustomVideos nib here

            firstSetupWindowController = FirstSetupWindowController()
            var topLevelObjects: NSArray? = NSArray()
            if !bundle.loadNibNamed(NSNib.Name("FirstSetupWindowController"),
                                owner: firstSetupWindowController,
                                topLevelObjects: &topLevelObjects) {
                errorLog("Could not load nib for FirstSetupWindowController, please report")
            }
        }

        DispatchQueue.main.async {
            self.firstSetupWindowController!.windowDidLoad()
            self.firstSetupWindowController!.showWindow(self)
            self.firstSetupWindowController!.window!.makeKeyAndOrderFront(self)
        }
    }

    @IBAction func videoFormatPopupChange(_ sender: NSPopUpButton) {
        let candidateFormat = VideoFormat(rawValue: sender.indexOfSelectedItem)!

        if candidateFormat != originalFormat {
            // swiftlint:disable:next line_length
            if Aerial.showAlert(question: "Changing format will delete all videos", text: "Changing format will delete your downloaded videos. They will be re-downloaded based on your preferences. \n\nYou can also manually redownload videos in Custom Sources.", button1: "Change Format and Delete Videos", button2: "Cancel") {
                PrefsVideos.videoFormat = candidateFormat
                originalFormat = candidateFormat

                Cache.clearCache()
                Cache.clearNonCacheableSources()
                // Sidebar.instance.refreshVideos()
            } else {
                videoFormatPopup.selectItem(at: PrefsVideos.videoFormat.rawValue)
            }
        } else {
            PrefsVideos.videoFormat = candidateFormat
        }
    }

    @IBAction func videoFadesPopupChange(_ sender: NSPopUpButton) {
        PrefsVideos.fadeMode = FadeMode(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func highQualityTextClick(_ sender: NSButton) {
        PrefsInfo.highQualityTextRendering = sender.state == .on
    }
    @IBAction func rightArrowSkipClick(_ sender: NSButton) {
        PrefsVideos.allowSkips = sender.state == .on
    }

    @IBAction func muteSoundClick(_ sender: NSButton) {
        PrefsAdvanced.muteSound = sender.state == .on
    }

    @IBAction func autoPlaysPreviewsClick(_ sender: NSButton) {
        PrefsAdvanced.autoPlayPreviews = sender.state == .on
    }

    @IBAction func favorOrientationClick(_ sender: NSButton) {
        PrefsAdvanced.favorOrientation = sender.state == .on
    }

    @IBAction func onBatteryPopupChange(_ sender: NSPopUpButton) {
        PrefsVideos.onBatteryMode = OnBatteryMode(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func languagePopupChange(_ sender: NSPopUpButton) {
        let poisp = PoiStringProvider.sharedInstance
        Preferences.sharedInstance.ciOverrideLanguage = poisp.getLanguageStringFromPosition(pos: sender.indexOfSelectedItem)
    }

    @IBAction func debugCheckboxClick(_ sender: NSButton) {
        Preferences.sharedInstance.debugMode = sender.state == .on
    }

    @IBAction func showLogInFinderClick(_ sender: Any) {
        let logfile = VideoCache.appSupportDirectory!.appending("/AerialLog.txt")

        // If we don't have a log, just show the folder
        if FileManager.default.fileExists(atPath: logfile) == false {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: VideoCache.appSupportDirectory!)
        } else {
            NSWorkspace.shared.selectFile(logfile, inFileViewerRootedAtPath: VideoCache.appSupportDirectory!)
        }
    }

    @IBAction func resetAllSettings(_ sender: NSButton) {
        if Aerial.showAlert(
            question: "Reset all settings?",
            text: "This will reset all your settings. After they are reset, Aerial will close System Preferences, you will have to reload it to access settings again.\n\nAre you sure you want to reset your settings?",
            button1: "Reset my settings",
            button2: "Cancel") {

            let process: Process = Process()

            debugLog("clearing defaults")
            process.launchPath = "/usr/bin/defaults"

            // Settings may be stored in a container... unless we run under companion ! What a mess...
            if #available(OSX 10.15, *) {
                if Aerial.underCompanion {
                    process.arguments = ["-currentHost", "delete", "com.JohnCoates.Aerial"]
                } else {
                    process.arguments = ["-currentHost", "delete", "~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/ByHost/com.JohnCoates.Aerial"]
                }
            } else {
                process.arguments = ["-currentHost", "delete", "com.JohnCoates.Aerial"]
            }

            process.launch()
            process.waitUntilExit()

            Aerial.showInfoAlert(title: "Settings reset to defaults", text: "Your settings were reset to defaults. \n\nPlease close Aerial and System Preferences in order to reload them.")
        }
    }

    // Helpers, to move in a model when I have a sec

    @IBAction func helpVideoFormat(_ sender: NSButton) {
        popoverVideoFormat.show(relativeTo: sender.preparedContentRect, of: sender, preferredEdge: .maxY)
    }

    @IBAction func helpOnBattery(_ sender: NSButton) {
        popoverOnBattery.show(relativeTo: sender.preparedContentRect, of: sender, preferredEdge: .maxY)
    }

    @IBAction func dolbyVisionClick(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://en.wikipedia.org/wiki/Dolby_Laboratories#Video_processing")!
        workspace.open(url)
    }

    @IBAction func projectPageClick(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/blob/master/Documentation/HardwareDecoding.md")!
        workspace.open(url)
    }
}
