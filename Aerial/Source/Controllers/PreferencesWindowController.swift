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
    
    func addVideoForTimeOfDay(timeOfDay:String, video:AerialVideo) {
        if timeOfDay.lowercaseString == "night" {
            video.arrayPosition = night.videos.count;
            night.videos.append(video);
        }
        else {
            video.arrayPosition = day.videos.count;
            day.videos.append(video);
        }
    }
}

@objc(PreferencesWindowController) class PreferencesWindowController: NSWindowController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    @IBOutlet var outlineView:NSOutlineView?
    @IBOutlet var playerView:AVPlayerView!
    @IBOutlet var differentAerialCheckbox:NSButton!
    @IBOutlet var projectPageLink:NSButton!
    @IBOutlet var cacheLocation:NSPathControl!
    @IBOutlet var cacheAerialsAsTheyPlayCheckbox:NSButton!
    
    var player:AVPlayer = AVPlayer()
    let defaults:NSUserDefaults = ScreenSaverDefaults(forModuleWithName: "com.JohnCoates.Aerial")! as ScreenSaverDefaults
    
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
        playerView.controlsStyle = .None;
        if #available(OSX 10.10, *) {
            playerView.videoGravity = AVLayerVideoGravityResizeAspectFill
        };
        defaults.synchronize();
        
        if defaults.boolForKey("differentDisplays") == true {
            differentAerialCheckbox.state = NSOnState;
        }
        
        if defaults.boolForKey("disableCache") == true {
            cacheAerialsAsTheyPlayCheckbox.state = NSOffState
        }
        
        // blue link
        let color = NSColor(calibratedRed:0.18, green:0.39, blue:0.76, alpha:1);
        let coloredTitle = NSMutableAttributedString(attributedString: projectPageLink.attributedTitle);
        let titleRange = NSMakeRange(0, coloredTitle.length);
        coloredTitle.addAttribute(NSForegroundColorAttributeName, value: color, range: titleRange);
        projectPageLink.attributedTitle = coloredTitle;
        
        if let cacheDirectory = VideoCache.cacheDirectory {
            cacheLocation.URL = NSURL(fileURLWithPath: cacheDirectory as String)
        }
        

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
    
    @IBAction func cacheAerialsAsTheyPlayClick(button:NSButton!) {
        debugLog("cache aerials as they play: \(button.state)");
        
        if button.state == NSOnState {
            defaults.setBool(false, forKey: "disableCache");
        }
        else {
            defaults.setBool(true, forKey: "disableCache");
        }
        
        defaults.synchronize();
    }
    
    @IBAction func userSetCacheLocation(button:NSButton?) {
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseDirectories = true;
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Choose Aerial Cache Directory"
        openPanel.prompt = "Choose"
        openPanel.directoryURL = cacheLocation.URL
        
        openPanel.beginWithCompletionHandler { (result:Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if openPanel.URLs.count > 0 {
                    let cacheDirectory = openPanel.URLs[0];
                    self.defaults.setObject(cacheDirectory.path, forKey: "cacheDirectory");
                    self.defaults.synchronize()
                    self.cacheLocation.URL = cacheDirectory
                }
            }
        }
    }
    @IBAction func resetCacheLocation(button:NSButton?) {
        defaults.removeObjectForKey("cacheDirectory");
        defaults.synchronize()
        if let cacheDirectory = VideoCache.cacheDirectory {
            cacheLocation.URL = NSURL(fileURLWithPath: cacheDirectory as String)
        }
    }
    
    @IBAction func outlineViewSettingsClick(button:NSButton) {
        let menu = NSMenu()
        menu.insertItemWithTitle("Uncheck All",
            action: "outlineViewUncheckAll:",
            keyEquivalent: "",
            atIndex: 0);
        
        menu.insertItemWithTitle("Check All",
            action: "outlineViewCheckAll:",
            keyEquivalent: "",
            atIndex: 1);
        
        let event = NSApp.currentEvent;
        NSMenu.popUpContextMenu(menu, withEvent: event!, forView: button);
    }
    
    
    func outlineViewUncheckAll(button:NSButton) {
        setChecked(false);
    }
    
    func outlineViewCheckAll(button:NSButton) {
        setChecked(true);
    }
    
    func setChecked(checked:Bool) {
        guard let videos = videos else {
            return;
        }
        
        for video in videos {
            self.defaults.setBool(checked, forKey: video.id);
        }
        self.defaults.synchronize();
        
        outlineView!.reloadData()
    }
    
    @IBAction func differentAerialsOnEachDisplayCheckClick(button:NSButton?) {
        let state = differentAerialCheckbox.state;
        
        let onState:Bool = state == NSOnState;

        defaults.setBool(onState, forKey: "differentDisplays");
        defaults.synchronize();
        
        debugLog("set differentDisplays to \(onState)");
    }
    
    @IBAction func pageProjectClick(button:NSButton?) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: "http://github.com/JohnCoates/Aerial")!);
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
    
    func loadedManifestWithVideos(manifestVideos:[AerialVideo]) {
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
        let sortedCities = unsortedCities.sort { $0.name < $1.name };

        self.cities = sortedCities;
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.outlineView?.reloadData();
            self.outlineView?.expandItem(nil, expandChildren: true);
        })

    }

    @IBAction func close(sender: AnyObject?) {
        NSApp.mainWindow?.endSheet(window!);
    }

    
    // MARK: - Outline View Delegate & Data Source
    
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
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
                    count++;
                }
                
                if city.day.videos.count > 0 {
                    count++;
                }
                
                return count;
            default:
                return 0;
        }
        
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        switch item {
        case is TimeOfDay:
            return true;
        case is City: // cities
            return true;
        default:
            return false;
        }
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
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
    
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
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
    
    func outlineView(outlineView: NSOutlineView, shouldEditTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> Bool {
        return false;
    }
    
    func outlineView(outlineView: NSOutlineView, dataCellForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSCell? {
        let row = outlineView.rowForItem(item);
        return tableColumn!.dataCellForRow(row) as? NSCell;
    }
    
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        switch item {
        case is TimeOfDay:
            return true;
        case is City:
            return true;
        default:
            return false;
        }
    }

    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        switch item {
        case is City:
            
            let city = item as! City;
            let view = outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as? NSTableCellView
            
            view?.textField?.stringValue = city.name;
            
            return view;
        case is TimeOfDay:
            let view = outlineView.makeViewWithIdentifier("DataCell", owner: self) as? NSTableCellView
            
            let timeOfDay = item as! TimeOfDay;
            view?.textField?.stringValue = timeOfDay.title.capitalizedString;
            let bundle = NSBundle(forClass: PreferencesWindowController.self);
            let imagePath = bundle.pathForResource("icon-\(timeOfDay.title)", ofType:"pdf");
            let image = NSImage(contentsOfFile: imagePath!);
            view?.imageView?.image = image;
            return view;
        case is AerialVideo:
            let view = outlineView.makeViewWithIdentifier("CheckCell", owner: self) as? CheckCellView
            
            
            let video = item as! AerialVideo;
            let number = video.arrayPosition + 1;
            let numberFormatter = NSNumberFormatter();
            
            numberFormatter.numberStyle = NSNumberFormatterStyle.SpellOutStyle;
            let numberString = numberFormatter.stringFromNumber(number);
            view?.textField?.stringValue = numberString!.capitalizedString;
            
            let settingValue = defaults.objectForKey(video.id);
            
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
                self.defaults.setBool(checked, forKey: video.id);
                self.defaults.synchronize();
            };
            
            return view;
        default:
            return nil;
        }
    }
    
    func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        switch item {
        case is AerialVideo:
            player = AVPlayer()
            playerView.player = player;
            
            let video = item as! AerialVideo;
            
            let asset = CachedOrCachingAsset(video.url);
//            let asset = AVAsset(URL: video.url);
            
            let item = AVPlayerItem(asset: asset);
            
            player.replaceCurrentItemWithPlayerItem(item);
            player.play();
            
            return true;
        case is TimeOfDay:
            return false;
        default:
            return false;
        }
    }
    
    func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat {
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
    
}
