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
final class AerialView: ScreenSaverView, CAAnimationDelegate {
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

    var isQuickFading = false

    var brightnessToRestore: Float?
    var isCatalinaPreview = false

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

    // Mirrored viewing mode and Spanned viewing mode share the same player for sync & ressource saving
    static var sharingPlayers: Bool {
        let preferences = Preferences.sharedInstance

        switch preferences.newViewingMode {
        case
            Preferences.NewViewingMode.cloned.rawValue,
            Preferences.NewViewingMode.mirrored.rawValue,
            Preferences.NewViewingMode.spanned.rawValue:

            return true
        default:
            return false
        }
    }

    static var sharedViews: [AerialView] = []
    // Because of lifecycle in Preview, we may pile up old/no longer
    // shared instanciated views that we need to track to not reuse
    static var instanciatedViews: [AerialView] = []

    // MARK: - Shared Player
    static var singlePlayerAlreadySetup: Bool = false
    static var sharedPlayerIndex: Int?
    static var didSkipMain: Bool = false

    class var sharedPlayer: AVPlayer {
        struct Static {
            static let instance: AVPlayer = AVPlayer()
            // swiftlint:disable:next identifier_name
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
        // legacyScreenSaver always return true for isPreview on Catalina
        // We need to detect and override ourselves
        if frame.width < 400 && frame.height < 300 {
            super.init(frame: frame, isPreview: true)
        } else {
            super.init(frame: frame, isPreview: false)
        }

        debugLog("avInit .saver \(frame) \(isPreview)")
        self.animationTimeInterval = 1.0 / 30.0
        setup()
    }

    // This is the one used by App
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        debugLog("avInit .app")
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
        let indexMaybe = AerialView.players.firstIndex(of: player)

        guard let index = indexMaybe else {
            return
        }
        AerialView.players.remove(at: index)
    }

    // swiftlint:disable:next cyclomatic_complexity
    func setup() {
        if let version = Bundle(identifier: "com.JohnCoates.Aerial")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            debugLog("\(self.description) AerialView setup init (V\(version))")
        }

        let preferences = Preferences.sharedInstance
        let timeManagement = TimeManagement.sharedInstance
        let batteryManagement = BatteryManagement()

        // Run Sparkle updater if enabled
        if !isPreview && preferences.updateWhileSaverMode {
            let au = AutoUpdates()
            au.doForcedUpdate()
        }

        // Check early if we need to enable power saver mode,
        // black screen with minimal brightness
        if preferences.overrideOnBattery && batteryManagement.isOnBattery() && !isPreview {
            if preferences.alternateVideoFormat == Preferences.AlternateVideoFormat.powerSaving.rawValue ||
                (preferences.powerSavingOnLowBattery && batteryManagement.isBatteryLow()) {
                debugLog("Engaging power saving mode")
                isDisabled = true
                timeManagement.setBrightness(level: 0.0)
                return
            }
        }

        // We may need to set timers to progressively dim the screen
        checkIfShouldSetBrightness()

        // Shared views can get stuck, we may need to clean them up here
        cleanupSharedViews()

        // We look for the screen in our detected list.
        // In case of preview or unknown screen result will be nil
        let displayDetection = DisplayDetection.sharedInstance
        let thisScreen = displayDetection.findScreenWith(frame: self.frame)

        var localPlayer: AVPlayer?
        debugLog("\(self.description) isPreview : \(isPreview)")
        debugLog("Using : \(String(describing: thisScreen))")

        // Is the current screen disabled by user ?
        if !isPreview {
            // If it's an unknown screen, we leave it enabled
            if let screen = thisScreen {
                if !displayDetection.isScreenActive(id: screen.id) {
                    // Then we disable and exit
                    debugLog("This display is not active, disabling")
                    isDisabled = true
                    return
                }
            }
        } else {
            AerialView.previewView = self
        }

        // Track which views are sharing the sharedPlayer
        if AerialView.sharingPlayers {
            AerialView.sharedViews.append(self)
        }

        // We track all instanciated views here, independand of their shared status
        AerialView.instanciatedViews.append(self)

        // Setup the AVPlayer
        if AerialView.sharingPlayers {
            localPlayer = AerialView.sharedPlayer
        } else {
            localPlayer = AVPlayer()
        }

        guard let player = localPlayer else {
            errorLog("\(self.description) Couldn't create AVPlayer!")
            return
        }

        self.player = player

        if isPreview {
            AerialView.previewPlayer = player
        } else if !AerialView.sharingPlayers {
            // add to player list
            AerialView.players.append(player)
        }

        setupPlayerLayer(withPlayer: player)

        // In mirror mode we use the main instance player
        if AerialView.sharingPlayers && AerialView.singlePlayerAlreadySetup {
            self.playerLayer.player = AerialView.instanciatedViews[AerialView.sharedPlayerIndex!].player
            self.playerLayer.opacity = 0
            return
        }

        // We're never sharing the preview !
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

    // On previews, it's possible that our shared player was stopped and is not reusable
    func cleanupSharedViews() {
        if AerialView.singlePlayerAlreadySetup {
            if AerialView.instanciatedViews[AerialView.sharedPlayerIndex!].wasStopped {
                AerialView.singlePlayerAlreadySetup = false
                AerialView.sharedPlayerIndex = nil

                AerialView.instanciatedViews = [AerialView]()   // Clear the list of instanciated stuff
                AerialView.sharedViews = [AerialView]()         // And the list of sharedViews
            }
        }
    }

    // MARK: - Lifecycle stuff
    override func startAnimation() {
        super.startAnimation()
        debugLog("\(self.description) startAnimation")

        if !isDisabled {
            // Previews may be restarted, but our layer will get hidden (somehow) so show it back
            if isPreview && player?.currentTime() != CMTime.zero {
                playerLayer.opacity = 1
                player?.play()
            }
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
                brightnessToRestore = nil
            }
        }
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

            // If we share a player, we need to add the fades and the text to all the
            // instanciated views using it (eg: in mirrored mode)
            if AerialView.sharingPlayers {
                for view in AerialView.sharedViews {
                    self.addPlayerFades(view: view, player: self.player!, video: self.currentVideo!)
                    self.addDescriptions(view: view, player: self.player!, video: self.currentVideo!)
                }
            } else {
                self.addPlayerFades(view: self, player: self.player!, video: self.currentVideo!)
                self.addDescriptions(view: self, player: self.player!, video: self.currentVideo!)
            }
        }
    }

    // MARK: - playNextVideo()
    func playNextVideo() {
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
        player.isMuted = true
        // player.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)

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
/*
    override func keyDown(with event: NSEvent) {
        debugLog("keyDown")
        let preferences = Preferences.sharedInstance

        if preferences.allowSkips {
            if event.keyCode == 124 {
                if !isQuickFading {
                    // If we share, just call this on our main view
                    if AerialView.sharingPlayers {
                        // The first view with the player gets the fade and the play next instruction,
                        // it controls the others
                        AerialView.sharedViews.first!.fastFadeOut(andPlayNext: true)
                        for view in AerialView.sharedViews where AerialView.sharedViews.first != view {
                            view.fastFadeOut(andPlayNext: false)
                        }
                    } else {
                        // If we do independant playback we have to skip all views
                        for view in AerialView.instanciatedViews {
                            view.fastFadeOut(andPlayNext: true)
                        }
                    }
                } else {
                    debugLog("Right arrow key currently locked")
                }
            } else {
                self.nextResponder!.keyDown(with: event)
                //super.keyDown(with: event)
            }
        } else {
            self.nextResponder?.keyDown(with: event)
            //super.keyDown(with: event)
        }
    }

    override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }
     */

    // MARK: - Extra Animations
    private func fastFadeOut(andPlayNext: Bool) {
        // We need to clear the current animations running on playerLayer
        isQuickFading = true    // Lock the use of keydown
        playerLayer.removeAllAnimations()
        let fadeOutAnimation = CAKeyframeAnimation(keyPath: "opacity")
        fadeOutAnimation.values = [1, 0] as [Int]
        fadeOutAnimation.keyTimes = [0, AerialView.fadeDuration] as [NSNumber]
        fadeOutAnimation.duration = AerialView.fadeDuration
        fadeOutAnimation.delegate = self
        fadeOutAnimation.isRemovedOnCompletion = false
        fadeOutAnimation.calculationMode = CAAnimationCalculationMode.cubic
        if andPlayNext {
            playerLayer.add(fadeOutAnimation, forKey: "quickfadeandnext")
        } else {
            playerLayer.add(fadeOutAnimation, forKey: "quickfade")
        }
    }

    // Stop callback for fastFadeOut
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        isQuickFading = false   // Release our ugly lock
        playerLayer.opacity = 0
        if anim == playerLayer.animation(forKey: "quickfadeandnext") {
            debugLog("stop and next")
            playerLayer.removeAllAnimations()   // Make sure we get rid of our anim
            playNextVideo()
        } else {
            debugLog("stop")
            playerLayer.removeAllAnimations()   // Make sure we get rid of our anim
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
}
