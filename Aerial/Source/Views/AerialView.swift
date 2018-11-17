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
// swiftlint:disable:next type_body_length
final class AerialView: ScreenSaverView {
    var playerLayer: AVPlayerLayer!
    var textLayer: CATextLayer!
    var clockLayer: CATextLayer!
    var messageLayer: CATextLayer!
    var lastCorner = -1
    var clockTimer: Timer?

    var preferencesController: PreferencesWindowController?
    static var players: [AVPlayer] = [AVPlayer]()
    static var previewPlayer: AVPlayer?
    static var previewView: AerialView?

    var player: AVPlayer?
    var currentVideo: AerialVideo?

    var observerWasSet = false
    var hasStartedPlaying = false
    var wasStopped = false
    var isDisabled = false
    var timeObserver: Any?

    var brightnessToRestore: Float?

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
    // because of lifecycle in Preview, we may pile up old/no longer
    // shared instanciated views that we need to track to not reuse
    static var instanciatedViews: [AerialView] = []
    //var instanciatedIndex: Int

    // MARK: - Shared Player

    static var singlePlayerAlreadySetup: Bool = false
    static var sharedPlayerIndex: Int?

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
    // This is the one used by System Preferences
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        debugLog("avInit1")
        self.animationTimeInterval = 1.0 / 30.0
        setup()
    }

    // This is the one used by App
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        debugLog("avInit2")
        setup()
    }

    deinit {
        debugLog("\(self.description) deinit AerialView")
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

    func setDimTimers() {
        if #available(OSX 10.12, *) {
            let preferences = Preferences.sharedInstance
            let timeManagement = TimeManagement.sharedInstance
            if preferences.dimBrightness && preferences.startDim != preferences.endDim {
                debugLog("setting brightness timers from \(String(describing: preferences.startDim)) to \(String(describing: preferences.endDim))")
                var interval: Int
                if preferences.overrideDimInMinutes {
                    interval = preferences.dimInMinutes! * 6 // * 60 / 10, we make 10 intermediate steps
                } else {
                    interval = timeManagement.getCurrentSleepTime() * 6
                    if interval == 0 {
                        interval = 180 // Fallback to 30 mins if no sleep
                    }
                }
                debugLog("Step size: \(interval) seconds")

                for idx in 1...10 {
                    _ = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval * idx), repeats: false) { (_) in
                        let val = preferences.startDim! - ((preferences.startDim! - preferences.endDim!) / 10 * Double(idx))
                        debugLog("Firing event \(idx) brightness to \(val)")
                        timeManagement.setBrightness(level: Float(val))
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            warnLog("Brightness control not available < macOS 10.12")
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func setup() {
        debugLog("\(self.description) AerialView setup init")
        let preferences = Preferences.sharedInstance
        let timeManagement = TimeManagement.sharedInstance

        if preferences.overrideOnBattery && timeManagement.isOnBattery() && !isPreview {
            if preferences.alternateVideoFormat == Preferences.AlternateVideoFormat.powerSaving.rawValue ||
                (preferences.powerSavingOnLowBattery && timeManagement.isBatteryLow()) {
                debugLog("Engaging power saving mode")
                isDisabled = true
                timeManagement.setBrightness(level: 0.0)
                return
            }
        }

        // Ugly, we make sure we should dim, we're not a preview, we haven't dimmed yet (multi monitor)
        // and ensure we properly apply the night/battery restrictions !
        if preferences.dimBrightness {
            if !isPreview && brightnessToRestore == nil {
                let (should, to) = timeManagement.shouldRestrictPlaybackToDayNightVideo()
                if !preferences.dimOnlyAtNight || (preferences.dimOnlyAtNight && should && to == "night") {
                    if !preferences.dimOnlyOnBattery || (preferences.dimOnlyOnBattery && timeManagement.isOnBattery()) {
                        brightnessToRestore = timeManagement.getBrightness()
                        debugLog("Brightness before Aerial was launched : \(String(describing: brightnessToRestore))")
                        timeManagement.setBrightness(level: Float(preferences.startDim!))
                        setDimTimers()
                    }
                }
            }
        }

        if AerialView.singlePlayerAlreadySetup {
            debugLog("singlePlayerAlreadySetup, checking if was stopped to purge")
            // On previews, it's possible that our shared player was stopped and is not reusable
            if AerialView.instanciatedViews[AerialView.sharedPlayerIndex!].wasStopped {
                debugLog("Purging previous singlePlayer")
                AerialView.singlePlayerAlreadySetup = false
                AerialView.sharedPlayerIndex = nil

                AerialView.instanciatedViews = [AerialView]()   // Clear the list of instanciated stuff
                AerialView.sharedViews = [AerialView]()         // And the list of sharedViews
            }
        }

        var localPlayer: AVPlayer?

        let notPreview = !isPreview
        debugLog("\(self.description) isPreview : \(isPreview)")

        if notPreview {
            debugLog("\(self.description) singlePlayerAlreadySetup \(AerialView.singlePlayerAlreadySetup)")
            if AerialView.singlePlayerAlreadySetup && preferences.multiMonitorMode == Preferences.MultiMonitorMode.mainOnly.rawValue {
                isDisabled = true
                return
            }

            // check if we should share preview's player
            //let noPlayers = (AerialView.players.count == 0)
            let previewPlayerExists = (AerialView.previewPlayer != nil)
            debugLog("\(self.description) nbPlayers \(AerialView.players.count) previewPlayerExists \(previewPlayerExists)")
            /*if noPlayers && previewPlayerExists {

                localPlayer = AerialView.previewPlayer
            }*/
        } else {
            AerialView.previewView = self
        }

        if AerialView.sharingPlayers {
            AerialView.sharedViews.append(self)
        }

        // We track all views here to clean the sharing code
        AerialView.instanciatedViews.append(self)

        if localPlayer == nil {
            debugLog("\(self.description) no local player")

            if AerialView.sharingPlayers {
                /*if AerialView.previewPlayer != nil {
                    localPlayer = AerialView.previewPlayer
                } else {*/

                localPlayer = AerialView.sharedPlayer
                //}
            } else {
                localPlayer = AVPlayer()
            }
        }

        guard let player = localPlayer else {
            errorLog("\(self.description) Couldn't create AVPlayer!")
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
            self.playerLayer.player = AerialView.instanciatedViews[AerialView.sharedPlayerIndex!].player
            self.playerLayer.opacity = 0
            return
        }

        // We're NOT sharing the preview !!!!!
        if !isPreview {
            AerialView.singlePlayerAlreadySetup = true
            AerialView.sharedPlayerIndex = AerialView.instanciatedViews.count-1
        }

        ManifestLoader.instance.addCallback { _ in
            self.playNextVideo()
        }
    }

    override func viewDidChangeBackingProperties() {
        debugLog("\(self.description) backing change \((self.window?.backingScaleFactor) ?? 1.0) isDisabled: \(isDisabled)")
        if !isDisabled {
            self.layer!.contentsScale = (self.window?.backingScaleFactor) ?? 1.0
            self.playerLayer.contentsScale = (self.window?.backingScaleFactor) ?? 1.0
            self.textLayer.contentsScale = (self.window?.backingScaleFactor) ?? 1.0
            self.clockLayer.contentsScale = (self.window?.backingScaleFactor) ?? 1.0
            self.messageLayer.contentsScale = (self.window?.backingScaleFactor) ?? 1.0
        }
    }

    func setupPlayerLayer(withPlayer player: AVPlayer) {
        debugLog("\(self.description) setupPlayerLayer")

        self.layer = CALayer()
        guard let layer = self.layer else {
            errorLog("\(self.description) Couldn't create CALayer")
            return
        }
        self.wantsLayer = true
        layer.backgroundColor = NSColor.black.cgColor
        layer.needsDisplayOnBoundsChange = true
        layer.frame = self.bounds

        debugLog("\(self.description) setting up player layer with frame: \(self.bounds) / \(self.frame)")

        playerLayer = AVPlayerLayer(player: player)
        if #available(OSX 10.10, *) {
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }
        playerLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        playerLayer.frame = layer.bounds
        layer.addSublayer(playerLayer)

        textLayer = CATextLayer()
        textLayer.frame = layer.bounds
        textLayer.opacity = 0
        // Add a bit of shadow to give an outline and better readability
        textLayer.shadowRadius = 10
        textLayer.shadowOpacity = 1.0
        textLayer.shadowColor = CGColor.black
        layer.addSublayer(textLayer)

        // Clock Layer
        clockLayer = CATextLayer()
        clockLayer.opacity = 0
        // Add a bit of shadow to give an outline and better readability
        clockLayer.shadowRadius = 10
        clockLayer.shadowOpacity = 1.0
        clockLayer.shadowColor = CGColor.black
        layer.addSublayer(clockLayer)

        // Message Layer
        messageLayer = CATextLayer()
        messageLayer.opacity = 0
        // Add a bit of shadow to give an outline and better readability
        messageLayer.shadowRadius = 10
        messageLayer.shadowOpacity = 1.0
        messageLayer.shadowColor = CGColor.black
        layer.addSublayer(messageLayer)

        if #available(OSX 10.14, *) {
        } else {
            debugLog("Using dot workaround for video driver corruption")
            // Tentative fix for high sierra issues
            let highSierraLayer = CATextLayer()
            highSierraLayer.frame = self.bounds
            highSierraLayer.opacity = 0.5
            highSierraLayer.font = NSFont(name: "Helvetica Neue Medium", size: 4)
            highSierraLayer.fontSize = 4
            highSierraLayer.string = "."

            let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: highSierraLayer.font as Any]

            // Calculate bounding box
            let attrString = NSAttributedString(string: highSierraLayer.string as! String, attributes: attributes)
            let rect = attrString.boundingRect(with: layer.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)

            highSierraLayer.frame = rect
            highSierraLayer.position = CGPoint(x: 2, y: 2)
            highSierraLayer.anchorPoint = CGPoint(x: 0, y: 0)
            layer.addSublayer(highSierraLayer)
        }
    }

    // MARK: - Lifecycle stuff
/*    override func draw(_ rect: NSRect) {
    }*/
    override func startAnimation() {
        super.startAnimation()
        debugLog("\(self.description) startAnimation")

        if !isDisabled {
            // Previews may be restarted, but our layer will get hidden (somehow) so show it back
            if isPreview && player?.currentTime() != CMTime.zero {
                playerLayer.opacity = 1
                player?.play()
            }

            /*if player?.rate == 0 {
             
            }*/
        }
    }

    override func stopAnimation() {
        super.stopAnimation()
        wasStopped = true
        debugLog("\(self.description) stopAnimation")
        if !isDisabled {
            player?.pause()
        }

        let preferences = Preferences.sharedInstance

        if preferences.dimBrightness {
            if !isPreview && brightnessToRestore != nil {
                let timeManagement = TimeManagement.sharedInstance
                timeManagement.setBrightness(level: brightnessToRestore!)
                debugLog("Restoring brightness to : \(String(describing: brightnessToRestore))")
                brightnessToRestore = nil
            }
        }
    }

    // MARK: - AVPlayerItem Notifications

    @objc func playerItemFailedtoPlayToEnd(_ aNotification: Notification) {
        warnLog("\(self.description) AVPlayerItemFailedToPlayToEndTimeNotification \(aNotification)")
        playNextVideo()
    }

    @objc func playerItemNewErrorLogEntryNotification(_ aNotification: Notification) {
        warnLog("\(self.description) AVPlayerItemNewErrorLogEntryNotification \(aNotification)")
    }

    @objc func playerItemPlaybackStalledNotification(_ aNotification: Notification) {
        warnLog("\(self.description) AVPlayerItemPlaybackStalledNotification \(aNotification)")
    }

    @objc func playerItemDidReachEnd(_ aNotification: Notification) {
        debugLog("\(self.description) played did reach end")
        debugLog("\(self.description) notification: \(aNotification)")
        playNextVideo()
        debugLog("\(self.description) playing next video for player \(String(describing: player))")
    }

    // Wait for the player to be ready
    // swiftlint:disable:next block_based_kvo
    internal override func observeValue(forKeyPath keyPath: String?,
                                        of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                                        context: UnsafeMutableRawPointer?) {
        debugLog("\(self.description) observeValue \(String(describing: keyPath))")
        if self.playerLayer.isReadyForDisplay {
            self.player!.play()
            hasStartedPlaying = true

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

    // MARK: - playNextVideo()
    func playNextVideo() {
        //let timeManagement = TimeManagement.sharedInstance

        let notificationCenter = NotificationCenter.default
        // Clear everything
        if timeObserver != nil {
            self.player!.removeTimeObserver(timeObserver!)
            timeObserver = nil
        }
        self.textLayer.removeAllAnimations()
        self.clockLayer.removeAllAnimations()
        self.messageLayer.removeAllAnimations()

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

        debugLog("\(self.description) Setting player for all player layers in \(AerialView.sharedViews)")
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
            errorLog("\(self.description) Error grabbing random video!")
            return
        }
        self.currentVideo = video

        // Workaround to avoid local playback making network calls
        let item = AerialPlayerItem(video: video)
        if !video.isAvailableOffline {
            player.replaceCurrentItem(with: item)
            debugLog("\(self.description) streaming video (not fully available offline) : \(video.url)")
        } else {
            let localurl = URL(fileURLWithPath: VideoCache.cachePath(forVideo: video)!)
            let localitem = AVPlayerItem(url: localurl)
            player.replaceCurrentItem(with: localitem)
            debugLog("\(self.description) playing video (OFFLINE MODE) : \(localurl)")
        }
/*
        // The first time we start from start animation !
        if hasStartedPlaying && player.rate == 0 {
            player.play()
        }
  */
        guard let currentItem = player.currentItem else {
            errorLog("\(self.description) No current item!")
            return
        }

        debugLog("\(self.description) observing current item \(currentItem)")

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

    // MARK: - Extra Animations

    private func addPlayerFades(player: AVPlayer, playerLayer: AVPlayerLayer, video: AerialVideo) {
        // We only fade in/out if we have duration
        if video.duration > 0 && AerialView.shouldFade {
            playerLayer.opacity = 0
            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [0, 1, 1, 0] as [Int]
            fadeAnimation.keyTimes = [0, AerialView.fadeDuration/video.duration, 1-(AerialView.fadeDuration/video.duration), 1] as [NSNumber]
            fadeAnimation.duration = video.duration
            fadeAnimation.calculationMode = CAAnimationCalculationMode.cubic
            playerLayer.add(fadeAnimation, forKey: "mainfade")
        } else {
            playerLayer.opacity = 1.0
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func addDescriptions(player: AVPlayer, video: AerialVideo) {
        let poiStringProvider = PoiStringProvider.sharedInstance
        let preferences = Preferences.sharedInstance

        if preferences.showDescriptions {
            // Preventively, make sure we have poi as tvOS11/10 videos won't have them
            if (!video.poi.isEmpty && poiStringProvider.loadedDescriptions) ||
                (preferences.useCommunityDescriptions && !video.communityPoi.isEmpty && !poiStringProvider.getPoiKeys(video: video).isEmpty) {
                // Collect all the timestamps from the JSON
                var times = [NSValue]()
                let keys = poiStringProvider.getPoiKeys(video: video)

                for pkv in keys {
                    let timeStamp = Double(pkv.key)!
                    times.append(NSValue(time: CMTime(seconds: timeStamp, preferredTimescale: 1)))
                }
                // The JSON isn't sorted so we fix that
                times.sort(by: { ($0 as! CMTime).seconds < ($1 as! CMTime).seconds })

                // Animate the very first one on it's own
                let str = poiStringProvider.getString(key: keys["0"]!, video: video)

                var fadeAnimation: CAKeyframeAnimation

                if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
                    fadeAnimation = createFadeInOutAnimation(duration: 11)
                } else {
                    // Always show mode, if there's more than one point, use that, if not either use known video duration or some hardcoded duration
                    if times.count > 1 {
                        let duration = (times[1] as! CMTime).seconds - 1
                        fadeAnimation = createFadeInOutAnimation(duration: duration)
                    } else if video.duration > 0 {
                        fadeAnimation = createFadeInOutAnimation(duration: video.duration - 1)
                    } else {
                        // We should have the duration, if we don't, hardcode the longest known duration
                        fadeAnimation = createFadeInOutAnimation(duration: 807)
                    }
                }

                self.textLayer.add(fadeAnimation, forKey: "textfade")
                if video.duration > 0 {
                    setupTextLayer(string: str, duration: fadeAnimation.duration, isInitial: true, totalDuration: video.duration - 1)
                } else {
                    setupTextLayer(string: str, duration: fadeAnimation.duration, isInitial: true, totalDuration: 807)
                }

                let mainQueue = DispatchQueue.main

                // We then callback for each timestamp
                timeObserver = player.addBoundaryTimeObserver(forTimes: times, queue: mainQueue) {
                    var isLastTimeStamp = true
                    var intervalUntilNextTimeStamp = 0.0

                    // find closest timestamp to when we're waking up
                    var closest = 1000.0
                    var closestTime = 0.0
                    var closestTimeValue: NSValue = NSValue(time: CMTime.zero)

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
                    } else if video.duration > 0 {
                        isLastTimeStamp = true
                        // If we have a duration for the video, we may not !
                        intervalUntilNextTimeStamp = video.duration - closestTime - 1
                    }

                    // Animate text
                    var fadeAnimation: CAKeyframeAnimation

                    if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
                        fadeAnimation = self.createFadeInOutAnimation(duration: 11)
                    } else {
                        if isLastTimeStamp, video.duration == 0 {
                            // We have no idea when the video ends, so 2 minutes it is
                            fadeAnimation = self.createFadeInOutAnimation(duration: 120)
                        } else {
                            fadeAnimation = self.createFadeInOutAnimation(duration: intervalUntilNextTimeStamp)
                        }
                    }
                    // Get the string for the current timestamp
                    let key = String(format: "%.0f", closestTime)
                    let str = poiStringProvider.getString(key: keys[key]!, video: video)
                    self.setupTextLayer(string: str, duration: fadeAnimation.duration, isInitial: false, totalDuration: video.duration-1)

                    self.textLayer.add(fadeAnimation, forKey: "textfade")
                }
            } else {
                // We don't have any extended description, using Secondary name (location) or video name (City)
                let str: String
                if video.secondaryName != "" {
                    str = video.secondaryName
                } else {
                    str = video.name
                }
                var fadeAnimation: CAKeyframeAnimation

                if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
                    fadeAnimation = createFadeInOutAnimation(duration: 11)
                } else {
                    // Always show mode, use known video duration or some hardcoded duration
                    if video.duration > 0 {
                        fadeAnimation = createFadeInOutAnimation(duration: video.duration - 1)
                    } else {
                        // We should have the duration, if we don't, hardcode the longest known duration
                        fadeAnimation = createFadeInOutAnimation(duration: 807)
                    }
                }
                self.textLayer.add(fadeAnimation, forKey: "textfade")
                setupTextLayer(string: str, duration: fadeAnimation.duration, isInitial: true, totalDuration: video.duration)
            }
        }
    }

    func setupTextLayer(string: String, duration: CFTimeInterval, isInitial: Bool, totalDuration: Double) {
        // Setup string
        self.textLayer.string = string
        self.textLayer.isWrapped = true
        let preferences = Preferences.sharedInstance

        // We override font size on previews
        var fontSize = CGFloat(preferences.fontSize!)
        if layer!.bounds.height < 200 {
            fontSize = 12
        }

        // We get the horizontal margin
        var mx = CGFloat(preferences.marginX!)

        if !preferences.overrideMargins {
            mx = 50
        }
        if isPreview {
            mx = 10
        }
        let boundingRect = CGSize(width: layer!.visibleRect.size.width-2*mx, height: layer!.visibleRect.size.height)

        // Get font with a fallback in case
        var font = NSFont(name: "Helvetica Neue Medium", size: 28)
        if let tryFont = NSFont(name: preferences.fontName!, size: fontSize) {
            font = tryFont
        }

        // Make sure we change the layer font/size
        self.textLayer.font = font
        self.textLayer.fontSize = fontSize

        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font as Any]

        // Calculate bounding box
        let str = NSAttributedString(string: string, attributes: attributes)

        var rect = str.boundingRect(with: boundingRect, options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin])
        // Last line won't appear if we don't adjust 
        rect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height + 10)

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
            setupAndRepositionExtra(position: corner, duration: duration, isInitial: isInitial, totalDuration: totalDuration)
        } else {
            repositionTextLayer(position: preferences.descriptionCorner!)   // Or set position from pref
            setupAndRepositionExtra(position: preferences.descriptionCorner!, duration: duration, isInitial: isInitial, totalDuration: totalDuration)
        }
    }

    private func reRectClock() {
        let preferences = Preferences.sharedInstance

        let dateFormatter = DateFormatter()
        if preferences.withSeconds {
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm:ss", options: 0, locale: Locale.current)
        } else {
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm", options: 0, locale: Locale.current)
        }

        let dateString = dateFormatter.string(from: Date())
        self.clockLayer.string = dateString
        // We override font size on previews
        var fontSize = CGFloat(preferences.extraFontSize!)
        if layer!.bounds.height < 200 {
            fontSize = 12
        }

        // Get font with a fallback in case
        var font = NSFont(name: "Monaco", size: 28)
        if let tryFont = NSFont(name: preferences.extraFontName!, size: fontSize) {
            font = tryFont
        }

        // Make sure we change the layer font/size
        self.clockLayer.font = font
        self.clockLayer.fontSize = fontSize

        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font as Any]

        // Calculate bounding box
        let str = NSAttributedString(string: dateString, attributes: attributes)
        let rect = str.boundingRect(with: layer!.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)

        // Rebind frame
        let oldRect = self.clockLayer.frame
        self.clockLayer.frame = CGRect(x: oldRect.minX, y: oldRect.minY, width: rect.maxX, height: rect.maxY)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func setupAndRepositionExtra(position: Int, duration: CFTimeInterval, isInitial: Bool, totalDuration: Double) {
        let preferences = Preferences.sharedInstance
        if preferences.showClock {
            if isInitial {
                if clockTimer == nil {
                    if #available(OSX 10.12, *) {
                        clockTimer =  Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                            self.reRectClock()
                        })
                    }

                }

                let dateFormatter = DateFormatter()
                if preferences.withSeconds {
                    dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm:ss", options: 0, locale: Locale.current)
                } else {
                    dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm", options: 0, locale: Locale.current)
                }
                let dateString = dateFormatter.string(from: Date())

                self.clockLayer.string = dateString

                // We override font size on previews
                var fontSize = CGFloat(preferences.extraFontSize!)
                if layer!.bounds.height < 200 {
                    fontSize = 12
                }

                // Get font with a fallback in case
                var font = NSFont(name: "Monaco", size: 28)
                if let tryFont = NSFont(name: preferences.extraFontName!, size: fontSize) {
                    font = tryFont
                }

                // Make sure we change the layer font/size
                self.clockLayer.font = font
                self.clockLayer.fontSize = fontSize

                let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font as Any]

                // Calculate bounding box
                let str = NSAttributedString(string: dateString, attributes: attributes)
                let rect = str.boundingRect(with: layer!.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)

                // Rebind frame
                self.clockLayer.frame = rect
                //clockLayer.anchorPoint = CGPoint(x: 0, y:0)
                //clockLayer.position = CGPoint(x:10 ,y:10+textLayer.visibleRect.height)
                //clockLayer.opacity = 1.0
            }

            if preferences.descriptionCorner == Preferences.DescriptionCorner.random.rawValue {
                clockLayer.add(createFadeInOutAnimation(duration: duration), forKey: "textfade")
            } else if isInitial && preferences.showDescriptionsMode == Preferences.DescriptionMode.always.rawValue {
                clockLayer.add(createFadeInOutAnimation(duration: totalDuration), forKey: "textfade")
            } else if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
                clockLayer.add(createFadeInOutAnimation(duration: duration), forKey: "textfade")
            }
        }

        if preferences.showMessage && preferences.showMessageString != "" {
            self.messageLayer.string = preferences.showMessageString

            // We override font size on previews
            var fontSize = CGFloat(preferences.extraFontSize!)
            if layer!.bounds.height < 200 {
                fontSize = 12
            }

            // Get font with a fallback in case
            var font = NSFont(name: "Helvetica Neue Medium", size: 28)
            if let tryFont = NSFont(name: preferences.extraFontName!, size: fontSize) {
                font = tryFont
            }

            // Make sure we change the layer font/size
            self.messageLayer.font = font
            self.messageLayer.fontSize = fontSize

            let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font as Any]

            // Calculate bounding box
            let str = NSAttributedString(string: preferences.showMessageString!, attributes: attributes)
            let rect = str.boundingRect(with: layer!.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)

            // Rebind frame
            self.messageLayer.frame = rect
            //messageLayer.anchorPoint = CGPoint(x: 0, y:0)
            //messageLayer.position = CGPoint(x:10 ,y:10+textLayer.visibleRect.height)
            //messageLayer.opacity = 1.0
            if preferences.descriptionCorner == Preferences.DescriptionCorner.random.rawValue {
                self.messageLayer.add(createFadeInOutAnimation(duration: duration), forKey: "textfade")
            } else if isInitial && preferences.showDescriptionsMode == Preferences.DescriptionMode.always.rawValue {
                self.messageLayer.add(createFadeInOutAnimation(duration: totalDuration), forKey: "textfade")
            } else if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
                self.messageLayer.add(createFadeInOutAnimation(duration: duration), forKey: "textfade")
            }

        }

        if !isInitial && preferences.extraCorner == Preferences.ExtraCorner.same.rawValue &&
            preferences.showDescriptionsMode == Preferences.DescriptionMode.always.rawValue &&
            preferences.descriptionCorner != Preferences.DescriptionCorner.random.rawValue {
            animateClockAndMessageLayer(position: position)
        } else {
            if preferences.extraCorner == Preferences.ExtraCorner.same.rawValue {
                repositionClockAndMessageLayer(position: position, alone: false)
            } else if preferences.extraCorner == Preferences.ExtraCorner.hOpposed.rawValue {
                repositionClockAndMessageLayer(position: (position+2)%4, alone: true)
            } else if preferences.extraCorner == Preferences.ExtraCorner.dOpposed.rawValue {
                repositionClockAndMessageLayer(position: 3-position, alone: true)
            }
        }
    }

    private func animateClockAndMessageLayer(position: Int) {
        var clockDecal: CGFloat = 0
        var messageDecal: CGFloat = 0
        let preferences = Preferences.sharedInstance

        var mx = CGFloat(preferences.marginX!)
        var my = CGFloat(preferences.marginY!)
        if !preferences.overrideMargins {
            mx = 50
            my = 50
        }
        if isPreview {
            mx = 10
            my = 10
        }

        clockDecal += textLayer.visibleRect.height
        messageDecal += textLayer.visibleRect.height

        if preferences.showMessage {
            clockDecal += messageLayer.visibleRect.height
        }
        let duration = 1 + AerialView.textFadeDuration

        var cto, mto: CGPoint
        if position == Preferences.DescriptionCorner.topLeft.rawValue {
            cto = CGPoint(x: mx, y: layer!.bounds.height-my-clockDecal)
            mto = CGPoint(x: mx, y: layer!.bounds.height-my-messageDecal)
        } else if position == Preferences.DescriptionCorner.bottomLeft.rawValue {
            cto = CGPoint(x: mx, y: my+clockDecal)
            mto = CGPoint(x: mx, y: my+messageDecal)
        } else if position == Preferences.DescriptionCorner.topRight.rawValue {
            cto = CGPoint(x: layer!.bounds.width-mx, y: layer!.bounds.height-my-clockDecal)
            mto = CGPoint(x: layer!.bounds.width-mx, y: layer!.bounds.height-my-messageDecal)
        } else {
            cto = CGPoint(x: layer!.bounds.width-mx, y: my+clockDecal)
            mto = CGPoint(x: layer!.bounds.width-mx, y: my+messageDecal)
        }

        self.clockLayer.add(createMoveAnimation(layer: clockLayer, to: cto, duration: duration), forKey: "position")
        self.messageLayer.add(createMoveAnimation(layer: messageLayer, to: mto, duration: duration), forKey: "position")
    }

    private func repositionClockAndMessageLayer(position: Int, alone: Bool) {
        var clockDecal: CGFloat = 0
        var messageDecal: CGFloat = 0
        let preferences = Preferences.sharedInstance

        var mx = CGFloat(preferences.marginX!)
        var my = CGFloat(preferences.marginY!)
        if !preferences.overrideMargins {
            mx = 50
            my = 50
        }
        if isPreview {
            mx = 10
            my = 10
        }

        if !alone {
            clockDecal += textLayer.visibleRect.height
            messageDecal += textLayer.visibleRect.height
        }

        if preferences.showMessage {
            clockDecal += messageLayer.visibleRect.height
        }

        if position == Preferences.DescriptionCorner.topLeft.rawValue {
            self.clockLayer.anchorPoint = CGPoint(x: 0, y: 1)
            self.clockLayer.position = CGPoint(x: mx, y: layer!.bounds.height-my-clockDecal)
            self.messageLayer.anchorPoint = CGPoint(x: 0, y: 1)
            self.messageLayer.position = CGPoint(x: mx, y: layer!.bounds.height-my-messageDecal)
        } else if position == Preferences.DescriptionCorner.bottomLeft.rawValue {
            self.clockLayer.anchorPoint = CGPoint(x: 0, y: 0)
            self.clockLayer.position = CGPoint(x: mx, y: my+clockDecal)
            self.messageLayer.anchorPoint = CGPoint(x: 0, y: 0)
            self.messageLayer.position = CGPoint(x: mx, y: my+messageDecal)
        } else if position == Preferences.DescriptionCorner.topRight.rawValue {
            self.clockLayer.anchorPoint = CGPoint(x: 1, y: 1)
            self.clockLayer.position = CGPoint(x: layer!.bounds.width-mx, y: layer!.bounds.height-my-clockDecal)
            self.messageLayer.anchorPoint = CGPoint(x: 1, y: 1)
            self.messageLayer.position = CGPoint(x: layer!.bounds.width-mx, y: layer!.bounds.height-my-messageDecal)
        } else if position == Preferences.DescriptionCorner.bottomRight.rawValue {
            self.clockLayer.anchorPoint = CGPoint(x: 1, y: 0)
            self.clockLayer.position = CGPoint(x: layer!.bounds.width-mx, y: my+clockDecal)
            self.messageLayer.anchorPoint = CGPoint(x: 1, y: 0)
            self.messageLayer.position = CGPoint(x: layer!.bounds.width-mx, y: my+messageDecal)
        }
    }

    private func repositionTextLayer(position: Int) {
        let preferences = Preferences.sharedInstance
        var mx = CGFloat(preferences.marginX!)
        var my = CGFloat(preferences.marginY!)
        if !preferences.overrideMargins {
            mx = 50
            my = 50
        }
        if isPreview {
            mx = 10
            my = 10
        }

        if position == Preferences.DescriptionCorner.topLeft.rawValue {
            self.textLayer.anchorPoint = CGPoint(x: 0, y: 1)
            self.textLayer.position = CGPoint(x: mx, y: layer!.bounds.height-my)
            self.textLayer.alignmentMode = .left
        } else if position == Preferences.DescriptionCorner.bottomLeft.rawValue {
            self.textLayer.anchorPoint = CGPoint(x: 0, y: 0)
            self.textLayer.position = CGPoint(x: mx, y: my)
            self.textLayer.alignmentMode = .left
        } else if position == Preferences.DescriptionCorner.topRight.rawValue {
            self.textLayer.anchorPoint = CGPoint(x: 1, y: 1)
            self.textLayer.position = CGPoint(x: layer!.bounds.width-mx, y: layer!.bounds.height-my)
            self.textLayer.alignmentMode = .right
        } else if position == Preferences.DescriptionCorner.bottomRight.rawValue {
            self.textLayer.anchorPoint = CGPoint(x: 1, y: 0)
            self.textLayer.position = CGPoint(x: layer!.bounds.width-mx, y: my)
            self.textLayer.alignmentMode = .right
        }
    }

    // Create a Fade In/Out animation
    func createFadeInOutAnimation(duration: Double) -> CAKeyframeAnimation {
        let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
        fadeAnimation.values = [0, 0, 1, 1, 0] as [NSNumber]
        fadeAnimation.keyTimes = [
            0,
            Double(1 / duration ),
            Double((1 + AerialView.textFadeDuration) / duration),
            Double(1 - AerialView.textFadeDuration / duration),
            1,
        ] as [NSNumber]
        fadeAnimation.duration = duration
        return fadeAnimation
    }

    // Create a move animation
    func createMoveAnimation(layer: CALayer, to: CGPoint, duration: Double) -> CABasicAnimation {
        let moveAnimation = CABasicAnimation(keyPath: "position")
        moveAnimation.fromValue = layer.position
        moveAnimation.toValue = to
        moveAnimation.duration = duration
        layer.position = to
        return moveAnimation
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
} // swiftlint:disable:this file_length
