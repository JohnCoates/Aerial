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


@objc(AerialView) class AerialView : ScreenSaverView {
//    var playerView: AVPlayerView!
    var playerLayer:AVPlayerLayer!
    var preferencesController:PreferencesWindowController?
    static var players:[AVPlayer] = [AVPlayer]()
    static var previewPlayer:AVPlayer?
    static var previewView:AerialView?
    
    var player:AVPlayer?
    static let defaults:NSUserDefaults = ScreenSaverDefaults(forModuleWithName: "com.JohnCoates.Aerial")! as ScreenSaverDefaults
    
    static var sharingPlayers:Bool {
        defaults.synchronize();
        return !defaults.boolForKey("differentDisplays");
    }
    
    static var sharedViews:[AerialView] = []
    
    // MARK: - Shared Player
    
    static var singlePlayerAlreadySetup:Bool = false;
    class var sharedPlayer: AVPlayer {
        struct Static {
            static let instance: AVPlayer = AVPlayer();
            static var _player:AVPlayer?;
            static var player:AVPlayer {
                if let activePlayer = _player {
                    return activePlayer;
                }

                _player = AVPlayer();
                return _player!;
            }
        }
        
        return Static.player;
    }
    
    // MARK: - Init / Setup
    
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
        debugLog("deinit AerialView");
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
//        layer.backgroundColor = NSColor.greenColor().CGColor
        
        debugLog("setting up player layer with frame: \(self.bounds) / \(self.frame)");
        
        playerLayer = AVPlayerLayer(player: player);
        if #available(OSX 10.10, *) {
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        };
        playerLayer.autoresizingMask = [CAAutoresizingMask.LayerWidthSizable, CAAutoresizingMask.LayerHeightSizable]
        playerLayer.frame = layer.bounds;
        layer.addSublayer(playerLayer);
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
        else {
            AerialView.previewView = self;
        }
        
        if AerialView.sharingPlayers {
            AerialView.sharedViews.append(self);
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
            NSLog("Aerial Error: Couldn't create AVPlayer!");
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
        
        setupPlayerLayer(withPlayer: player);
        
        
        if (AerialView.sharingPlayers == true && AerialView.singlePlayerAlreadySetup) {
            self.playerLayer.player = AerialView.sharedViews[0].player
            return;
        }
        
        AerialView.singlePlayerAlreadySetup = true;
        
        
        ManifestLoader.instance.addCallback { (videos:[AerialVideo]) -> Void in
            self.playNextVideo();
        };
    }
    
    
    // MARK: - AVPlayerItem Notifications
    
    func playerItemFailedtoPlayToEnd(aNotification: NSNotification) {
        NSLog("AVPlayerItemFailedToPlayToEndTimeNotification \(aNotification)");
        
        playNextVideo();
    }
    
    func playerItemNewErrorLogEntryNotification(aNotification: NSNotification) {
        NSLog("AVPlayerItemNewErrorLogEntryNotification \(aNotification)");
    }
    
    func playerItemPlaybackStalledNotification(aNotification: NSNotification) {
        NSLog("AVPlayerItemPlaybackStalledNotification \(aNotification)");
    }
    
    func playerItemDidReachEnd(aNotification: NSNotification) {
        debugLog("played did reach end");
        debugLog("notification: \(aNotification)");
        playNextVideo()

        debugLog("playing next video for player \(player)");
        

    }
    
    // MARK: - Playing Videos
    
    func playNextVideo() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        // remove old entries
        notificationCenter.removeObserver(self);
        
        let player = AVPlayer()
        // play another video
        let oldPlayer = self.player
        self.player = player
        self.playerLayer.player = self.player
        
        if self.preview {
            AerialView.previewPlayer = player
        }
        
        debugLog("Setting player for all player layers in \(AerialView.sharedViews)");
        for view in AerialView.sharedViews {
            view.playerLayer.player = player
        }
        
        if (oldPlayer == AerialView.previewPlayer) {
            AerialView.previewView?.playerLayer.player = self.player
        }
        
        let randomVideo = ManifestLoader.instance.randomVideo();
        
        guard let video = randomVideo else {
            NSLog("Aerial: Error grabbing random video!");
            return;
        }
        let videoURL = video.url;
        
        let asset = CachedOrCachingAsset(videoURL)
//        let asset = AVAsset(URL: videoURL);
        
        let item = AVPlayerItem(asset: asset);
        
        player.replaceCurrentItemWithPlayerItem(item);
        
        debugLog("playing video: \(video.url)");
        if player.rate == 0 {
            player.play();
        }
        
        guard let currentItem = player.currentItem else {
            NSLog("Aerial Error: No current item!");
            return;
        }
        
        debugLog("observing current item \(currentItem)");
        notificationCenter.addObserver(self, selector: #selector(AerialView.playerItemDidReachEnd(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: currentItem);
        notificationCenter.addObserver(self, selector: #selector(AerialView.playerItemNewErrorLogEntryNotification(_:)), name: AVPlayerItemNewErrorLogEntryNotification, object: currentItem);
        notificationCenter.addObserver(self, selector: #selector(AerialView.playerItemFailedtoPlayToEnd(_:)), name: AVPlayerItemFailedToPlayToEndTimeNotification, object: currentItem);
        notificationCenter.addObserver(self, selector: #selector(AerialView.playerItemPlaybackStalledNotification(_:)), name: AVPlayerItemPlaybackStalledNotification, object: currentItem);
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.None;
    }
    
    // MARK: - Preferences
    
    override func hasConfigureSheet() -> Bool {
        return true;
    }
    
    override func configureSheet() -> NSWindow? {
        if let controller = preferencesController {
            return controller.window
        }
        
        let controller = PreferencesWindowController(windowNibName: "PreferencesWindow");
    
        preferencesController = controller;
        return controller.window;
    }
}