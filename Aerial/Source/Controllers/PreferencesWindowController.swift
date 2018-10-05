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
    @IBOutlet var differentAerialCheckbox: NSButton!
    @IBOutlet var showDescriptionsCheckbox: NSButton!
    @IBOutlet var localizeForTvOS12Checkbox: NSButton!
    @IBOutlet var projectPageLink: NSButton!
    @IBOutlet var secondProjectPageLink: NSButton!
    @IBOutlet var cacheLocation: NSPathControl!
    @IBOutlet var cacheAerialsAsTheyPlayCheckbox: NSButton!
    @IBOutlet var neverStreamVideosCheckbox: NSButton!
    @IBOutlet var popupVideoFormat: NSPopUpButton!
    @IBOutlet var descriptionModePopup: NSPopUpButton!
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

    var player: AVPlayer = AVPlayer()
    
    var videos: [AerialVideo]?
    // cities -> time of day -> videos
    var cities = [City]()
    
    static var loadedJSON: Bool = false
    
    lazy var preferences = Preferences.sharedInstance
    
    // MARK: - Init
    var awakenAlready = false
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    override init(window: NSWindow?) {
        super.init(window: window)
        
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let previewPlayer = AerialView.previewPlayer {
            self.player = previewPlayer
        }
        

        outlineView.floatsGroupRows = false
        loadJSON()

        if let version = Bundle(identifier: "com.johncoates.Aerial-Test")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.stringValue = version
        }
        if let version = Bundle(identifier: "com.JohnCoates.Aerial")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.stringValue = version
        }

        if #available(OSX 10.12.2, *) {
            iconTime1.image = NSImage(named: NSImage.touchBarHistoryTemplateName)
            iconTime2.image = NSImage(named: NSImage.touchBarComposeTemplateName)
        }
        
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
            popoverH264Label.stringValue = "MacOS 10.13 or above required"
            popoverHEVCLabel.stringValue = "Hardware acceleration status unknown"
        }

        playerView.player = player
        playerView.controlsStyle = .none
        if #available(OSX 10.10, *) {
            playerView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }
        
        if preferences.differentAerialsOnEachDisplay {
            differentAerialCheckbox.state = NSControl.StateValue.on
        }
        
        if preferences.showDescriptions {
            showDescriptionsCheckbox.state = NSControl.StateValue.on
        }

        if preferences.localizeDescriptions {
            localizeForTvOS12Checkbox.state = NSControl.StateValue.on
        }
        
        if preferences.neverStreamVideos {
            neverStreamVideosCheckbox.state = NSControl.StateValue.on
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
        
        // Handle the radio button
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
        
        
        popupVideoFormat.selectItem(at: preferences.videoFormat!)
        
        descriptionModePopup.selectItem(at: preferences.showDescriptionsMode!)
        
        colorizeProjectPageLinks()
        
        if let cacheDirectory = VideoCache.cacheDirectory {
            cacheLocation.url = URL(fileURLWithPath: cacheDirectory as String)
        }
        
        cacheStatusLabel.isEditable = false
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
    
    @IBAction func neverStreamVideosClick(_ button: NSButton!) {
        debugLog("never stream videos: \(convertFromNSControlStateValue(button.state))")
        
        let onState = (button.state == NSControl.StateValue.on)
        preferences.neverStreamVideos = onState
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
    
    @IBAction func outlineViewSettingsClick(_ button: NSButton) {
        let menu = NSMenu()
        menu.insertItem(withTitle: "Uncheck All",
            action: #selector(PreferencesWindowController.outlineViewUncheckAll(button:)),
            keyEquivalent: "",
            at: 0)
        
        menu.insertItem(withTitle: "Check All",
            action: #selector(PreferencesWindowController.outlineViewCheckAll(button:)),
            keyEquivalent: "",
            at: 1)
        
        let event = NSApp.currentEvent
        NSMenu.popUpContextMenu(menu, with: event!, for: button)
    }

    @IBAction func popupVideoFormatChange(_ sender:NSPopUpButton) {
        NSLog("index change : \(sender.indexOfSelectedItem)")
        preferences.videoFormat = sender.indexOfSelectedItem
    }
    
    @IBAction func descriptionModePopupChange(_ sender:NSPopUpButton) {
        NSLog("dindex change : \(sender.indexOfSelectedItem)")
        
        preferences.showDescriptionsMode = sender.indexOfSelectedItem
    }
    

    @objc func outlineViewUncheckAll(button: NSButton) {
        setAllVideos(inRotation: false)
    }
    
    @objc func outlineViewCheckAll(button: NSButton) {
        setAllVideos(inRotation: true)
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
    
    @IBAction func differentAerialsOnEachDisplayCheckClick(_ button: NSButton?) {
        let state = differentAerialCheckbox.state
        let onState = (state == NSControl.StateValue.on)
        
        preferences.differentAerialsOnEachDisplay = onState
        
        debugLog("set differentAerialsOnEachDisplay to \(onState)")
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

    
    // MARK: - Link
    
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

    @IBAction func close(_ sender: AnyObject?) {
        window?.sheetParent?.endSheet(window!)
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
            if let imagePath = bundle.path(forResource: "icon-\(timeOfDay.title)",
                ofType:"pdf") {
                let image = NSImage(contentsOfFile: imagePath)
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
                let localurl = URL(fileURLWithPath: VideoCache.cachePath(forVideo: video)!)
                let localitem = AVPlayerItem(url: localurl)
                player.replaceCurrentItem(with: localitem)
            }
            else {
                let asset = CachedOrCachingAsset(video.url)
                let item = AVPlayerItem(asset: asset)
                player.replaceCurrentItem(with: item)
            }
            
            player.play()
            
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
                return 17
            case is TimeOfDay:
                return 18
            case is City:
                return 17
            default:
                fatalError("unhandled item in heightOfRowByItem for \(item)")
        }
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
        
         NSLog("video download finished with success: \(success))")
    }
    
    func videoDownload(_ videoDownload: VideoDownload, receivedBytes: Int, progress: Float) {
        currentProgress.doubleValue = Double(progress)
//     NSLog("received bytes: \(receivedBytes), progress: \(progress)")
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
