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

@objc(AerialView)
class AerialView: ScreenSaverView {
    var playerLayer: AVPlayerLayer!
    var textLayer: CATextLayer!
    var preferencesController: PreferencesWindowController?
    static var players: [AVPlayer] = [AVPlayer]()
    static var previewPlayer: AVPlayer?
    static var previewView: AerialView?
    
    var player: AVPlayer?
    
    static var sharingPlayers: Bool {
        let preferences = Preferences.sharedInstance
        return !preferences.differentAerialsOnEachDisplay
    }
    
    static var sharedViews: [AerialView] = []
    
    // MARK: - Shared Player
    
    static var singlePlayerAlreadySetup: Bool = false
    class var sharedPlayer: AVPlayer {
        struct Static {
            static let instance: AVPlayer = AVPlayer()
            static var _player: AVPlayer?
            static var player: AVPlayer {
                if let activePlayer = _player {
                    return activePlayer
                }

                _player = AVPlayer()
                return _player!
            }
        }
        
        return Static.player
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
        debugLog("deinit AerialView")
        NotificationCenter.default.removeObserver(self)
        
        // set player item to nil if not preview player
        if player != AerialView.previewPlayer {
            player?.rate = 0
            player?.replaceCurrentItem(with: nil)
        }
        
        guard let player = self.player else {
            return
        }
        
        // Remove from player index
        
        let indexMaybe = AerialView.players.index(of: player)
        
        guard let index = indexMaybe else {
            return
        }
        
        AerialView.players.remove(at: index)
    }
    
    func setupPlayerLayer(withPlayer player: AVPlayer) {
        self.layer = CALayer()
        guard let layer = self.layer else {
            NSLog("Aerial Error: Couldn't create CALayer")
            return
        }
        self.wantsLayer = true
        layer.backgroundColor = NSColor.black.cgColor
        layer.needsDisplayOnBoundsChange = true
        layer.frame = self.bounds
//        layer.backgroundColor = NSColor.greenColor().CGColor
        
        debugLog("setting up player layer with frame: \(self.bounds) / \(self.frame)")
        
        playerLayer = AVPlayerLayer(player: player)
        if #available(OSX 10.10, *) {
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }
        playerLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        playerLayer.frame = layer.bounds
        layer.addSublayer(playerLayer)
        // Debug code
        textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 20, y: 10, width: layer.bounds.width, height: 40)
        //textLayer.position = CGPoint(x: 20, y: 20)
        //textLayer.position = CGPoint(x: layer.bounds.maxX-20, y: layer.bounds.maxY-20)
        //textLayer.alignmentMode = .left
        textLayer.font = NSFont(name: "Helvetica Neue Medium", size: 26)
        textLayer.fontSize = 28 // Seems needed despite line above
        textLayer.string = ""
        textLayer.opacity = 0
        
        layer.addSublayer(textLayer)
    }
    
    func setup() {
        var localPlayer: AVPlayer?
        
        let notPreview = !isPreview
        
        if notPreview {
            // check if we should share preview's player
            let noPlayers = (AerialView.players.count == 0)
            let previewPlayerExists = (AerialView.previewPlayer != nil)
            if noPlayers && previewPlayerExists {
                localPlayer = AerialView.previewPlayer
            }
        } else {
            AerialView.previewView = self
        }
        
        if AerialView.sharingPlayers {
            AerialView.sharedViews.append(self)
        }
        
        if localPlayer == nil {
            if AerialView.sharingPlayers {
                if AerialView.previewPlayer != nil {
                    localPlayer = AerialView.previewPlayer
                } else {
                    localPlayer = AerialView.sharedPlayer
                }
            } else {
                localPlayer = AVPlayer()
            }
        }
        
        guard let player = localPlayer else {
            NSLog("Aerial Error: Couldn't create AVPlayer!")
            return
        }
        
        self.player = player
        
        if self.isPreview {
            AerialView.previewPlayer = player
        } else if !AerialView.sharingPlayers {
            // add to player list
            AerialView.players.append(player)
        }
        
        setupPlayerLayer(withPlayer: player)
        
        if AerialView.sharingPlayers && AerialView.singlePlayerAlreadySetup {
            self.playerLayer.player = AerialView.sharedViews[0].player
            return
        }
        
        AerialView.singlePlayerAlreadySetup = true
        
        ManifestLoader.instance.addCallback { videos in
            self.playNextVideo()
        }
    }
    
    // MARK: - AVPlayerItem Notifications
    
    @objc func playerItemFailedtoPlayToEnd(_ aNotification: Notification) {
        NSLog("AVPlayerItemFailedToPlayToEndTimeNotification \(aNotification)")
        
        playNextVideo()
    }
    
    @objc func playerItemNewErrorLogEntryNotification(_ aNotification: Notification) {
        NSLog("AVPlayerItemNewErrorLogEntryNotification \(aNotification)")
    }
    
    @objc func playerItemPlaybackStalledNotification(_ aNotification: Notification) {
        NSLog("AVPlayerItemPlaybackStalledNotification \(aNotification)")
    }
    
    @objc func playerItemDidReachEnd(_ aNotification: Notification) {
        debugLog("played did reach end")
        debugLog("notification: \(aNotification)")
        playNextVideo()

        debugLog("playing next video for player \(String(describing: player))")
    }
    
    func playNextVideo() {
        let notificationCenter = NotificationCenter.default
        
        // remove old entries
        notificationCenter.removeObserver(self)
        
        let player = AVPlayer()
        // play another video
        let oldPlayer = self.player
        self.player = player
        self.playerLayer.player = self.player
        
        if self.isPreview {
            AerialView.previewPlayer = player
        }
        
        debugLog("Setting player for all player layers in \(AerialView.sharedViews)")
        for view in AerialView.sharedViews {
            view.playerLayer.player = player
        }
        
        if oldPlayer == AerialView.previewPlayer {
            AerialView.previewView?.playerLayer.player = self.player
        }
        
        // get a list of current videos that should be excluded from the candidate selection
        // for the next video. This prevents the same video from being shown twice in a row
        // as well as the same video being shown on two different monitors even when sharingPlayers
        // is false
        let currentVideos: [AerialVideo] = AerialView.players.compactMap { (player) -> AerialVideo? in
            (player.currentItem as? AerialPlayerItem)?.video
        }
        
        let randomVideo = ManifestLoader.instance.randomVideo(excluding: currentVideos)
        
        guard let video = randomVideo else {
            NSLog("Aerial: Error grabbing random video!")
            return
        }
        
        let item = AerialPlayerItem(video: video)
        
        player.replaceCurrentItem(with: item)
        
        let preferences = Preferences.sharedInstance
        debugLog("playing video: \(video.url)")
        self.textLayer.string = video.name

        if (preferences.showDescriptions)
        {
            if (preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue)
            {
                // Animate text
                let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
                fadeAnimation.values = [0, 0, 1, 1, 0]
                fadeAnimation.keyTimes = [0, 0.2, 0.4, 0.8, 1]
                fadeAnimation.duration = 12
                self.textLayer.add(fadeAnimation, forKey: "textfade")
            }
            else
            {
                self.textLayer.opacity = 1.0
            }
        }
        
        if player.rate == 0 {
            player.play()
        }
        
        guard let currentItem = player.currentItem else {
            NSLog("Aerial Error: No current item!")
            return
        }
        
        debugLog("observing current item \(currentItem)")
        notificationCenter.addObserver(self,
                                       selector: #selector(AerialView.playerItemDidReachEnd(_:)),
                                       name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                       object: currentItem)
        notificationCenter.addObserver(self,
                                       selector: #selector(AerialView.playerItemNewErrorLogEntryNotification(_:)),
                                       name: NSNotification.Name.AVPlayerItemNewErrorLogEntry,
                                       object: currentItem)
        notificationCenter.addObserver(self,
                                       selector: #selector(AerialView.playerItemFailedtoPlayToEnd(_:)),
                                       name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
                                       object: currentItem)
        notificationCenter.addObserver(self,
                                       selector: #selector(AerialView.playerItemPlaybackStalledNotification(_:)),
                                       name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                       object: currentItem)
        player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
    }
    
    // MARK: - Preferences
    
    override var hasConfigureSheet: Bool {
        return true
    }
    
    override var configureSheet: NSWindow? {
        if let controller = preferencesController {
            return controller.window
        }
        
        let controller = PreferencesWindowController(windowNibName: "PreferencesWindow")
    
        preferencesController = controller
        return controller.window
    }
}
