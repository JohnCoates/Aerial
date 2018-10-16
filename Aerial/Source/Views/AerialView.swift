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
    var clockLayer: CATextLayer!
    var messageLayer: CATextLayer!
    var lastCorner = -1
    var clockTimer : Timer?
    
    var preferencesController: PreferencesWindowController?
    static var players: [AVPlayer] = [AVPlayer]()
    static var previewPlayer: AVPlayer?
    static var previewView: AerialView?
    
    var player: AVPlayer?
    var currentVideo: AerialVideo?
    
    var observerWasSet = false
    
    static var shouldFade: Bool {
        let preferences = Preferences.sharedInstance
        return (preferences.fadeMode != Preferences.FadeMode.disabled.rawValue)
    }
    
    static var fadeDuration: Double {
        let preferences = Preferences.sharedInstance
        switch preferences.fadeMode {
        case Preferences.FadeMode.t0_5.rawValue:
            return 0.5
        case Preferences.FadeMode.t1.rawValue:
            return 1
        case Preferences.FadeMode.t2.rawValue:
            return 2
        default:
            return 0.10
        }
    }
    
    static var textFadeDuration: Double {
        let preferences = Preferences.sharedInstance
        switch preferences.fadeModeText {
        case Preferences.FadeMode.t0_5.rawValue:
            return 0.5
        case Preferences.FadeMode.t1.rawValue:
            return 1
        case Preferences.FadeMode.t2.rawValue:
            return 2
        default:
            return 0.10
        }
    }
    
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
        
        textLayer = CATextLayer()
/*        textLayer.frame = CGRect(x: 20, y: layer.bounds.height-60, width: layer.bounds.width-40, height: 40)
        textLayer.font = NSFont(name: "Helvetica Neue Medium", size: 28)
        if self.frame.height < 400 {
            textLayer.fontSize = 12 // Seems needed despite line above

        } else {
            textLayer.fontSize = 28 // Seems needed despite line above
        }*/
        textLayer.string = ""
        textLayer.opacity = 0
        // Add a bit of shadow to give an outline and better readability
        textLayer.shadowRadius = 10
        textLayer.shadowOpacity = 1.0
        textLayer.shadowColor = CGColor.black
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1.0
        layer.addSublayer(textLayer)
        
        // Clock Layer
        clockLayer = CATextLayer()
        clockLayer.opacity = 0
        // Add a bit of shadow to give an outline and better readability
        clockLayer.shadowRadius = 10
        clockLayer.shadowOpacity = 1.0
        clockLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1.0
        layer.addSublayer(clockLayer)
        
        // Message Layer
        messageLayer = CATextLayer()
        messageLayer.opacity = 0
        // Add a bit of shadow to give an outline and better readability
        messageLayer.shadowRadius = 10
        messageLayer.shadowOpacity = 1.0
        messageLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1.0
        layer.addSublayer(messageLayer)
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
            self.playerLayer.opacity = 0
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
        if AerialView.shouldFade {
            self.playerLayer.opacity = 0
        } else {
            self.playerLayer.opacity = 1.0
        }
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
        self.currentVideo = video

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

        if player.rate == 0 {
            player.play()
            //player.rate = 32.0
        }
        
        guard let currentItem = player.currentItem else {
            NSLog("Aerial Error: No current item!")
            return
        }
        
        debugLog("observing current item \(currentItem)")

        // Descriptions and fades are set when we begin playback
        if !observerWasSet {
            observerWasSet = true
            playerLayer.addObserver(self, forKeyPath: "readyForDisplay", options: .initial, context: nil)
        }
        
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
    
    // Wait for the player to be ready
    internal override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if self.playerLayer.isReadyForDisplay {
            // All playerLayers should fade, we only have one shared player
            if AerialView.sharingPlayers {
                for view in AerialView.sharedViews {
                    self.addPlayerFades(player: self.player!, playerLayer: view.playerLayer, video: self.currentVideo!)
                }
            } else {
                self.addPlayerFades(player: self.player!, playerLayer: self.playerLayer, video: self.currentVideo!)
            }
            
            // Descriptions on main only for now

            self.addDescriptions(player: self.player!, video: self.currentVideo!)
        }
    }
    
    private func addPlayerFades(player: AVPlayer, playerLayer: AVPlayerLayer, video: AerialVideo)
    {
        // We only fade in/out if we have duration
        if video.duration > 0 && AerialView.shouldFade {
            playerLayer.opacity = 0
            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [0, 1, 1, 0] as [Int]
            fadeAnimation.keyTimes = [0, AerialView.fadeDuration/video.duration, 1-(AerialView.fadeDuration/video.duration), 1] as [NSNumber]
            fadeAnimation.duration = video.duration
            fadeAnimation.calculationMode = CAAnimationCalculationMode.cubic
            playerLayer.add(fadeAnimation, forKey: "mainfade")
        }
        else {
            playerLayer.opacity = 1.0
        }
    }
    
    private func addDescriptions(player: AVPlayer, video: AerialVideo)
    {
        let poiStringProvider = PoiStringProvider.sharedInstance
        let preferences = Preferences.sharedInstance
        
        if (preferences.showDescriptions)
        {
            // Preventively, make sure we have poi as tvOS11/10 videos won't have them
            if video.poi.count > 0 && poiStringProvider.loadedDescriptions
            {
                // Collect all the timestamps from the JSON
                var times = [NSValue]()

                for pkv in video.poi
                {
                    //print("time \(pkv.key) \(poiStringProvider.getString(key: video.poi[pkv.key]!))")
                    let timeStamp = Double(pkv.key)!
                    times.append(NSValue(time: CMTime(seconds: timeStamp, preferredTimescale: 1)))
                }
                // The JSON isn't sorted so we fix that
                times.sort(by: { ($0 as! CMTime).seconds < ($1 as! CMTime).seconds } )
                
                // Animate the very first one on it's own
                let str = poiStringProvider.getString(key: video.poi["0"]!)
                
                var fadeAnimation:CAKeyframeAnimation
                
                if (preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue)
                {
                    fadeAnimation = createFadeInOutAnimation(duration: 11)
                }
                else
                {
                    // Always show mode, if there's more than one point, use that, if not either use known video duration or some hardcoded duration
                    if times.count > 1
                    {
                        let duration = (times[1] as! CMTime).seconds - 1
                        fadeAnimation = createFadeInOutAnimation(duration: duration)
                    }
                    else if video.duration > 0
                    {
                        fadeAnimation = createFadeInOutAnimation(duration: video.duration - 1)
                    }
                    else
                    {
                        // We should have the duration, if we don't, hardcode the longest known duration
                        fadeAnimation = createFadeInOutAnimation(duration: 807)
                    }
                }

                self.textLayer.add(fadeAnimation, forKey: "textfade")
                setupTextLayer(string: str, duration: fadeAnimation.duration)
                
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
                    
                    // Animate text
                    var fadeAnimation: CAKeyframeAnimation
                    
                    if (preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue)
                    {
                        fadeAnimation = self.createFadeInOutAnimation(duration: 11)
                    }
                    else
                    {
                        if isLastTimeStamp, video.duration == 0 {
                            // We have no idea when the video ends, so 2 minutes it is
                            fadeAnimation = self.createFadeInOutAnimation(duration: 120)
                        }
                        else {
                            fadeAnimation = self.createFadeInOutAnimation(duration: intervalUntilNextTimeStamp)
                        }
                    }
                    // Get the string for the current timestamp
                    let key = String(format: "%.0f",closestTime)
                    let str = poiStringProvider.getString(key: video.poi[key]!)
                    self.setupTextLayer(string: str, duration: fadeAnimation.duration)

                    self.textLayer.add(fadeAnimation, forKey: "textfade")
                }
            }
            else
            {
                // We don't have any extended description, using video name (City)
                let str = video.name
                var fadeAnimation:CAKeyframeAnimation

                if (preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue)
                {
                    fadeAnimation = createFadeInOutAnimation(duration: 11)
                }
                else
                {
                    // Always show mode, use known video duration or some hardcoded duration
                    if video.duration > 0
                    {
                        fadeAnimation = createFadeInOutAnimation(duration: video.duration - 1)
                    }
                    else
                    {
                        // We should have the duration, if we don't, hardcode the longest known duration
                        fadeAnimation = createFadeInOutAnimation(duration: 807)
                    }
                }
                self.textLayer.add(fadeAnimation, forKey: "textfade")
                setupTextLayer(string: str, duration : fadeAnimation.duration)
            }
        }
    }
    
    // Create a Fade In/Out animation
    func createFadeInOutAnimation(duration: Double) -> CAKeyframeAnimation {
        let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
        fadeAnimation.values = [0, 0, 1, 1, 0] as [NSNumber]
        fadeAnimation.keyTimes = [0, Double( 1/duration ), Double( (1+AerialView.textFadeDuration)/duration ), Double( 1-AerialView.textFadeDuration/duration ), 1] as [NSNumber]
        fadeAnimation.duration = duration
        
        return fadeAnimation
    }
    
    func setupTextLayer(string:String, duration: CFTimeInterval) {
        // Setup string
        self.textLayer.string = string

        let preferences = Preferences.sharedInstance

        // We override font size on previews
        var fontSize = CGFloat(preferences.fontSize!)
        if (layer!.bounds.height < 200) {
            fontSize = 12
        }

        // Get font with a fallback in case
        var font = NSFont(name: "Helvetica Neue Medium", size: 28)
        if let tryFont = NSFont(name: preferences.fontName!,size: fontSize) {
            font = tryFont
        }

        // Make sure we change the layer font/size
        self.textLayer.font = font
        self.textLayer.fontSize = fontSize

        let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : font as Any]

        // Calculate bounding box
        let s = NSAttributedString(string: string, attributes: attributes)
        let rect = s.boundingRect(with: layer!.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)

        // Rebind frame
        self.textLayer.frame = rect

        // At the position the user wants
        if preferences.descriptionCorner == Preferences.DescriptionCorner.random.rawValue {
            // Randomish, we still want something different
            var corner = Int.random(in: 0...3)
            while corner == lastCorner {
                corner = Int.random(in: 0...3)
            }
            lastCorner = corner
            
            repositionTextLayer(position: corner)
            setupAndRepositionExtra(position: corner, duration: duration)
        } else {
            repositionTextLayer(position: preferences.descriptionCorner!)   // Or set position from pref
            setupAndRepositionExtra(position: preferences.descriptionCorner!, duration: duration)
        }
    }
    
    private func setupAndRepositionExtra(position: Int, duration: CFTimeInterval)
    {
        let preferences = Preferences.sharedInstance
        if (preferences.showClock)
        {
            if (clockTimer == nil)
            {
                if #available(OSX 10.12, *) {
                    clockTimer =  Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (Timer) in
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm:ss", options: 0, locale: Locale.current)
                        let dateString = dateFormatter.string(from: Date())
                        self.clockLayer.string = dateString
                    })
                }
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm:ss", options: 0, locale: Locale.current)
            let dateString = dateFormatter.string(from: Date())
            
            self.clockLayer.string = dateString
            
            let preferences = Preferences.sharedInstance
            
            // We override font size on previews
            var fontSize = CGFloat(preferences.extraFontSize!)
            if (layer!.bounds.height < 200) {
                fontSize = 12
            }
            
            // Get font with a fallback in case
            var font = NSFont(name: "Helvetica Neue Medium", size: 28)
            if let tryFont = NSFont(name: preferences.extraFontName!,size: fontSize) {
                font = tryFont
            }
            
            // Make sure we change the layer font/size
            self.clockLayer.font = font
            self.clockLayer.fontSize = fontSize
            
            let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : font as Any]
            
            // Calculate bounding box
            let s = NSAttributedString(string: dateString, attributes: attributes)
            let rect = s.boundingRect(with: layer!.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)
            
            // Rebind frame
            self.clockLayer.frame = rect
            //clockLayer.anchorPoint = CGPoint(x: 0, y:0)
            //clockLayer.position = CGPoint(x:10 ,y:10+textLayer.visibleRect.height)
            //clockLayer.opacity = 1.0
            clockLayer.add(createFadeInOutAnimation(duration: duration), forKey: "textfade")
        }

        if (preferences.showMessage && preferences.showMessageString != "") {
            self.messageLayer.string = preferences.showMessageString
            
            // We override font size on previews
            var fontSize = CGFloat(preferences.extraFontSize!)
            if (layer!.bounds.height < 200) {
                fontSize = 12
            }
            
            // Get font with a fallback in case
            var font = NSFont(name: "Helvetica Neue Medium", size: 28)
            if let tryFont = NSFont(name: preferences.extraFontName!,size: fontSize) {
                font = tryFont
            }
            
            // Make sure we change the layer font/size
            self.messageLayer.font = font
            self.messageLayer.fontSize = fontSize
            
            let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : font as Any]
            
            // Calculate bounding box
            let s = NSAttributedString(string: preferences.showMessageString!, attributes: attributes)
            let rect = s.boundingRect(with: layer!.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)
            
            // Rebind frame
            self.messageLayer.frame = rect
            //messageLayer.anchorPoint = CGPoint(x: 0, y:0)
            //messageLayer.position = CGPoint(x:10 ,y:10+textLayer.visibleRect.height)
            //messageLayer.opacity = 1.0
            self.messageLayer.add(createFadeInOutAnimation(duration: duration), forKey: "textfade")
        }

        if preferences.extraCorner == Preferences.ExtraCorner.same.rawValue{
            repositionClockAndMessageLayer(position: position, alone: false)
        } else if preferences.extraCorner == Preferences.ExtraCorner.hOpposed.rawValue{
            repositionClockAndMessageLayer(position: (position+2)%4, alone: true)
        } else if preferences.extraCorner == Preferences.ExtraCorner.dOpposed.rawValue{
            repositionClockAndMessageLayer(position: 3-position, alone: true)
        }
    }
    
    private func repositionClockAndMessageLayer(position:Int, alone:Bool) {
        var clockDecal : CGFloat = 0
        var messageDecal : CGFloat = 0
        let preferences = Preferences.sharedInstance
        
        if !alone {
            clockDecal += textLayer.visibleRect.height
            messageDecal += textLayer.visibleRect.height
        }
        
        if preferences.showMessage {
            clockDecal += messageLayer.visibleRect.height
        }

        if (position == Preferences.DescriptionCorner.topLeft.rawValue) {
            self.clockLayer.anchorPoint = CGPoint(x: 0, y: 1)
            self.clockLayer.position = CGPoint(x: 10, y: layer!.bounds.height-10-clockDecal)
            self.messageLayer.anchorPoint = CGPoint(x: 0, y: 1)
            self.messageLayer.position = CGPoint(x: 10, y: layer!.bounds.height-10-messageDecal)
        } else if (position == Preferences.DescriptionCorner.bottomLeft.rawValue) {
            self.clockLayer.anchorPoint = CGPoint(x: 0, y: 0)
            self.clockLayer.position = CGPoint(x: 10, y: 10+clockDecal)
            self.messageLayer.anchorPoint = CGPoint(x: 0, y: 0)
            self.messageLayer.position = CGPoint(x: 10, y: 10+messageDecal)
        } else if (position == Preferences.DescriptionCorner.topRight.rawValue) {
            self.clockLayer.anchorPoint = CGPoint(x: 1, y: 1)
            self.clockLayer.position = CGPoint(x: layer!.bounds.width-10, y: layer!.bounds.height-10-clockDecal)
            self.messageLayer.anchorPoint = CGPoint(x: 1, y: 1)
            self.messageLayer.position = CGPoint(x: layer!.bounds.width-10, y: layer!.bounds.height-10-messageDecal)
        } else if (position == Preferences.DescriptionCorner.bottomRight.rawValue) {
            self.clockLayer.anchorPoint = CGPoint(x: 1, y: 0)
            self.clockLayer.position = CGPoint(x: layer!.bounds.width-10, y: 10+clockDecal)
            self.messageLayer.anchorPoint = CGPoint(x: 1, y: 0)
            self.messageLayer.position = CGPoint(x: layer!.bounds.width-10, y: 10+messageDecal)
        }
    }

    private func repositionTextLayer(position:Int) {
        if (position == Preferences.DescriptionCorner.topLeft.rawValue) {
            self.textLayer.anchorPoint = CGPoint(x: 0, y: 1)
            self.textLayer.position = CGPoint(x: 10, y: layer!.bounds.height-10)
        } else if (position == Preferences.DescriptionCorner.bottomLeft.rawValue) {
            self.textLayer.anchorPoint = CGPoint(x: 0, y: 0)
            self.textLayer.position = CGPoint(x: 10, y: 10)
        } else if (position == Preferences.DescriptionCorner.topRight.rawValue) {
            self.textLayer.anchorPoint = CGPoint(x: 1, y: 1)
            self.textLayer.position = CGPoint(x: layer!.bounds.width-10, y: layer!.bounds.height-10)
        } else if (position == Preferences.DescriptionCorner.bottomRight.rawValue) {
            self.textLayer.anchorPoint = CGPoint(x: 1, y: 0)
            self.textLayer.position = CGPoint(x: layer!.bounds.width-10, y: 10)
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
