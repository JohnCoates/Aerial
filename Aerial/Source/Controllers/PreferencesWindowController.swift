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

class TimeOfDay {
    let title:String;
    var videos:[AerialVideo] = [AerialVideo]()
    
    init(title:String) {
        self.title = title;
    }
    
}

class City {
    var night:TimeOfDay = TimeOfDay(title: "night");
    var day:TimeOfDay = TimeOfDay(title: "day");
    let name:String;
    
    init(name:String) {
        self.name = name;
    }
    
    func addVideoForTimeOfDay(_ timeOfDay:String, video:AerialVideo) {
        if timeOfDay.lowercased() == "night" {
            video.arrayPosition = night.videos.count;
            night.videos.append(video);
        }
        else {
            video.arrayPosition = day.videos.count;
            day.videos.append(video);
        }
    }
}

@objc(PreferencesWindowController) class PreferencesWindowController: NSWindowController, NSOutlineViewDataSource, NSOutlineViewDelegate, VideoDownloadDelegate {

    @IBOutlet var outlineView:NSOutlineView?
    @IBOutlet var playerView:AVPlayerView!
    @IBOutlet var differentAerialCheckbox:NSButton!
    @IBOutlet var projectPageLink:NSButton!
    @IBOutlet var cacheLocation:NSPathControl!
    @IBOutlet var cacheAerialsAsTheyPlayCheckbox:NSButton!
    
    var player:AVPlayer = AVPlayer()
    let defaults:UserDefaults = ScreenSaverDefaults(forModuleWithName: "com.JohnCoates.Aerial")! as ScreenSaverDefaults
    
    var videos:[AerialVideo]?
    // cities -> time of day -> videos
    var cities = [City]();
    
    static var loadedJSON:Bool = false;
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let previewPlayer = AerialView.previewPlayer {
            self.player = previewPlayer;
        }
        
        outlineView?.floatsGroupRows = false;
        loadJSON();
        
        playerView.player = player;
        playerView.controlsStyle = .none;
        if #available(OSX 10.10, *) {
            playerView.videoGravity = AVLayerVideoGravityResizeAspectFill
        };
        defaults.synchronize();
        
        if defaults.bool(forKey: "differentDisplays") == true {
            differentAerialCheckbox.state = NSOnState;
        }
        
        if defaults.bool(forKey: "disableCache") == true {
            cacheAerialsAsTheyPlayCheckbox.state = NSOffState
        }
        
        // blue link
        let color = NSColor(calibratedRed:0.18, green:0.39, blue:0.76, alpha:1);
        let coloredTitle = NSMutableAttributedString(attributedString: projectPageLink.attributedTitle);
        let titleRange = NSMakeRange(0, coloredTitle.length);
        coloredTitle.addAttribute(NSForegroundColorAttributeName, value: color, range: titleRange);
        projectPageLink.attributedTitle = coloredTitle;
        
        if let cacheDirectory = VideoCache.cacheDirectory {
            cacheLocation.url = URL(fileURLWithPath: cacheDirectory as String)
        }
        
        cacheStatusLabel.isEditable = false;
        

    }
    
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    override init(window: NSWindow?) {
        super.init(window: window)
        
    }
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    @IBAction func cacheAerialsAsTheyPlayClick(_ button:NSButton!) {
        debugLog("cache aerials as they play: \(button.state)");
        
        if button.state == NSOnState {
            defaults.set(false, forKey: "disableCache");
        }
        else {
            defaults.set(true, forKey: "disableCache");
        }
        
        defaults.synchronize();
    }
    
    @IBAction func userSetCacheLocation(_ button:NSButton?) {
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseDirectories = true;
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Choose Aerial Cache Directory"
        openPanel.prompt = "Choose"
        openPanel.directoryURL = cacheLocation.url
        
        openPanel.begin { (result:Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if openPanel.urls.count > 0 {
                    let cacheDirectory = openPanel.urls[0];
                    self.defaults.set(cacheDirectory.path, forKey: "cacheDirectory");
                    self.defaults.synchronize()
                    self.cacheLocation.url = cacheDirectory
                }
            }
        }
    }
    @IBAction func resetCacheLocation(_ button:NSButton?) {
        defaults.removeObject(forKey: "cacheDirectory");
        defaults.synchronize()
        if let cacheDirectory = VideoCache.cacheDirectory {
            cacheLocation.url = URL(fileURLWithPath: cacheDirectory as String)
        }
    }
    
    @IBAction func outlineViewSettingsClick(_ button:NSButton) {
        let menu = NSMenu()
        menu.insertItem(withTitle: "Uncheck All",
            action: #selector(PreferencesWindowController.outlineViewUncheckAll(_:)),
            keyEquivalent: "",
            at: 0);
        
        menu.insertItem(withTitle: "Check All",
            action: #selector(PreferencesWindowController.outlineViewCheckAll(_:)),
            keyEquivalent: "",
            at: 1);
        
        let event = NSApp.currentEvent;
        NSMenu.popUpContextMenu(menu, with: event!, for: button);
    }
    
    
    func outlineViewUncheckAll(_ button:NSButton) {
        setChecked(false);
    }
    
    func outlineViewCheckAll(_ button:NSButton) {
        setChecked(true);
    }
    
    func setChecked(_ checked:Bool) {
        guard let videos = videos else {
            return;
        }
        
        for video in videos {
            self.defaults.set(checked, forKey: video.id);
        }
        self.defaults.synchronize();
        
        outlineView!.reloadData()
    }
    
    @IBAction func differentAerialsOnEachDisplayCheckClick(_ button:NSButton?) {
        let state = differentAerialCheckbox.state;
        
        let onState:Bool = state == NSOnState;

        defaults.set(onState, forKey: "differentDisplays");
        defaults.synchronize();
        
        debugLog("set differentDisplays to \(onState)");
    }
    
    @IBAction func pageProjectClick(_ button:NSButton?) {
        NSWorkspace.shared().open(URL(string: "http://github.com/JohnCoates/Aerial")!);
    }
    
    func loadJSON() {
        if (PreferencesWindowController.loadedJSON) {
            return;
        }
        PreferencesWindowController.loadedJSON = true;
        
        ManifestLoader.instance.addCallback { (manifestVideos:[AerialVideo]) -> Void in
            self.loadedManifestWithVideos(manifestVideos)
       };
    }
    
    func loadedManifestWithVideos(_ manifestVideos:[AerialVideo]) {
        var videos = [AerialVideo]();
        var cities = [String:City]();
        for video in manifestVideos {
            let name = video.name
            
            if cities.keys.contains(name) == false {
                cities[name] = City(name: name);
            }
        
            let city:City = cities[name]!;
        
            let timeOfDay = video.timeOfDay
            city.addVideoForTimeOfDay(timeOfDay, video: video);
            videos.append(video)
        }


        self.videos = videos;
        
        // sort cities by name
        let unsortedCities = cities.values;
        let sortedCities = unsortedCities.sorted { $0.name < $1.name };

        self.cities = sortedCities;
        DispatchQueue.main.async(execute: { () -> Void in
            self.outlineView?.reloadData();
            self.outlineView?.expandItem(nil, expandChildren: true);
        })

    }

    @IBAction func close(_ sender: AnyObject?) {
        NSApp.mainWindow?.endSheet(window!);
    }

    
    // MARK: - Outline View Delegate & Data Source
    
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return cities.count;
        }
        
        switch item {
            case is TimeOfDay:
                let timeOfDay = item as! TimeOfDay;
                return timeOfDay.videos.count;
            case is City:
                let city = item as! City;
                
                var count = 0;
                
                if city.night.videos.count > 0 {
                    count += 1;
                }
                
                if city.day.videos.count > 0 {
                    count += 1;
                }
                
                return count;
            default:
                return 0;
        }
        
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        switch item {
        case is TimeOfDay:
            return true;
        case is City: // cities
            return true;
        default:
            return false;
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return cities[index];
        }
        
        switch item {
        case is City:
            let city = item as! City;
            
            if (index == 0 && city.day.videos.count > 0) {
                return city.day;
            }
            else {
                return city.night;
            }
            
        case is TimeOfDay:
            let timeOfDay = item as! TimeOfDay;
            return timeOfDay.videos[index];
        
        default:
            return false;
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        switch item {
        case is City:
            let city = item as! City;
            return city.name;
        case is TimeOfDay:
            let timeOfDay = item as! TimeOfDay;
            return timeOfDay.title;
            
        default:
            return "untitled";
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        return false;
    }
    
    func outlineView(_ outlineView: NSOutlineView, dataCellFor tableColumn: NSTableColumn?, item: Any) -> NSCell? {
        let row = outlineView.row(forItem: item);
        return tableColumn!.dataCell(forRow: row) as? NSCell;
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        switch item {
        case is TimeOfDay:
            return true;
        case is City:
            return true;
        default:
            return false;
        }
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        switch item {
        case is City:
            
            let city = item as! City;
            let view = outlineView.make(withIdentifier: "HeaderCell", owner: self) as? NSTableCellView
            
            view?.textField?.stringValue = city.name;
            
            return view;
        case is TimeOfDay:
            let view = outlineView.make(withIdentifier: "DataCell", owner: self) as? NSTableCellView
            
            let timeOfDay = item as! TimeOfDay;
            view?.textField?.stringValue = timeOfDay.title.capitalized;
            let bundle = Bundle(for: PreferencesWindowController.self);
            let imagePath = bundle.path(forResource: "icon-\(timeOfDay.title)", ofType:"pdf");
            let image = NSImage(contentsOfFile: imagePath!);
            view?.imageView?.image = image;
            return view;
        case is AerialVideo:
            let view = outlineView.make(withIdentifier: "CheckCell", owner: self) as? CheckCellView
            
            
            let video = item as! AerialVideo;
            let number = video.arrayPosition + 1;
            let numberFormatter = NumberFormatter();
            
            numberFormatter.numberStyle = NumberFormatter.Style.spellOut;
            let numberString = numberFormatter.string(from: number as NSNumber);
            view?.textField?.stringValue = numberString!.capitalized;
            
            let settingValue = defaults.object(forKey: video.id);
            
            if let settingValue = settingValue as? NSNumber {
                if settingValue.boolValue == false {
                    view?.checkButton.state = NSOffState;
                }
                else {
                    view?.checkButton.state = NSOnState;
                }
            }
            else {
                view?.checkButton.state = NSOnState;
            }
            
            
            view?.onCheck = { (checked:Bool) in
                self.defaults.set(checked, forKey: video.id);
                self.defaults.synchronize();
            };
            
            return view;
        default:
            return nil;
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        switch item {
        case is AerialVideo:
            player = AVPlayer()
            playerView.player = player;
            
            let video = item as! AerialVideo;
            
            let asset = CachedOrCachingAsset(video.url);
//            let asset = AVAsset(URL: video.url);
            
            let item = AVPlayerItem(asset: asset);
            
            player.replaceCurrentItem(with: item);
            player.play();
            
            
            return true;
        case is TimeOfDay:
            return false;
        default:
            return false;
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        switch item {
        case is AerialVideo:
            return 18;
        case is TimeOfDay:
            return 18;
        case is City:
            return 18;
        default:
            return 0;
        }
    }
    
    // MARK: - Caching
    @IBOutlet var totalProgress:NSProgressIndicator!
    @IBOutlet var currentProgress:NSProgressIndicator!
    @IBOutlet var cacheStatusLabel:NSTextField!
    var currentVideoDownload:VideoDownload?
    var manifestVideos:[AerialVideo]?
    
    @IBAction func cacheAllNow(_ button:NSButton) {
       cacheStatusLabel.stringValue = "Loading JSON"
        currentProgress.maxValue = 1;
        
        ManifestLoader.instance.addCallback { (manifestVideos:[AerialVideo]) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.manifestVideos = manifestVideos
                self.cacheNextVideo()
                
            })
        };
    }
    
    
    func cacheNextVideo() {
        guard let manifestVideos = self.manifestVideos else {
            cacheStatusLabel.stringValue = "Couldn't load manifest!"
            return;
        }
        
        let uncached = manifestVideos.filter { (video) -> Bool in
            return video.isAvailableOffline == false
        }
        
        
        if uncached.count == 0 {
            cacheStatusLabel.stringValue = "All videos have been cached"
            return;
        }
        
        NSLog("unached: \(uncached)")
        
        totalProgress.maxValue = Double(manifestVideos.count)
        totalProgress.doubleValue = Double(manifestVideos.count) - Double(uncached.count)
        NSLog("total process max value: \(totalProgress.maxValue), current value: \(totalProgress.doubleValue)")
        
        
        let video = uncached[0];
        
        // find video that hasn't been cached
        let videoDownload = VideoDownload(video: video, delegate: self)
        
        cacheStatusLabel.stringValue = "Caching video \(video.name) \(video.timeOfDay.capitalized): \(video.id)"
        
        currentVideoDownload = videoDownload
        videoDownload.startDownload()
    }
 
    // MARK: - Video Download Delegate
    
    func videoDownload(_ videoDownload:VideoDownload , finished success:Bool, errorMessage:String?) {
        
        if let message = errorMessage {
            cacheStatusLabel.stringValue = message
        }
        else {
            cacheNextVideo()
        }
        
         NSLog("video download finished with success: \(success))")
    }
    
    func videoDownload(_ videoDownload:VideoDownload, receivedBytes:Int, progress:Float) {
        currentProgress.doubleValue = Double(progress)
//     NSLog("received bytes: \(receivedBytes), progress: \(progress)")
    }
    
}
