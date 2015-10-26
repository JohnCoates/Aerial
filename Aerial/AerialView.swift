//
//  AerialView.swift
//  Aerial
//
//  Created by John Coates on 10/22/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import ScreenSaver
import AVFoundation
import AVKit

typealias manifestLoadCallback = ([AerialVideo]) -> (Void);

// shuffling thanks to Nate Cook http://stackoverflow.com/questions/24026510/how-do-i-shuffle-an-array-in-swift
extension CollectionType {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Generator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}

class ManifestLoader {
    static let instance:ManifestLoader = ManifestLoader();
    
    let defaults:NSUserDefaults = ScreenSaverDefaults(forModuleWithName: "com.JohnCoates.Aerial")! as ScreenSaverDefaults
    var callbacks = [manifestLoadCallback]();
    var loadedManifest = [AerialVideo]();
    var playedVideos = [AerialVideo]();
    
    func addCallback(callback:manifestLoadCallback) {
        if (loadedManifest.count > 0) {
            callback(loadedManifest);
        }
        else {
            callbacks.append(callback);
        }
    }
    
    func randomVideo() -> AerialVideo? {
        
        let shuffled = loadedManifest.shuffle();
        
        for video in shuffled {
            let possible = defaults.objectForKey(video.id);
            
            if let possible = possible as? NSNumber {
                if possible.boolValue == false {
                    continue;
                }
            }
            
            return video;
        }
        
        // nothing available??? return first thing we find
        return shuffled.first;
    }
    
    init() {
        // start loading right away!
        let completionHandler = { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            guard let data = data else {
                NSLog("Couldn't load manifest!");
                return;
            }
            
            if let error = error {
                NSLog("Error! \(error)");
                return;
            }
            
            var videos = [AerialVideo]();
            
            do {
                let batches = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! Array<NSDictionary>;
                
                for batch:NSDictionary in batches {
                    let assets = batch["assets"] as! Array<NSDictionary>;
                    
                    for item in assets {
                        let url = item["url"] as! String;
                        let name = item["accessibilityLabel"] as! String;
                        let timeOfDay = item["timeOfDay"] as! String;
                        let id = item["id"] as! String;
                        let type = item["type"] as! String;
                        
                        if (type != "video") {
                            continue;
                        }
                        
                        
                        let video = AerialVideo(id: id, name: name, type: type, timeOfDay: timeOfDay, url: url);
                        
                        videos.append(video)
                    }
                }
                
                self.loadedManifest = videos;
                NSLog("loaded videos: \(videos)");
                
                // callbacks
                for callback in self.callbacks {
                    callback(videos);
                }
                self.callbacks.removeAll()
                
            }
            catch {
                NSLog("Error retrieving content listing.");
                return;
            }
            
            
        };
        let url = NSURL(string: "http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json");
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:completionHandler);
        task.resume();
    }
}


@objc(AerialView) class AerialView : ScreenSaverView {
    var playerView: AVPlayerView!
    var playerLayer:AVPlayerLayer!
    var preferencesController:PreferencesWindowController?
    static var players:[AVPlayer] = [AVPlayer]()
    static var previewPlayer:AVPlayer?
    
    var player:AVPlayer?
    static let defaults:NSUserDefaults = ScreenSaverDefaults(forModuleWithName: "com.JohnCoates.Aerial")! as ScreenSaverDefaults
    
    static var sharingPlayers:Bool {
        defaults.synchronize();
        return !defaults.boolForKey("differentDisplays");
    }
    
    static var singlePlayerAlreadySetup:Bool = false;
    class var sharedPlayer: AVPlayer {
        struct Static {
            static let instance: AVPlayer = AVPlayer();
            static var _player:AVPlayer?;
            static var player:AVPlayer {
                if let activePlayer = _player {
//                    NSLog("returning existing player: %@", activePlayer);
                    return activePlayer;
                }
//                NSLog("preview.... constructing new player!");
//                let movieURL = NSURL(string: "http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/b10-2.mov");
//                let asset = AVAsset(URL: movieURL!);
//                
//                let item = AVPlayerItem(asset: asset);
                _player = AVPlayer();
                return _player!;
            }
        }
        
        return Static.player;
    }
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        self.animationTimeInterval = 1.0 / 30.0
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    deinit {
//        NSLog("deinit AerialView");
        NSNotificationCenter.defaultCenter().removeObserver(self);
        
        // set player item to nil if not preview player
        if player != AerialView.previewPlayer {
            player?.rate = 0;
            player?.replaceCurrentItemWithPlayerItem(nil);
        }
        
        guard let player = self.player else {
            return;
        }
        
        // Remove from player index
        
        let indexMaybe = AerialView.players.indexOf(player)
        
        guard let index = indexMaybe else {
            return;
        }
        
        AerialView.players.removeAtIndex(index);
    }
    
    
    func setupPlayerLayer(withPlayer player:AVPlayer) {
        self.layer = CALayer()
        guard let layer = self.layer else {
            NSLog("Aerial Errror: Couldn't create CALayer");
            return;
        }
        self.wantsLayer = true
        layer.backgroundColor = NSColor.blackColor().CGColor
        layer.delegate = self;
        layer.needsDisplayOnBoundsChange = true;
        layer.frame = self.bounds
        
        playerLayer = AVPlayerLayer(player: player);
        
        playerLayer.frame = layer.bounds;
        layer.addSublayer(playerLayer);
    }
    func setupPlayerView(withPlayer player:AVPlayer) {
        playerView = AVPlayerView()
        playerView.frame = self.bounds
        playerView.autoresizingMask = [.ViewHeightSizable, .ViewWidthSizable]
        playerView.controlsStyle = .None
        playerView.player = player;
        playerView.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.addSubview(playerView);
    }
    func setup() {
        
        var localPlayer:AVPlayer?
        
        if (!self.preview) {
            // check if we should share preview's player
            if (AerialView.players.count == 0) {
                if AerialView.previewPlayer != nil {
                    localPlayer = AerialView.previewPlayer;
                }
            }
        }
        
        
        if localPlayer == nil {
            if AerialView.sharingPlayers {
                if AerialView.previewPlayer != nil {
                    localPlayer = AerialView.previewPlayer
                }
                else {
                    localPlayer = AerialView.sharedPlayer;
                }
            }
            else {
                localPlayer = AVPlayer();
            }
        }
        
        guard let player = localPlayer else {
            NSLog("Aerial: Couldn't create AVPlayer!");
            return;
        }
        
        self.player = player;
        
        if (self.preview) {
            AerialView.previewPlayer = player;
        }
        else if (AerialView.sharingPlayers == false) {
            // add to player list
            AerialView.players.append(player);
        }
        
//        setupPlayerLayer(withPlayer: player);
        // view allows for video gravity
        setupPlayerView(withPlayer: player);
        
        
        if (AerialView.sharingPlayers == true && AerialView.singlePlayerAlreadySetup) {
            return;
        }
        
        AerialView.singlePlayerAlreadySetup = true;
        
        
        ManifestLoader.instance.addCallback { (videos:[AerialVideo]) -> Void in
            self.playNextVideo(player);
        };
    }
    
    /*
public let AVPlayerItemTimeJumpedNotification: String // the item's current time has changed discontinuously
@available(OSX 10.7, *)
public let AVPlayerItemDidPlayToEndTimeNotification: String // item has played to its end time
@available(OSX 10.7, *)
public let AVPlayerItemFailedToPlayToEndTimeNotification: String // item has failed to play to its end time
@available(OSX 10.9, *)
public let AVPlayerItemPlaybackStalledNotification: String // media did not arrive in time to continue playback
@available(OSX 10.9, *)
public let AVPlayerItemNewAccessLogEntryNotification: String // a new access log entry has been added
@available(OSX 10.9, *)
public let AVPlayerItemNewErrorLogEntryNotification: String // a new error log entry has been added

// notification userInfo key                                                                    type
@available(OSX 10.7, *)
public let AVPlayerItemFailedToPlayToEndTimeErrorKey: String // NSError
*/
    func playerItemFailedtoPlayToEnd(aNotification: NSNotification) {
        NSLog("AVPlayerItemFailedToPlayToEndTimeNotification \(aNotification)");
        guard let player = self.player else {
            return;
        }
        
        playNextVideo(player);
    }
    
    func playerItemNewErrorLogEntryNotification(aNotification: NSNotification) {
        NSLog("AVPlayerItemNewErrorLogEntryNotification \(aNotification)");
    }
    
    func playerItemPlaybackStalledNotification(aNotification: NSNotification) {
        NSLog("AVPlayerItemPlaybackStalledNotification \(aNotification)");
    }
    
    func playerItemDidReachEnd(aNotification: NSNotification) {
//        NSLog("played did reach end");
//        NSLog("notification: \(aNotification)");
        guard let player = self.player else {
            return;
        }

//        NSLog("playing next video for player \(player)");
        
        // play another video
        playNextVideo(player);
    }
    
    func playNextVideo(player:AVPlayer) {
        let randomVideo = ManifestLoader.instance.randomVideo();
        
        guard let video = randomVideo else {
            NSLog("error grabbing random video!");
            return;
        }
        let videoURL = video.url;
//        let videoURL = NSURL(string:"http://localhost/test.mov")!;
        
        let asset = AVAsset(URL: videoURL);
        
        let item = AVPlayerItem(asset: asset);
        player.replaceCurrentItemWithPlayerItem(item);
        
//        NSLog("playing video: \(video.url)");
        if player.rate == 0 {
            player.play();
        }
        
        guard let currentItem = player.currentItem else {
            NSLog("no current item!");
            return;
        }
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        // remove old entries
        notificationCenter.removeObserver(self);
        
//        NSLog("observing current item \(currentItem)");
        notificationCenter.addObserver(self, selector: "playerItemDidReachEnd:", name: AVPlayerItemDidPlayToEndTimeNotification, object: currentItem);
        notificationCenter.addObserver(self, selector: "playerItemNewErrorLogEntryNotification:", name: AVPlayerItemNewErrorLogEntryNotification, object: currentItem);
        notificationCenter.addObserver(self, selector: "playerItemFailedtoPlayToEnd:", name: AVPlayerItemFailedToPlayToEndTimeNotification, object: currentItem);
        notificationCenter.addObserver(self, selector: "playerItemPlaybackStalledNotification:", name: AVPlayerItemPlaybackStalledNotification, object: currentItem);
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.None;
    }
    
    override func hasConfigureSheet() -> Bool {
        return true;
    }
    
    override func configureSheet() -> NSWindow? {
        if let controller = preferencesController {
            return controller.window
        }
        
        let controller = PreferencesWindowController(windowNibName: "PreferencesWindow");
    
        preferencesController = controller;
//        controller.loadWindow();
//        controller.window?.styleMask
//        guard let window = controller.window else {
//            NSLog("no controller :(");
//            return nil;
//        }
        return controller.window;
    }
}