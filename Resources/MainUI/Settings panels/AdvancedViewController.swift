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
    @IBOutlet var onBatteryPopup: NSPopUpButton!

    @IBOutlet var languagePopup: NSPopUpButton!
    @IBOutlet var languageLabel: NSTextField!

    @IBOutlet var debugCheckbox: NSButton!

    @IBOutlet var showLogButton: NSButton!

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

        muteSoundCheckbox.state = PrefsAdvanced.muteSound ? .on : .off

        onBatteryPopup.selectItem(at: PrefsVideos.onBatteryMode.rawValue)

        if Preferences.sharedInstance.debugMode {
            debugCheckbox.state = .on
        }

        let poisp = PoiStringProvider.sharedInstance
        languagePopup.selectItem(at: poisp.getLanguagePosition())

        // Grab preferred language as proper string
        languageLabel.stringValue = getPreferredLanguage()

        showLogButton.setIcons("folder")
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

    @IBAction func videoFormatPopupChange(_ sender: NSPopUpButton) {
        PrefsVideos.videoFormat = VideoFormat(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func videoFadesPopupChange(_ sender: NSPopUpButton) {
        PrefsVideos.fadeMode = FadeMode(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func rightArrowSkipClick(_ sender: NSButton) {
        PrefsVideos.allowSkips = sender.state == .on
    }

    @IBAction func muteSoundClick(_ sender: NSButton) {
        PrefsAdvanced.muteSound = sender.state == .on
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

    // Helpers, to move in a model when I have a sec
    func getPreferredLanguage() -> String {
        let printOutputLocale: NSLocale = NSLocale(localeIdentifier: Locale.preferredLanguages[0])
        if let deviceLanguageName: String = printOutputLocale.displayName(forKey: .identifier, value: Locale.preferredLanguages[0]) {
            if #available(OSX 10.12, *) {
                return "Preferred language: \(deviceLanguageName) [\(printOutputLocale.languageCode)]"
            } else {
                return "Preferred language: \(deviceLanguageName)"
            }
        } else {
            return ""
        }
    }

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
