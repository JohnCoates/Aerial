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
    var layerManager: LayerManager
    var playerLayer: AVPlayerLayer!

    static var players: [AVPlayer] = [AVPlayer]()
    static var previewPlayer: AVPlayer?
    static var previewView: AerialView?

    var player: AVPlayer?
    var currentVideo: AerialVideo?

    var preferencesController: PreferencesWindowController?

    var observerWasSet = false
    var hasStartedPlaying = false
    var wasStopped = false
    var isDisabled = false

    var isQuickFading = false

    var brightnessToRestore: Float?

    // We use this for tentative Catalina bug workaround
    var originalWidth, originalHeight: CGFloat

    // Tentative improvement when only one video in playlist
    var shouldLoop = false

    static var shouldFade: Bool {
        return (PrefsVideos.fadeMode != .disabled)
    }

    static var fadeDuration: Double {
        switch PrefsVideos.fadeMode {
        case .t0_5:
            return 0.5
        case .t1:
            return 1
        case .t2:
            return 2
        default:
            return 0.10
        }
    }

    static var textFadeDuration: Double {
        switch PrefsInfo.fadeModeText {
        case .t0_5:
            return 0.5
        case .t1:
            return 1
        case .t2:
            return 2
        default:
            return 0.10
        }
    }

    // Mirrored/cloned viewing mode and Spanned viewing mode share the same player for sync & ressource saving
    static var sharingPlayers: Bool {
        switch PrefsDisplays.viewingMode {
        case .cloned, .mirrored, .spanned:
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
    // This is the one used by System Preferences/ScreenSaverEngine
    override init?(frame: NSRect, isPreview: Bool) {
        // legacyScreenSaver always return true for isPreview on Catalina
        // We need to detect and override ourselves
        var preview = false
        self.originalWidth = frame.width
        self.originalHeight = frame.height

        if frame.width < 400 && frame.height < 300 {
            preview = true
        }

        // This is where we manage our location info layers, clock, etc
        self.layerManager = LayerManager(isPreview: preview)

        super.init(frame: frame, isPreview: preview)
        debugLog("avInit .saver \(frame) p: \(isPreview) o: \(preview)")

        self.animationTimeInterval = 1.0 / 30.0

        setup()
    }

    // This is the one used by our App target used for debugging
    required init?(coder: NSCoder) {
        self.layerManager = LayerManager(isPreview: false)

        // ...
        self.originalWidth = 0
        self.originalHeight = 0

        super.init(coder: coder)
        self.originalWidth = frame.width
        self.originalHeight = frame.height

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
            debugLog("\(self.description) AerialView setup init (V\(version)) preview: \(self.isPreview)")
        }

        let preferences = Preferences.sharedInstance

        let au = AutoUpdates.sharedInstance
        // Run Sparkle updater if enabled
        if !isPreview {
            if preferences.updateWhileSaverMode {
                if PrefsUpdates.sparkleUpdateMode == .notify {
                    // Run the probing check
                    au.doProbingCheck()
                } else {
                    // Run the forced update
                    au.doForcedUpdate()
                }
            }
        }

        // Check early if we need to enable power saver mode,
        // black screen with minimal brightness
        if !isPreview {
            if (PrefsVideos.onBatteryMode == .alwaysDisabled && Battery.isUnplugged())
                || (PrefsVideos.onBatteryMode == .disableOnLow && Battery.isLow()) {
                debugLog("Engaging power saving mode")
                isDisabled = true
                Brightness.set(level: 0.0)
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
        //swiftlint:disable:next line_length
        debugLog("\(self.description) backing change \((self.window?.backingScaleFactor) ?? 1.0) isDisabled: \(isDisabled) frame: \(self.frame) preview: \(self.isPreview)")

        // Tentative workaround for a Catalina bug
        if self.frame.width < 300 && !isPreview {
            debugLog("*** Frame size bug, trying to override to \(originalWidth)x\(originalHeight)!")
            self.frame = CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight)
        }

        if !isDisabled {
            self.layer!.contentsScale = (self.window?.backingScaleFactor) ?? 1.0
            self.playerLayer.contentsScale = (self.window?.backingScaleFactor) ?? 1.0

            // And our additional layers
            layerManager.setContentScale(scale: (self.window?.backingScaleFactor) ?? 1.0)
        }
/*
        // TMP TEST
        if self.window?.backingScaleFactor == 1.0 {
            debugLog("*** Forcing retina 2.0")
            self.layer!.contentsScale = 2.0
            self.playerLayer.contentsScale = 2.0

            // And our additional layers
            layerManager.setContentScale(scale: 2.0)
        }
*/
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
        debugLog("\(self.description) startAnimation frame \(self.frame) bounds \(self.bounds)")

        if !isDisabled {
            // Previews may be restarted, but our layer will get hidden (somehow) so show it back
            if isPreview && player?.currentTime() != CMTime.zero {
                debugLog("restarting playback")
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
                Brightness.set(level: brightnessToRestore!)
                brightnessToRestore = nil
            }
        }
    }

    // Wait for the player to be ready
    // swiftlint:disable:next block_based_kvo
    internal override func observeValue(forKeyPath keyPath: String?,
                                        of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                                        context: UnsafeMutableRawPointer?) {
        debugLog("\(self.description) observeValue \(String(describing: keyPath)) \(self.playerLayer.isReadyForDisplay) \(self.frame)")

        if self.playerLayer.isReadyForDisplay {
            self.player!.play()
            hasStartedPlaying = true
            debugLog("start playback: \(self.frame) \(self.bounds)")

            // If we share a player, we need to add the fades and the text to all the
            // instanciated views using it (eg: in mirrored mode)
            if AerialView.sharingPlayers {
                for view in AerialView.sharedViews {
                    self.addPlayerFades(view: view, player: self.player!, video: self.currentVideo!)
                    view.layerManager.setupLayersForVideo(video: self.currentVideo!, player: self.player!)
                }
            } else {
                self.addPlayerFades(view: self, player: self.player!, video: self.currentVideo!)
                self.layerManager.setupLayersForVideo(video: self.currentVideo!, player: self.player!)
            }
        }
    }

    // MARK: - playNextVideo()
    func playNextVideo() {
        print("-/-/-/ PNV")
        let notificationCenter = NotificationCenter.default
        // Clear everything
        layerManager.clearLayerAnimations(player: self.player!)
        for view in AerialView.sharedViews {
            view.layerManager.clearLayerAnimations(player: self.player!)
        }

        // remove old entries
        notificationCenter.removeObserver(self)

        let player = AVPlayer()
        // play another video
        let oldPlayer = self.player
        self.player = player
        player.isMuted = PrefsAdvanced.muteSound
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

        let (randomVideo, pshouldLoop) = ManifestLoader.instance.randomVideo(excluding: currentVideos)

        // If we only have one video in the playlist, we can rewind it for seamless transitions
        self.shouldLoop = pshouldLoop

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

    override func keyDown(with event: NSEvent) {
        debugLog("keyDown")

        if PrefsVideos.allowSkips {
            if event.keyCode == 124 {
                if !isQuickFading {
                    // If we share, just call this on our main view
                    if AerialView.sharingPlayers {
                        // The first view with the player gets the fade and the play next instruction,
                        // it controls the others
                        for view in AerialView.sharedViews where AerialView.sharedViews.first != view {
                            view.fastFadeOut(andPlayNext: false)
                        }
                        AerialView.sharedViews.first!.fastFadeOut(andPlayNext: true)

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
        // swiftlint:disable:next implicit_getter
        get {
            return true
        }
    }

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
