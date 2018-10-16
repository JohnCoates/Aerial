//
//  PreferencesWindowController.swift
//  Aerial
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation
import ScreenSaver
import VideoToolbox

class TimeOfDay {
    let title: String
    var videos: [AerialVideo] = [AerialVideo]()
    
    init(title: String) {
        self.title = title
    }
    
}

class City {
    var night: TimeOfDay = TimeOfDay(title: "night")
    var day: TimeOfDay = TimeOfDay(title: "day")
    let name: String
    //var videos: [AerialVideo] = [AerialVideo]()
    
    init(name: String) {
        self.name = name
    }
    /*func addVideo(video: AerialVideo)
    {
        video.arrayPosition = videos.count
        videos.append(video)
    }*/
    func addVideoForTimeOfDay(_ timeOfDay: String, video: AerialVideo) {
        if timeOfDay.lowercased() == "night" {
            video.arrayPosition = night.videos.count
            night.videos.append(video)
        } else {
            video.arrayPosition = day.videos.count
            day.videos.append(video)
        }
    }
}

@objc(PreferencesWindowController)
class PreferencesWindowController: NSWindowController, NSOutlineViewDataSource,
NSOutlineViewDelegate, VideoDownloadDelegate {

    @IBOutlet var outlineView: NSOutlineView!
    @IBOutlet var outlineViewSettings: NSButton!
    @IBOutlet var playerView: AVPlayerView!
    @IBOutlet var showDescriptionsCheckbox: NSButton!
    @IBOutlet var localizeForTvOS12Checkbox: NSButton!
    @IBOutlet var projectPageLink: NSButton!
    @IBOutlet var secondProjectPageLink: NSButton!
    @IBOutlet var cacheLocation: NSPathControl!
    @IBOutlet var cacheAerialsAsTheyPlayCheckbox: NSButton!
    @IBOutlet var neverStreamVideosCheckbox: NSButton!
    @IBOutlet var neverStreamPreviewsCheckbox: NSButton!
    
    @IBOutlet var multiMonitorModePopup: NSPopUpButton!
    @IBOutlet var popupVideoFormat: NSPopUpButton!
    @IBOutlet var descriptionModePopup: NSPopUpButton!
    @IBOutlet var fadeInOutModePopup: NSPopUpButton!
    @IBOutlet weak var fadeInOutTextModePopup: NSPopUpButton!
    
    @IBOutlet var versionLabel: NSTextField!
    @IBOutlet var popover: NSPopover!
    @IBOutlet var popoverH264Indicator: NSButton!
    @IBOutlet var popoverHEVCIndicator: NSButton!
    @IBOutlet var popoverH264Label: NSTextField!
    @IBOutlet var popoverHEVCLabel: NSTextField!

    @IBOutlet var timeDisabledRadio: NSButton!
    @IBOutlet var timeNightShiftRadio: NSButton!
    @IBOutlet var timeManualRadio: NSButton!
    @IBOutlet var timeLightDarkModeRadio: NSButton!
    @IBOutlet var nightShiftLabel: NSTextField!
    @IBOutlet var lightDarkModeLabel: NSTextField!
    
    @IBOutlet var sunriseTime: NSDatePicker!
    @IBOutlet var sunsetTime: NSDatePicker!
    @IBOutlet var iconTime1: NSImageCell!
    @IBOutlet var iconTime2: NSImageCell!

    @IBOutlet var cornerTopLeft: NSButton!
    @IBOutlet var cornerTopRight: NSButton!
    @IBOutlet var cornerBottomLeft: NSButton!
    @IBOutlet var cornerBottomRight: NSButton!
    @IBOutlet var cornerRandom: NSButton!

    @IBOutlet var previewDisabledTextfield: NSTextField!
    @IBOutlet var fontPickerButton: NSButton!
    @IBOutlet var currentFontLabel: NSTextField!
    @IBOutlet var currentLocaleLabel: NSTextField!
    
    @IBOutlet var showClockCheckbox: NSButton!
    @IBOutlet var showExtraMessage: NSButton!
    @IBOutlet var extraMessageTextField: NSTextField!
    @IBOutlet var extraMessageFontLabel: NSTextField!
    @IBOutlet weak var extraCornerPopup: NSPopUpButton!
    
    var player: AVPlayer = AVPlayer()
    
    var videos: [AerialVideo]?
    // cities -> time of day -> videos
    var cities = [City]()
    
    static var loadedJSON: Bool = false
    
    lazy var preferences = Preferences.sharedInstance
    
    let fontManager: NSFontManager
    var fontEditing = 0     // To track the font we are changing
    
    // MARK: - Init
    required init?(coder decoder: NSCoder) {
        self.fontManager = NSFontManager.shared
        super.init(coder: decoder)
    }
    override init(window: NSWindow?) {
        self.fontManager = NSFontManager.shared
        super.init(window: window)
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.fontManager.target = self

        if let previewPlayer = AerialView.previewPlayer {
            self.player = previewPlayer
        }

        outlineView.floatsGroupRows = false

        loadJSON()  // Async loading

        if let version = Bundle(identifier: "com.johncoates.Aerial-Test")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.stringValue = version
        }
        if let version = Bundle(identifier: "com.JohnCoates.Aerial")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.stringValue = version
        }

        // Some icons are 10.12.2+ only
        if #available(OSX 10.12.2, *) {
            iconTime1.image = NSImage(named: NSImage.touchBarHistoryTemplateName)
            iconTime2.image = NSImage(named: NSImage.touchBarComposeTemplateName)
        }
        
        // Help popover, GVA detection requires 10.13
        if #available(OSX 10.13, *) {
            if !VTIsHardwareDecodeSupported(kCMVideoCodecType_H264)
            {
                popoverH264Label.stringValue = "H264 acceleration not supported"
                popoverH264Indicator.image = NSImage(named: NSImage.statusUnavailableName)
            }
            if !VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)
            {
                popoverHEVCLabel.stringValue = "HEVC acceleration not supported"
                popoverHEVCIndicator.image = NSImage(named: NSImage.statusUnavailableName)
            }
        } else {
            // Fallback on earlier versions
            popoverHEVCIndicator.isHidden = true
            popoverH264Indicator.image = NSImage(named: NSImage.cautionName)
            popoverH264Label.stringValue = "macOS 10.13 or above required"
            popoverHEVCLabel.stringValue = "Hardware acceleration status unknown"
        }
        
        // Fonts for descriptions and extra (clock/msg)
        currentFontLabel.stringValue = preferences.fontName! + ", \(preferences.fontSize!) pt"
        extraMessageFontLabel.stringValue = preferences.extraFontName! + ", \(preferences.extraFontSize!) pt"

        // Extra message
        extraMessageTextField.stringValue = preferences.showMessageString!
        
        // Grab preferred language as proper string
        let printOutputLocale: NSLocale = NSLocale(localeIdentifier: Locale.preferredLanguages[0])
        if let deviceLanguageName: String = printOutputLocale.displayName(forKey: NSLocale.Key.identifier, value: Locale.preferredLanguages[0]) {
            currentLocaleLabel.stringValue = "Preferred language : \(deviceLanguageName)"
        } else {
            currentLocaleLabel.stringValue = ""
        }
        
        // Videos panel
        playerView.player = player
        playerView.controlsStyle = .none
        if #available(OSX 10.10, *) {
            playerView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }

        // To loop playback, we catch the end of the video to rewind
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
        
        if #available(OSX 10.12, *) {
        } else {
            showClockCheckbox.isEnabled = false
        }
        
        // Text panel
        if preferences.showClock {
            showClockCheckbox.state = NSControl.StateValue.on
        }

        if preferences.showMessage {
            showExtraMessage.state = NSControl.StateValue.on
            extraMessageTextField.isEnabled = true
        }

        if preferences.showDescriptions {
            showDescriptionsCheckbox.state = NSControl.StateValue.on
        }

        if preferences.localizeDescriptions {
            localizeForTvOS12Checkbox.state = NSControl.StateValue.on
        }
        
        // Cache panel
        if preferences.neverStreamVideos {
            neverStreamVideosCheckbox.state = NSControl.StateValue.on
        }
        
        if preferences.neverStreamPreviews {
            neverStreamPreviewsCheckbox.state = NSControl.StateValue.on
        }
        
        if !preferences.cacheAerials {
            cacheAerialsAsTheyPlayCheckbox.state = NSControl.StateValue.off
        }
        
        // Time mode
        let timeManagement = TimeManagement.sharedInstance
        // Light/Dark mode only available on Mojave+
        let (isLDMCapable, reason: LDMReason) = timeManagement.isLightDarkModeAvailable()
        if !isLDMCapable {
            timeLightDarkModeRadio.isEnabled = false
        }
        lightDarkModeLabel.stringValue = LDMReason

        // Night Shift requires 10.12.4+ and a compatible Mac
        let (isNSCapable, reason: NSReason) = timeManagement.isNightShiftAvailable()
        if !isNSCapable {
            timeNightShiftRadio.isEnabled = false
        }
        nightShiftLabel.stringValue = NSReason

        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        if let dateSunrise = dateFormatter.date(from: preferences.manualSunrise!) {
            sunriseTime.dateValue = dateSunrise
        }
        if let dateSunset = dateFormatter.date(from: preferences.manualSunset!) {
            sunsetTime.dateValue = dateSunset
        }
        
        // Handle the time radios
        switch preferences.timeMode {
        case Preferences.TimeMode.nightShift.rawValue:
            timeNightShiftRadio.state = NSControl.StateValue.on
        case Preferences.TimeMode.manual.rawValue:
            timeManualRadio.state = NSControl.StateValue.on
        case Preferences.TimeMode.lightDarkMode.rawValue:
            timeLightDarkModeRadio.state = NSControl.StateValue.on
        default:
            timeDisabledRadio.state = NSControl.StateValue.on
        }
        
        // Handle the corner radios
        switch preferences.descriptionCorner {
        case Preferences.DescriptionCorner.topLeft.rawValue:
            cornerTopLeft.state = NSControl.StateValue.on
        case Preferences.DescriptionCorner.topRight.rawValue:
            cornerTopRight.state = NSControl.StateValue.on
        case Preferences.DescriptionCorner.bottomLeft.rawValue:
            cornerBottomLeft.state = NSControl.StateValue.on
        case Preferences.DescriptionCorner.bottomRight.rawValue:
            cornerBottomRight.state = NSControl.StateValue.on
        default:
            cornerRandom.state = NSControl.StateValue.on
        }

        multiMonitorModePopup.selectItem(at: preferences.multiMonitorMode!)
        
        popupVideoFormat.selectItem(at: preferences.videoFormat!)
        
        descriptionModePopup.selectItem(at: preferences.showDescriptionsMode!)
        
        fadeInOutModePopup.selectItem(at: preferences.fadeMode!)

        fadeInOutTextModePopup.selectItem(at: preferences.fadeModeText!)

        extraCornerPopup.selectItem(at: preferences.extraCorner!)
        
        colorizeProjectPageLinks()
        
        if let cacheDirectory = VideoCache.cacheDirectory {
            cacheLocation.url = URL(fileURLWithPath: cacheDirectory as String)
        }
        
        cacheStatusLabel.isEditable = false
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Workaround for garbled icons on non retina, we force redraw
        outlineView.reloadData()
    }
    
    @IBAction func close(_ sender: AnyObject?) {
        window?.sheetParent?.endSheet(window!)
    }
    
    // MARK: Video playback
    
    // Rewind preview video when reaching end
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            let url:URL? = (playerItem.asset as? AVURLAsset)?.url

            if (url!.absoluteString.starts(with: "file")) {
                playerItem.seek(to: CMTime.zero, completionHandler: nil)
                self.player.play()
            }
        }
    }
    
    // MARK: - Setup
    
    fileprivate func colorizeProjectPageLinks() {
        let color = NSColor(calibratedRed: 0.18, green: 0.39, blue: 0.76, alpha: 1)
        var coloredLink = NSMutableAttributedString(attributedString: projectPageLink.attributedTitle)
        var fullRange = NSRange(location: 0, length: coloredLink.length)
        coloredLink.addAttribute(NSAttributedString.Key.foregroundColor,
                                 value: color,
                                  range: fullRange)
        projectPageLink.attributedTitle = coloredLink

        // We have an extra project link on the video format popover, color it too
        coloredLink = NSMutableAttributedString(attributedString: secondProjectPageLink.attributedTitle)
        fullRange = NSRange(location: 0, length: coloredLink.length)
        coloredLink.addAttribute(NSAttributedString.Key.foregroundColor,
                                 value: color,
                                 range: fullRange)
        secondProjectPageLink.attributedTitle = coloredLink
    }
    
    // MARK: - Preferences
    @IBAction func fontPickerClick(_ sender:NSButton?) {
        // Make a panel
        let fp = self.fontManager.fontPanel(true)

        // Set current font
        if let font = NSFont(name: preferences.fontName!,size: CGFloat(preferences.fontSize!)) {
            fp?.setPanelFont(font, isMultiple: false)

        } else {
            fp?.setPanelFont(NSFont(name: "Helvetica Neue Medium", size: 28)!, isMultiple: false)
        }

        // push the panel but mark which one we are editing
        fontEditing = 0
        fp?.makeKeyAndOrderFront(sender)
    }
    
    @IBAction func fontResetClick(_ sender:NSButton?) {
        preferences.fontName = "Helvetica Neue Medium"
        preferences.fontSize = 28
        
        // Update our label
        currentFontLabel.stringValue = preferences.fontName! + ", \(preferences.fontSize!) pt"
    }

    @IBAction func extraFontPickerClick(_ sender:NSButton?) {
        // Make a panel
        let fp = self.fontManager.fontPanel(true)
        
        // Set current font
        if let font = NSFont(name: preferences.extraFontName!,size: CGFloat(preferences.extraFontSize!)) {
            fp?.setPanelFont(font, isMultiple: false)
            
        } else {
            fp?.setPanelFont(NSFont(name: "Helvetica Neue Medium", size: 28)!, isMultiple: false)
        }
        
        // push the panel but mark which one we are editing
        fontEditing = 1
        fp?.makeKeyAndOrderFront(sender)
    }

    @IBAction func extraFontResetClick(_ sender:NSButton?) {
        preferences.extraFontName = "Helvetica Neue Medium"
        preferences.extraFontSize = 28
        
        // Update our label
        extraMessageFontLabel.stringValue = preferences.extraFontName! + ", \(preferences.extraFontSize!) pt"
    }

    
    @IBAction func extraTextFieldChange(_ sender: NSTextField) {
        print("changed message \(sender.stringValue)")
        preferences.showMessageString = sender.stringValue
    }
    
    @IBAction func timeModeChange(_ sender:NSButton?) {
        if sender == timeDisabledRadio {
            preferences.timeMode = Preferences.TimeMode.disabled.rawValue
        } else if sender == timeNightShiftRadio {
            preferences.timeMode = Preferences.TimeMode.nightShift.rawValue
        } else if sender == timeManualRadio {
            preferences.timeMode = Preferences.TimeMode.manual.rawValue
        } else if sender == timeLightDarkModeRadio {
            preferences.timeMode = Preferences.TimeMode.lightDarkMode.rawValue
        }
    }
    
    @IBAction func descriptionCornerChange(_ sender:NSButton?) {
        if sender == cornerTopLeft {
            preferences.descriptionCorner = Preferences.DescriptionCorner.topLeft.rawValue
        } else if sender == cornerTopRight {
            preferences.descriptionCorner = Preferences.DescriptionCorner.topRight.rawValue
        } else if sender == cornerBottomLeft {
            preferences.descriptionCorner = Preferences.DescriptionCorner.bottomLeft.rawValue
        } else if sender == cornerBottomRight {
            preferences.descriptionCorner = Preferences.DescriptionCorner.bottomRight.rawValue
        } else if sender == cornerRandom {
            preferences.descriptionCorner = Preferences.DescriptionCorner.random.rawValue
        }
    }
    
    @IBAction func sunriseChange(_ sender:NSDatePicker?) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let sunriseString = dateFormatter.string(from: (sender?.dateValue)!)
        preferences.manualSunrise = sunriseString
    }

    @IBAction func sunsetChange(_ sender:NSDatePicker?) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let sunsetString = dateFormatter.string(from: (sender?.dateValue)!)
        preferences.manualSunset = sunsetString
    }

    @IBAction func helpButtonClick(_ button: NSButton!) {
        popover.show(relativeTo: button.preparedContentRect, of: button, preferredEdge: .maxY)
    }
    
    @IBAction func showInFinder(_ button: NSButton!) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: VideoCache.cacheDirectory!)
        
    }
    
    @IBAction func showClockClick(_ sender: NSButton) {
        debugLog("show clock click: \(convertFromNSControlStateValue(sender.state))")
        
        let onState = (sender.state == NSControl.StateValue.on)
        preferences.showClock = onState

    }
    
    @IBAction func showExtraMessageClick(_ sender: NSButton) {
        debugLog("show extra message: \(convertFromNSControlStateValue(sender.state))")
        
        let onState = (sender.state == NSControl.StateValue.on)
        // We also need to enable/disable our message field
        extraMessageTextField.isEnabled = onState
        preferences.showMessage = onState
    }
    
    @IBAction func neverStreamVideosClick(_ button: NSButton!) {
        debugLog("never stream videos: \(convertFromNSControlStateValue(button.state))")
        
        let onState = (button.state == NSControl.StateValue.on)
        preferences.neverStreamVideos = onState
    }
    
    @IBAction func neverStreamPreviewsClick(_ button: NSButton!) {
        debugLog("never stream previews: \(convertFromNSControlStateValue(button.state))")
        
        let onState = (button.state == NSControl.StateValue.on)
        preferences.neverStreamPreviews = onState
    }
    @IBAction func cacheAerialsAsTheyPlayClick(_ button: NSButton!) {
        debugLog("cache aerials as they play: \(convertFromNSControlStateValue(button.state))")
        
        let onState = (button.state == NSControl.StateValue.on)
        preferences.cacheAerials = onState
    }
    
    @IBAction func userSetCacheLocation(_ button: NSButton?) {
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Choose Aerial Cache Directory"
        openPanel.prompt = "Choose"
        openPanel.directoryURL = cacheLocation.url
        
        openPanel.begin { result in
            guard result.rawValue == NSFileHandlingPanelOKButton,
                openPanel.urls.count > 0 else {
                return
            }
            
            let cacheDirectory = openPanel.urls[0]
            self.preferences.customCacheDirectory = cacheDirectory.path
            self.cacheLocation.url = cacheDirectory
        }
    }
    @IBAction func resetCacheLocation(_ button: NSButton?) {
        preferences.customCacheDirectory = nil
        if let cacheDirectory = VideoCache.cacheDirectory {
            cacheLocation.url = URL(fileURLWithPath: cacheDirectory as String)
        }
    }
    
    @IBAction func popupVideoFormatChange(_ sender:NSPopUpButton) {
        debugLog("index change : \(sender.indexOfSelectedItem)")
        preferences.videoFormat = sender.indexOfSelectedItem
        preferences.synchronize()
        
        outlineView.reloadData()
    }
    
    @IBAction func descriptionModePopupChange(_ sender:NSPopUpButton) {
        debugLog("dindex change : \(sender.indexOfSelectedItem)")
        
        preferences.showDescriptionsMode = sender.indexOfSelectedItem
        preferences.synchronize()
    }
    
    @IBAction func multiMonitorModePopupChange(_ sender:NSPopUpButton) {
        debugLog("mm index change : \(sender.indexOfSelectedItem)")
        
        preferences.multiMonitorMode = sender.indexOfSelectedItem
        preferences.synchronize()
    }
    
    @IBAction func fadeInOutModePopupChange(_ sender:NSPopUpButton) {
        debugLog("fm index change : \(sender.indexOfSelectedItem)")
        
        preferences.fadeMode = sender.indexOfSelectedItem
        preferences.synchronize()
    }
    
    @IBAction func fadeInOutTextModePopupChange(_ sender: NSPopUpButton) {
        debugLog("fmt index change : \(sender.indexOfSelectedItem)")
        
        preferences.fadeModeText = sender.indexOfSelectedItem
        preferences.synchronize()
    }
    
    @IBAction func extraCornerPopupChange(_ sender: NSPopUpButton) {
        debugLog("ec index change : \(sender.indexOfSelectedItem)")
        
        preferences.extraCorner = sender.indexOfSelectedItem
        preferences.synchronize()

    }

    @IBAction func showDescriptionsClick(button: NSButton?) {
        let state = showDescriptionsCheckbox.state
        let onState = (state == NSControl.StateValue.on)
        
        preferences.showDescriptions = onState
        
        debugLog("set showDescriptions to \(onState)")
    }
    
    @IBAction func localizeForTvOS12Click(button: NSButton?) {
        let state = localizeForTvOS12Checkbox.state
        let onState = (state == NSControl.StateValue.on)
        
        preferences.localizeDescriptions = onState
        
        debugLog("set localizeDescriptions to \(onState)")
    }
    
    // MARK: Menu
    @IBAction func outlineViewSettingsClick(_ button: NSButton) {
        let menu = NSMenu()

        menu.insertItem(withTitle: "Check Only Cached",
                        action: #selector(PreferencesWindowController.outlineViewCheckCached(button:)),
                        keyEquivalent: "",
                        at: 0)
        menu.insertItem(withTitle: "Check Only 4K",
                        action: #selector(PreferencesWindowController.outlineViewCheck4K(button:)),
                        keyEquivalent: "",
                        at: 1)
        menu.insertItem(withTitle: "Check All",
                        action: #selector(PreferencesWindowController.outlineViewCheckAll(button:)),
                        keyEquivalent: "",
                        at: 2)
        menu.insertItem(withTitle: "Uncheck All",
                        action: #selector(PreferencesWindowController.outlineViewUncheckAll(button:)),
                        keyEquivalent: "",
                        at: 3)
        menu.insertItem(NSMenuItem.separator(), at: 4)
        menu.insertItem(withTitle: "Download Checked",
                        action: #selector(PreferencesWindowController.outlineViewDownloadChecked(button:)),
                        keyEquivalent: "",
                        at: 5)
        menu.insertItem(withTitle: "Download All",
                        action: #selector(PreferencesWindowController.outlineViewDownloadAll(button:)),
                        keyEquivalent: "",
                        at: 6)
        
        let event = NSApp.currentEvent
        NSMenu.popUpContextMenu(menu, with: event!, for: button)
    }

    @objc func outlineViewUncheckAll(button: NSButton) {
        setAllVideos(inRotation: false)
    }
    
    @objc func outlineViewCheckAll(button: NSButton) {
        setAllVideos(inRotation: true)
    }
    
    @objc func outlineViewCheck4K(button: NSButton) {
        guard let videos = videos else {
            return
        }
        
        for video in videos {
            if video.url4KHEVC != "" {
                preferences.setVideo(videoID: video.id,
                                     inRotation: true,
                                     synchronize: false)
            } else {
                preferences.setVideo(videoID: video.id,
                                     inRotation: false,
                                     synchronize: false)
            }
        }
        preferences.synchronize()
        
        outlineView.reloadData()
    }
    
    @objc func outlineViewCheckCached(button: NSButton) {
        guard let videos = videos else {
            return
        }
        
        for video in videos {
            if video.isAvailableOffline {
                preferences.setVideo(videoID: video.id,
                                     inRotation: true,
                                     synchronize: false)
            } else {
                preferences.setVideo(videoID: video.id,
                                     inRotation: false,
                                     synchronize: false)
            }
        }
        preferences.synchronize()
        
        outlineView.reloadData()
    }
    
    @objc func outlineViewDownloadChecked(button: NSButton) {
        guard let videos = videos else {
            return
        }
        let videoManager = VideoManager.sharedInstance

        for video in videos {
            if preferences.videoIsInRotation(videoID: video.id) && !video.isAvailableOffline {
                if !videoManager.isVideoQueued(id: video.id) {
                    videoManager.queueDownload(video)
                }
            }
        }
    }
    
    @objc func outlineViewDownloadAll(button: NSButton) {
        guard let videos = videos else {
            return
        }
        let videoManager = VideoManager.sharedInstance
        
        for video in videos {
            if !video.isAvailableOffline {
                if !videoManager.isVideoQueued(id: video.id) {
                    videoManager.queueDownload(video)
                }
            }
        }
    }
    
    func setAllVideos(inRotation: Bool) {
        guard let videos = videos else {
            return
        }
        
        for video in videos {
            preferences.setVideo(videoID: video.id,
                                 inRotation: inRotation,
                                 synchronize: false)
        }
        preferences.synchronize()
        
        outlineView.reloadData()
    }
    
    // MARK: - Links
    
    @IBAction func pageProjectClick(_ button: NSButton?) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "http://github.com/JohnCoates/Aerial")!
        workspace.open(url)
    }
    
    // MARK: - Manifest
    
    func loadJSON() {
        if PreferencesWindowController.loadedJSON {
            return
        }
        PreferencesWindowController.loadedJSON = true
        
        ManifestLoader.instance.addCallback { manifestVideos in
            self.loaded(manifestVideos: manifestVideos)
       }
    }
    
    func loaded(manifestVideos: [AerialVideo]) {
        var videos = [AerialVideo]()
        var cities = [String: City]()

        // First day, then night
        for video in manifestVideos {
            let name = video.name
            
            if cities.keys.contains(name) == false {
                cities[name] = City(name: name)
            }
            let city = cities[name]!
        
            let timeOfDay = video.timeOfDay
            city.addVideoForTimeOfDay(timeOfDay, video: video)
            
            videos.append(video)
        }

        self.videos = videos
        
        // sort cities by name
        let unsortedCities = cities.values
        let sortedCities = unsortedCities.sorted { $0.name < $1.name }

        self.cities = sortedCities

        DispatchQueue.main.async {
            self.outlineView.reloadData()
            self.outlineView.expandItem(nil, expandChildren: true)
        }
    }
    
    // MARK: - Outline View Delegate & Data Source
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return cities.count
        }
        
        switch item {
            case is TimeOfDay:
                let timeOfDay = item as! TimeOfDay
                return timeOfDay.videos.count
            case is City:
                let city = item as! City
                
                var count = 0
                
                if city.night.videos.count > 0 {
                    count += 1
                }
                
                if city.day.videos.count > 0 {
                    count += 1
                }
                return count

                //let city = item as! City
                //return city.day.videos.count + city.night.videos.count
            default:
                return 0
        }
        
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        switch item {
        case is TimeOfDay:
            return true
        case is City:
            return true
        default:
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return cities[index]
        }
        
        switch item {
        case is City:
            
            let city = item as! City
            
            if index == 0 && city.day.videos.count > 0 {
                return city.day
            } else {
                return city.night
            }
            //let city = item as! City
            //return city.videos[index]
            
        case is TimeOfDay:
            let timeOfDay = item as! TimeOfDay
            return timeOfDay.videos[index]
        
        default:
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView,
                     objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        switch item {
        case is City:
            let city = item as! City
            return city.name
        case is TimeOfDay:
            let timeOfDay = item as! TimeOfDay
            return timeOfDay.title
            
        default:
            return "untitled"
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, dataCellFor tableColumn: NSTableColumn?, item: Any) -> NSCell? {
        let row = outlineView.row(forItem: item)
        return tableColumn!.dataCell(forRow: row) as? NSCell
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        switch item {
        case is TimeOfDay:
            return true
        case is City:
            return true
        default:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView,
                     viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        switch item {
        case is City:
            let city = item as! City
            let view = outlineView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("HeaderCell"),
                                        owner: nil) as! NSTableCellView     // if owner = self, awakeFromNib will be called for each created cell !
            view.textField?.stringValue = city.name
            
            return view
        case is TimeOfDay:
            let timeOfDay = item as! TimeOfDay
            let view = outlineView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("DataCell"),
                                        owner: nil) as! NSTableCellView     // if owner = self, awakeFromNib will be called for each created cell !
            
            view.textField?.stringValue = timeOfDay.title.capitalized
            
            let bundle = Bundle(for: PreferencesWindowController.self)
            
            // Use -dark icons in macOS 10.14+ Dark Mode
            let timeManagement = TimeManagement.sharedInstance
            var postfix = ""
            if timeManagement.isDarkModeEnabled() {
                postfix = "-dark"
            }
            
            if let imagePath = bundle.path(forResource: "icon-\(timeOfDay.title)"+postfix,
                ofType:"pdf") {
                let image = NSImage(contentsOfFile: imagePath)
                image!.size.width = 13
                image!.size.height = 13
                view.imageView?.image = image
                // TODO, change the icons for dark mode

            } else {
                NSLog("\(#file) failed to find time of day icon")
            }
            
            return view
        case is AerialVideo:
            let video = item as! AerialVideo
            let view = outlineView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("CheckCell"),
                                        owner: nil) as! CheckCellView   // if owner = self, awakeFromNib will be called for each created cell !
            // Mark the new view for this video for subsequent callbacks
            let videoManager = VideoManager.sharedInstance
            videoManager.addCheckCellView(id: video.id, checkCellView: view)

            view.setVideo(video: video)     // For our Add button
            view.adaptIndicators()

            if (video.secondaryName != "") {
                view.textField?.stringValue = video.secondaryName
            }
            else {
                // One based index
                let number = video.arrayPosition + 1
                let numberFormatter = NumberFormatter()
                
                numberFormatter.numberStyle = NumberFormatter.Style.spellOut
                guard
                    let numberString = numberFormatter.string(from: number as NSNumber)
                    else {
                        print("failed to create number with formatter")
                        return nil
                }
                
                view.textField?.stringValue = numberString.capitalized
            }


            
            let isInRotation = preferences.videoIsInRotation(videoID: video.id)
            
            if isInRotation {
                view.checkButton.state = NSControl.StateValue.on
            } else {
                view.checkButton.state = NSControl.StateValue.off
            }
            
            view.onCheck = { checked in
                self.preferences.setVideo(videoID: video.id,
                                          inRotation: checked)
            }

            return view
        default:
            return nil
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        switch item {
        case is AerialVideo:
            player = AVPlayer()
            playerView.player = player
            
            let video = item as! AerialVideo
            debugLog("playing this preview \(video)")
            // Workaround for cached videos generating online traffic
            if video.isAvailableOffline {
                previewDisabledTextfield.isHidden = true
                let localurl = URL(fileURLWithPath: VideoCache.cachePath(forVideo: video)!)
                let localitem = AVPlayerItem(url: localurl)
                player.replaceCurrentItem(with: localitem)
                player.play()
            }
            else if !preferences.neverStreamPreviews {
                previewDisabledTextfield.isHidden = true
                let asset = CachedOrCachingAsset(video.url)
                let item = AVPlayerItem(asset: asset)
                player.replaceCurrentItem(with: item)
                player.play()
            } else {
                previewDisabledTextfield.isHidden = false
            }
            
            return true
        case is TimeOfDay:
            return false
        default:
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        switch item {
            case is AerialVideo:
                return 19
            case is TimeOfDay:
                return 18
            case is City:
                return 17
            default:
                fatalError("unhandled item in heightOfRowByItem for \(item)")
        }
    }
    func outlineView(_ outlineView: NSOutlineView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - Caching
    
    @IBOutlet var totalProgress: NSProgressIndicator!
    @IBOutlet var currentProgress: NSProgressIndicator!
    @IBOutlet var cacheStatusLabel: NSTextField!
    var currentVideoDownload: VideoDownload?
    var manifestVideos: [AerialVideo]?
    
    @IBAction func cacheAllNow(_ button: NSButton) {
       cacheStatusLabel.stringValue = "Loading JSON"
        currentProgress.maxValue = 1
        
        ManifestLoader.instance.addCallback { (manifestVideos: [AerialVideo]) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.manifestVideos = manifestVideos
                self.cacheNextVideo()
                
            })
        }
    }
    
    func cacheNextVideo() {
        guard let manifestVideos = self.manifestVideos else {
            cacheStatusLabel.stringValue = "Couldn't load manifest!"
            return
        }
        
        let uncached = manifestVideos.filter { (video) -> Bool in
            return video.isAvailableOffline == false
        }
        
        NSLog("uncached: \(uncached)")
        
        totalProgress.maxValue = Double(manifestVideos.count)
        totalProgress.doubleValue = Double(manifestVideos.count) - Double(uncached.count)
        NSLog("total process max value: \(totalProgress.maxValue), current value: \(totalProgress.doubleValue)")
        
        if uncached.count == 0 {
            cacheStatusLabel.stringValue = "All videos have been cached"
            return
        }
        
        let video = uncached[0]
        
        // find video that hasn't been cached
        let videoDownload = VideoDownload(video: video, delegate: self)
        
        cacheStatusLabel.stringValue = "Caching video \(video.name) \(video.timeOfDay.capitalized): \(video.url)"
        
        currentVideoDownload = videoDownload
        videoDownload.startDownload()
    }
 
    // MARK: - Video Download Delegate
    
    func videoDownload(_ videoDownload: VideoDownload,
                       finished success: Bool, errorMessage: String?) {
        if let message = errorMessage {
            cacheStatusLabel.stringValue = message
        } else {
            cacheNextVideo()
        }
        
        preferences.synchronize()
        outlineView.reloadData()
        NSLog("video download finished with success: \(success))")
    }
    
    func videoDownload(_ videoDownload: VideoDownload, receivedBytes: Int, progress: Float) {
        currentProgress.doubleValue = Double(progress)
//     NSLog("received bytes: \(receivedBytes), progress: \(progress)")
    }
    
}

extension PreferencesWindowController : NSFontChanging  {
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        return [.size, .collection, .face]
    }
    
    func changeFont(_ sender: NSFontManager?) {
        print("change font")
        // Set current font
        var oldFont = NSFont(name: "Helvetica Neue Medium", size: 28)

        if (fontEditing == 0) {
            if let tryFont = NSFont(name: preferences.fontName!,size: CGFloat(preferences.fontSize!)) {
                oldFont = tryFont
            }
        } else {
            if let tryFont = NSFont(name: preferences.extraFontName!,size: CGFloat(preferences.extraFontSize!)) {
                oldFont = tryFont
            }
        }
        
        
        let newFont = sender?.convert(oldFont!)

        if (fontEditing == 0) {
            preferences.fontName = newFont?.fontName
            preferences.fontSize = Double((newFont?.pointSize)!)
            
            // Update our label
            currentFontLabel.stringValue = preferences.fontName! + ", \(preferences.fontSize!) pt"
        } else {
            preferences.extraFontName = newFont?.fontName
            preferences.extraFontSize = Double((newFont?.pointSize)!)
            
            // Update our label
            extraMessageFontLabel.stringValue = preferences.extraFontName! + ", \(preferences.extraFontSize!) pt"
        }
        preferences.synchronize()
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSControlStateValue(_ input: NSControl.StateValue) -> Int {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSUserInterfaceItemIdentifier(_ input: String) -> NSUserInterfaceItemIdentifier {
	return NSUserInterfaceItemIdentifier(rawValue: input)
}

