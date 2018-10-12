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
        return (preferences.multiMonitorMode == Preferences.MultiMonitorMode.mirrored.rawValue)
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
        
        debugLog("setting up player layer with frame: \(self.bounds) / \(self.frame)")
        
        playerLayer = AVPlayerLayer(player: player)
        if #available(OSX 10.10, *) {
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }
        playerLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        playerLayer.frame = layer.bounds
        playerLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1.0

        layer.addSublayer(playerLayer)

        // Debug code
        textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 20, y: 10, width: layer.bounds.width, height: 40)
        textLayer.font = NSFont(name: "Helvetica Neue Medium", size: 26)
        if self.frame.height < 400 {
            textLayer.fontSize = 12 // Seems needed despite line above

        } else {
            textLayer.fontSize = 28 // Seems needed despite line above
        }
        textLayer.string = ""
        textLayer.opacity = 0
        // Add a bit of shadow to give an outline and better readability
        textLayer.shadowRadius = 10
        textLayer.shadowOpacity = 1.0
        textLayer.shadowColor = CGColor.black
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1.0
        layer.addSublayer(textLayer)
    }
    
    func setup() {
        NSLog("AerialMM : setup init")
        var localPlayer: AVPlayer?
        
        let notPreview = !isPreview
        
        if notPreview {
            let preferences = Preferences.sharedInstance
            
            if (AerialView.singlePlayerAlreadySetup && preferences.multiMonitorMode == Preferences.MultiMonitorMode.mainOnly.rawValue) {
                return
            }
            
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
        //let timeManagement = TimeManagement.sharedInstance

        let notificationCenter = NotificationCenter.default
        
        // remove old entries
        notificationCenter.removeObserver(self)
        
        let player = AVPlayer()
        // play another video
        let oldPlayer = self.player
        self.player = player
        self.playerLayer.player = self.player
        self.playerLayer.opacity = 0
        
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


        // Workaround to avoid local playback making network calls
        let item = AerialPlayerItem(video: video)
        if !video.isAvailableOffline
        {
            player.replaceCurrentItem(with: item)
            debugLog("streaming video (not fully available offline) : \(video.url)")
        }
        else
        {
            let localurl = URL(fileURLWithPath: VideoCache.cachePath(forVideo: video)!)
            let localitem = AVPlayerItem(url: localurl)
            player.replaceCurrentItem(with: localitem)
            debugLog("playing video (OFFLINE MODE) : \(localurl)")
        }
        // Add the descriptions for the video, either the video label or the ones from the strings bundle
        self.addDescriptions(player: player, video: video)
        self.addPlayerFades(player: player, video: video)
        
        if player.rate == 0 {
            player.play()
            //player.rate = 32.0
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
    
    private func addPlayerFades(player: AVPlayer, video: AerialVideo)
    {
        // We only fade in/out if we have duration
        // TODO: This and the first description should probably be a callback after playback start...
        if video.duration > 0 {
            self.playerLayer.opacity = 0
            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [0, 1, 1, 0]
            fadeAnimation.keyTimes = [0, 2/video.duration, 1-2/video.duration, 1] as [NSNumber]
            fadeAnimation.duration = video.duration
            self.playerLayer.add(fadeAnimation, forKey: "mainfade")
        }
        else {
            self.playerLayer.opacity = 1.0
        }
    }
    
    private func addDescriptions(player: AVPlayer, video: AerialVideo)
    {
        // Idle string bundle
        let preferences = Preferences.sharedInstance
        
        var bundlePath = VideoCache.cacheDirectory!
        if (preferences.localizeDescriptions) {
            bundlePath.append(contentsOf: "/TVIdleScreenStrings.bundle")
        }
        else {
            bundlePath.append(contentsOf: "/TVIdleScreenStrings.bundle/en.lproj/")
        }
        
        //let path = Bundle.main.path(forResource: lang, ofType: "lproj")
        
        if (preferences.showDescriptions)
        {
            // Preventively, make sure we have poi as tvOS11/10 videos won't have them
            if video.poi.count > 0, let stringBundle = Bundle.init(path: bundlePath)
            {
                // Collect all the timestamps from the JSON
                var times = [NSValue]()
                
                for pkv in video.poi
                {
                    let timeStamp = Double(pkv.key)!
                    times.append(NSValue(time: CMTime(seconds: timeStamp, preferredTimescale: 1)))
                }
                // The JSON isn't sorted so we fix that
                times.sort(by: { ($0 as! CMTime).seconds < ($1 as! CMTime).seconds } )
                
                // Animate the very first one on it's own
                let str = stringBundle.localizedString(forKey: video.poi["0"]!, value: "", table: "Localizable.nocache")
                let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
                
                fadeAnimation.values = [0, 0, 1, 1, 0]

                if (preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue)
                {
                    fadeAnimation.keyTimes = [0, 1/12, 3/12, 10/12, 1] as [NSNumber]
                    fadeAnimation.duration = 12
                }
                else
                {
                    // Always show mode, if there's more than one point use that, if not either use known video duration or some hardcoded duration
                    if times.count > 1
                    {
                        let duration = (times[1] as! CMTime).seconds - 1
                        fadeAnimation.keyTimes = [0, 1/duration, 3/duration, 1-2/duration, 1] as [NSNumber]
                        fadeAnimation.duration = duration
                    }
                    else if video.duration > 0
                    {
                        fadeAnimation.keyTimes = [0, 1/(video.duration-1), 3/(video.duration - 1), 1-2/(video.duration - 1), 1] as [NSNumber]
                        fadeAnimation.duration = (video.duration - 1)
                    }
                    else
                    {
                        // We should have the duration, if we don't, hardcode the longest known duration
                        fadeAnimation.keyTimes = [0, 1/807, 3/807, 1-2/807, 1] as [NSNumber]
                        fadeAnimation.duration = 807
                    }
                }
                self.textLayer.add(fadeAnimation, forKey: "textfade")
                self.textLayer.string = str
                
                let mainQueue = DispatchQueue.main
                
                // We then callback for each timestamp
                player.addBoundaryTimeObserver(forTimes: times, queue: mainQueue) {
                    var isLastTimeStamp = true
                    var intervalUntilNextTimeStamp = 0.0
                    
                    // find closest timestamp to when we're waking up
                    var closest = 1000.0
                    var closestTime = 0.0
                    var closestTimeValue: NSValue = NSValue(time:CMTime.zero)
                    
                    for time in times {
                        let ts = (time as! CMTime).seconds
                        let distance = abs(ts - player.currentTime().seconds)
                        if distance < closest {
                            closest = distance
                            closestTime = ts
                            closestTimeValue = time
                        }
                    }
                    
                    // We also need the next timeStamp
                    let index = times.firstIndex(of: closestTimeValue)
                    if index! < times.count - 1 {
                        isLastTimeStamp = false
                        intervalUntilNextTimeStamp = (times[index!+1] as! CMTime).seconds - closestTime - 1
                    }
                    else if video.duration > 0 {
                        isLastTimeStamp = true
                        // If we have a duration for the video, we may not !
                        intervalUntilNextTimeStamp = video.duration - closestTime - 1
                    }
                    // Get the string for the current timestamp
                    let key = String(format: "%.0f",closestTime)
                    let str = stringBundle.localizedString(forKey: video.poi[key]!, value: "", table: "Localizable.nocache")
                    self.textLayer.string = str
                    
                    
                    // Animate text
                    let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
                    fadeAnimation.values = [0, 1, 1, 0]
                    
                    if (preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue)
                    {
                        fadeAnimation.keyTimes = [0, 0.2, 0.8, 1]
                        fadeAnimation.duration = 10
                    }
                    else
                    {
                        if isLastTimeStamp, video.duration == 0 {
                            fadeAnimation.keyTimes = [0, 2 / 120, 1 - 2 / 120, 1] as [NSNumber]
                            fadeAnimation.duration = 120    // TODO : better detect total video running time
                        }
                        else {
                            fadeAnimation.keyTimes = [0, 2/intervalUntilNextTimeStamp, 1-2/intervalUntilNextTimeStamp, 1] as [NSNumber]
                            fadeAnimation.duration = intervalUntilNextTimeStamp
                        }
                    }
                    
                    self.textLayer.add(fadeAnimation, forKey: "textfade")
                }
            }
            else
            {
                // We don't have any extended description, using video name (City)
                let str = video.name
                let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
                
                fadeAnimation.values = [0, 0, 1, 1, 0]
                
                if (preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue)
                {
                    fadeAnimation.keyTimes = [0, 1/12, 3/12, 10/12, 1] as [NSNumber]
                    fadeAnimation.duration = 12
                }
                else
                {
                    // Always show mode, use known video duration or some hardcoded duration
                    if video.duration > 0
                    {
                        fadeAnimation.keyTimes = [0, 1/(video.duration-1), 3/(video.duration - 1), 1-2/(video.duration - 1), 1] as [NSNumber]
                        fadeAnimation.duration = (video.duration - 1)
                    }
                    else
                    {
                        // We should have the duration, if we don't, hardcode the longest known duration
                        fadeAnimation.keyTimes = [0, 1/807, 3/807, 1-2/807, 1] as [NSNumber]
                        fadeAnimation.duration = 807
                    }
                }
                self.textLayer.add(fadeAnimation, forKey: "textfade")
                self.textLayer.string = str
            }
        }
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
