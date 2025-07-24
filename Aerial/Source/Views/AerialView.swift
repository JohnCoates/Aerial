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

    var preferencesController: PanelWindowController?

    var observerWasSet = false
    var hasStartedPlaying = false
    var wasStopped = false
    var isDisabled = false

    var isQuickFading = false

    var brightnessToRestore: Float?

    var globalSpeed: Float = 1.0
    var globalPause = false

    // We use this for tentative Catalina bug workaround
    var originalWidth, originalHeight: CGFloat

    // We use this for tentative Sonoma bug workaround
    var foundScreen: Screen?
    var foundFrame: NSRect?

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
        Aerial.helper.checkCompanion()

        // Clear log if > 1MB on startup
        rollLogIfNeeded()

        // Set Companion bridge notifications under Sonoma, but not under Companion
        if !Aerial.helper.underCompanion {
            if #available(macOS 14, *) {
                CompanionBridge.setNotifications()
            }
        }
        
        // legacyScreenSaver always return true for isPreview on Catalina
        // We need to detect and override ourselves
        // This is finally fixed in Ventura
        var preview = false
        self.originalWidth = frame.width
        self.originalHeight = frame.height

        if frame.width < 400 && frame.height < 300 {
            preview = true
        }
        
        // This is where we manage our location info layers, clock, etc
        self.layerManager = LayerManager(isPreview: preview)

        super.init(frame: frame, isPreview: preview)
        debugLog("🖼️ AVinit (.saver) \(frame) p: \(isPreview) o: \(preview)")

        self.animationTimeInterval = 1.0 / 30.0

        if Aerial.helper.underCompanion && isPreview {
            debugLog("Running under companion in preview mode, preventing setup")
        } else {
            // We need to delay things under Sonoma because legacyScreenSaver is awesome
            if #available(macOS 14.0, *) {
                var delay = 0.01
                
                // If nightshift we delay more
                if !Aerial.helper.underCompanion && PrefsTime.timeMode == .nightShift {
                    delay = 0.5
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    debugLog("🖼️ AVinit delayed setup!")
                    self.setup()
                }
            } else {
                setup()
            }
        }
    }

    // This is the one used by our App target used for debugging
    required init?(coder: NSCoder) {
        Aerial.helper.appMode = true

        Aerial.helper.checkCompanion()

        // Clear log if > 1MB on startup
        rollLogIfNeeded()

        // Set Companion bridge notifications under Sonoma, but not under Companion
        if !Aerial.helper.underCompanion {
            if #available(macOS 14, *) {
                CompanionBridge.setNotifications()
            }
        }

        
        self.layerManager = LayerManager(isPreview: false)

        // ...
        self.originalWidth = 0
        self.originalHeight = 0

        super.init(coder: coder)
        self.originalWidth = frame.width
        self.originalHeight = frame.height

        debugLog("🖼️ AVinit .app")
        
        // We need to delay things under Sonoma because legacyScreenSaver is awesome
        if #available(macOS 14.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                debugLog("🖼️ AVinit delayed setup!")
                self.setup()
            }
        } else {
            setup()
        }
    }

    deinit {
        Aerial.helper.maybeUnmuteSound()
        
        debugLog("🖼️ \(self.description) AVdeinit ")
        NotificationCenter.default.removeObserver(self)
    }

    func ensureCorrectFormat() {
        if #available(OSX 10.15, *) {
        } else {
            // No HDR allowed here
            if PrefsVideos.videoFormat == .v4KHDR {
                debugLog("🖼️⚠️ Fixing 4K HDR not allowed prior to Catalina")
                PrefsVideos.videoFormat = .v4KHEVC
            } else if PrefsVideos.videoFormat == .v1080pHDR {
                debugLog("🖼️⚠️ Fixing 1080p HDR not allowed prior to Catalina")
                PrefsVideos.videoFormat = .v1080pHEVC
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func setup() {
        // Disable HDR only on macOS Ventura
        if !Aerial.helper.canHDR() {
            if isPreview && (PrefsVideos.videoFormat == .v4KHDR || PrefsVideos.videoFormat == .v1080pHDR) {
                // This will lead to crashing in up to Ventura beta5 so disable
                let debugTextView = NSTextView(frame: bounds.insetBy(dx: 20, dy: 20))
                debugTextView.font = .labelFont(ofSize: 10)
                debugTextView.string += "HDR Previews hidden on Ventura"
                isDisabled = true
                
                self.addSubview(debugTextView)
                return
            }
        }


        
        
        // First we check the system appearance, as it relies on our view
        Aerial.helper.computeDarkMode(view: self)

        // Then check if we need to mute/unmute sound
        Aerial.helper.maybeMuteSound()

        // Kick up the timezone detection
        _ = TimeManagement.sharedInstance

        // This is to make sure we don't start in a format that's unsupported
        ensureCorrectFormat()
        
        if let version = Bundle(identifier: "com.JohnCoates.Aerial")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            debugLog("🖼️ \(self.description) AV setup init (V\(version)) preview: \(self.isPreview)")
            debugLog("🖼️ Running \(ProcessInfo.processInfo.operatingSystemVersionString)")
        }

        // First thing, we may need to migrate the cache !
        Cache.migrate()

        // Now we need to check if we should remove lingering stuff from the cache !
        if Cache.canNetwork() {
            Cache.removeCruft()
        }

        // Check early if we need to enable power saver mode,
        // black screen with minimal brightness
        if !isPreview {
            if (PrefsVideos.onBatteryMode == .alwaysDisabled && Battery.isUnplugged())
                || (PrefsVideos.onBatteryMode == .disableOnLow && Battery.isLow()) {
                debugLog("🖼️ Engaging power saving mode")
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

        let screenCount = displayDetection.getScreenCount()
        debugLog("🖼️ Real screen count : \(screenCount)")

        var thisScreen: Screen? = nil
        if #available(macOS 14.0, *) {
            if foundScreen == nil {
                debugLog("🖼️ missing foundScreen, workarounding \(String(describing: self.window?.screen))")
                if let missingScreen = self.window?.screen {
                    debugLog("🖼️ screen attached")
                    matchScreen(thisScreen: missingScreen)
                } else {
                    errorLog("🖼️ still missing screen")
                }
            } else {
                debugLog("🖼️ early foundScreen ok \(String(describing: foundScreen))")
            }
        } else {
            thisScreen = displayDetection.findScreenWith(frame: self.frame)
        }
        
        // We note the foundFrame as this is more accurate than the reported one! We need this for coordinates mapping
        if let thisScreen = thisScreen {
            foundFrame = thisScreen.bottomLeftFrame
            foundScreen = thisScreen
            debugLog("🖼️ Using : \(String(describing: thisScreen))")
        }

        for twindow in NSApplication.shared.windows {
            debugLog("window : \(twindow.debugDescription)")
        }
        
        var localPlayer: AVPlayer?
        
        // Is the current screen disabled by user ?
        if !isPreview {
            // If it's an unknown screen, we leave it enabled
            if let screen = foundScreen {
                if !displayDetection.isScreenActive(id: screen.id) {
                    // Then we disable and exit
                    debugLog("🖼️ This display is not active, disabling")
                    isDisabled = true
                    return
                } else {
                    debugLog("Screen is active")
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
            if let index = AerialView.sharedPlayerIndex {
                self.playerLayer.player = AerialView.instanciatedViews[index].player
                self.playerLayer.opacity = 0
                return
            }
        }

        // We're never sharing the preview !
        if !isPreview {
            AerialView.singlePlayerAlreadySetup = true
            AerialView.sharedPlayerIndex = AerialView.instanciatedViews.count-1
        }

        // So first we wait for our list to be ready
        VideoList.instance.addCallback {
            // Then we may need to delay things a bit if we haven't gathered the coordinates yet
            if PrefsTime.timeMode == .locationService && Locations.sharedInstance.coordinates == nil {
                debugLog("🖼️⚠️ No coordinates yet, delaying a bit...")
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    self.playNextVideo()
                }
            } else {
                self.playNextVideo()
            }
        }
    }
    
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if foundScreen == nil {
            debugLog("🖼️ \(self.description) viewDidMoveToWindow frame: \(self.frame) window: \(String(describing: self.window))")
            debugLog(self.window?.screen.debugDescription ?? "Unknown")
            
            if let thisScreen = self.window?.screen {
                matchScreen(thisScreen: thisScreen)
            } else {
                // For some reason we may not have a screen here!
                debugLog("🖼️ no screen attached, will try again later")
            }
        } else {
            debugLog("🖼️ wdmtw after we already have a screen, ignoring")
        }
        
    }

    func matchScreen(thisScreen: NSScreen) {
        let screenID = thisScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID
        
        debugLog(screenID.description)
        
        foundScreen = DisplayDetection.sharedInstance.findScreenWith(id: screenID)
        if let foundScreen = foundScreen {
            foundFrame = foundScreen.bottomLeftFrame
            if #available(macOS 14, *) {
                self.frame = foundFrame!

                // remove it from the list of unused screens
                DisplayDetection.sharedInstance.markScreenAsUsed(id: screenID)
            }
        }

        debugLog("🖼️🌾 Using : \(String(describing: foundScreen))")
        debugLog("🥬🌾 window.screen \(String(describing: self.window?.screen.debugDescription))")
        debugLog("🖼️🌾 self.frame : \(String(describing: self.frame))")
    }
    
    // Handle window resize
    override func viewDidEndLiveResize() {
        layerManager.redrawAllCorners()
    }
    
    override func viewDidChangeBackingProperties() {
        debugLog("🖼️ \(self.description) backing change \((self.window?.backingScaleFactor) ?? 1.0) isDisabled: \(isDisabled) frame: \(self.frame) preview: \(self.isPreview)")

        // Tentative workaround for a Catalina+ bug
        if self.frame.width < 300 && !isPreview {
            debugLog("🖼️☢️ Frame size bug, trying to override to \(originalWidth)x\(originalHeight)!")
            self.frame = CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight)
        }

        if !isDisabled {
            if let layer = layer, let window = self.window {
                layer.contentsScale = (window.backingScaleFactor) ?? 1.0
                self.playerLayer.contentsScale = (window.backingScaleFactor) ?? 1.0

                // And our additional layers
                layerManager.setContentScale(scale: (window.backingScaleFactor) ?? 1.0)
            }
        }
    }

    // On previews, it's possible that our shared player was stopped and is not reusable
    func cleanupSharedViews() {
        if AerialView.singlePlayerAlreadySetup {
            if let index = AerialView.sharedPlayerIndex {
                if AerialView.instanciatedViews[index].wasStopped {
                    AerialView.singlePlayerAlreadySetup = false
                    AerialView.sharedPlayerIndex = nil

                    AerialView.instanciatedViews = [AerialView]()   // Clear the list of instanciated stuff
                    AerialView.sharedViews = [AerialView]()         // And the list of sharedViews
                }
            }
        }
    }

    // MARK: - Lifecycle stuff
    override func startAnimation() {
        super.startAnimation()
        debugLog("🖼️ \(self.description) startAnimation frame \(self.frame) bounds \(self.bounds)")

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
        Aerial.helper.maybeUnmuteSound()

        wasStopped = true
        debugLog("🖼️ \(self.description) stopAnimation")
        if !isDisabled {
            player?.pause()
            player?.rate = 0
            layerManager.removeAllLayers()
            playerLayer.removeAllAnimations()
            player?.replaceCurrentItem(with: nil)

            isDisabled = true
        }

        if PrefsDisplays.dimBrightness {
            if !isPreview, let brightnessToRestore = brightnessToRestore {
                Brightness.set(level: brightnessToRestore)
                self.brightnessToRestore = nil
            }
        }
        
        
        teardown()
    }

    func teardown() {
        debugLog("🖼️ \(self.description) teardown")

        // Remove notifications observer
        debugLog("🖼️ \(self.description) clear notif")
        //clearNotifications()  // tmptest
        // Clear layer animations
        debugLog("🖼️ \(self.description) clear anims")
        clearAllLayerAnimations()

        if let player = player {
            // Remove from player index
            let indexMaybe = AerialView.players.firstIndex(of: player)

            guard let index = indexMaybe else {
                return
            }
            AerialView.players.remove(at: index)
        }
        
        // Remove any download
        VideoManager.sharedInstance.cancelAll()
       
        debugLog("🖼️ end teardown, exiting")
    }
    
    // Wait for the player to be ready
    // swiftlint:disable:next block_based_kvo
    internal override func observeValue(forKeyPath keyPath: String?,
                                        of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                                        context: UnsafeMutableRawPointer?) {
        debugLog("🖼️ \(description) observeValue \(String(describing: keyPath)) \(playerLayer.isReadyForDisplay)")

        if let player = player, let currentVideo = currentVideo, playerLayer.isReadyForDisplay {
            player.play()
            hasStartedPlaying = true

            if Aerial.helper.underCompanion {
                player.rate = globalSpeed
            } else {
                player.rate = PlaybackSpeed.forVideo(currentVideo.id)
            }

            debugLog("🖼️ start playback: \(frame) \(bounds) rate: \(player.rate)")
            debugLog("🥬🥬 window2 \(String(describing: window?.screen))")
            // If we share a player, we need to add the fades and the text to all the
            // instanciated views using it (eg: in mirrored mode)
            if AerialView.sharingPlayers {
                for view in AerialView.sharedViews {
                    self.addPlayerFades(view: view, player: player, video: currentVideo)
                    
                    if (Aerial.helper.underCompanion && PrefsInfo.hideUnderCompanion) {
                        debugLog("🖼️ Disable overlays under Companion")
                    } else {
                        view.layerManager.setupLayersForVideo(video: currentVideo, player: player)
                    }
                }
            } else {
                self.addPlayerFades(view: self, player: player, video: currentVideo)
                if (Aerial.helper.underCompanion && PrefsInfo.hideUnderCompanion) {
                    debugLog("🖼️ Disable overlays under Companion")
                } else {
                    self.layerManager.setupLayersForVideo(video: currentVideo, player: player)
                }
            }
        }
    }

    // Remove all the layer animations on all shared views
    func clearAllLayerAnimations() {
        // Clear everything
        if let player = player {
            layerManager.clearLayerAnimations(player: player)
            for view in AerialView.sharedViews {
                view.layerManager.clearLayerAnimations(player: player)
            }
        }
    }

    func clearNotifications() {
        NotificationCenter.default.removeObserver(self)
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
    func setNotifications(_ currentItem: AVPlayerItem) {
        let notificationCenter = NotificationCenter.default

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

        NSWorkspace.shared.notificationCenter.addObserver(
                self, selector: #selector(onSleepNote(note:)),
                name: NSWorkspace.willSleepNotification, object: nil)

        DistributedNotificationCenter.default.addObserver(self,
            selector: #selector(AerialView.willStart(_:)),
            name: Notification.Name("com.apple.screensaver.willstart"), object: nil)
        DistributedNotificationCenter.default.addObserver(self,
            selector: #selector(AerialView.willStop(_:)),
            name: Notification.Name("com.apple.screensaver.willstop"), object: nil)
        /*DistributedNotificationCenter.default.addObserver(self,
            selector: #selector(AerialView.screenIsUnlocked(_:)),
            name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)
        */
        Music.instance.setup()
    }

    func sendNotification(video: AerialVideo) {
        DistributedNotificationCenter.default.post(name: Notification.Name("com.glouel.aerial.nextvideo"), object: "aerialtest : " + video.name)
    }

    
    @objc func willStart(_ aNotification: Notification) {
        if Aerial.helper.underCompanion {
            debugLog("🖼️ 📢📢📢 willStart")
            player?.pause()
        }
    }

    @objc func screenIsUnlocked(_ aNotification: Notification) {
        if #available(macOS 14.0, *) {
            debugLog("🖼️ 📢📢📢 ☢️sonoma☢️ workaround screenIsUnlocked")
            if !Aerial.helper.underCompanion {
                if let player = player {
                    layerManager.removeAllLayers()
                    player.pause()
                }
                self.stopAnimation()
            } else {
                if !globalPause {
                    player?.play()
                    player?.rate = globalSpeed
                }
            }
        }
    }
    
    @objc func onSleepNote(note: Notification) {
        debugLog("🖼️ 📢📢📢 onSleepNote")
        if !Aerial.helper.underCompanion {
            if #available(macOS 14.0, *) {
                exit(0)
            }
        }
    }
    
    @objc func willStop(_ aNotification: Notification) {
        DisplayDetection.sharedInstance.resetUnusedScreens()

/*        if #available(macOS 14.0, *) {
            debugLog("🖼️ 📢📢📢 🖼️ 📢📢📢 ☢️sonoma☢️ workaround IGNORING willStop")
        } else {*/
        debugLog("🖼️ 📢📢📢 willStop")
        if !Aerial.helper.underCompanion {
            if let player = player {
                player.pause()
            }
            
            if #available(macOS 14.0, *) {
                debugLog("🖼️ ⏱️ Setting up 2-second delayed exit")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    debugLog("🖼️ 🚪 Exiting application now")
                    exit(0)
                }
            }

            self.stopAnimation()
        } else {
            if !globalPause {
                player?.play()
                player?.rate = globalSpeed
            }
        }
        //}
    }

    // Tentative integration with companion of extra features
    @objc func togglePause() {
        debugLog("🖼️ Toggling pause")
        if player?.rate == 0 {
            player?.play()
            player?.rate = globalSpeed
            globalPause = false
        } else {
            player?.pause()
            globalPause = true
        }
        removePlayerFades()
    }

    @objc func nextVideo() {
        debugLog("🖼️ Next video")
        fastFadeOut(andPlayNext: true)
    }

    @objc func skipAndHide() {
        guard let currentVideo = currentVideo else {
            errorLog("skipAndHide, no currentVideo")
            return
        }

        debugLog("🖼️ Skip video and hide")
        PrefsVideos.hidden.append(currentVideo.id)
        fastFadeOut(andPlayNext: true)
    }

    @objc func getGlobalSpeed() -> Float {
        guard let player = player else {
            errorLog("getGlobalSpeed, no player")
            return 0
        }
        debugLog("🖼️ Current global speed : " + String(globalSpeed))
        return player.rate
    }

    @objc func setGlobalSpeed(_ speed : Float)  {
        debugLog("🖼️ Setting speed to : " + String(speed))
        globalSpeed = speed

        // Apply now if playing
        if let player = player {
            if (player.rate != 0) {
                player.rate = globalSpeed
            }
        }
    }

    
    
    // MARK: - playNextVideo()
    // swiftlint:disable:next cyclomatic_complexity
    func playNextVideo() {
        debugLog("🖼️ \(self) pnv")

        clearAllLayerAnimations()

        clearNotifications()

        // play another video
        let player = AVPlayer()
        let oldPlayer = self.player
        self.player = player
        player.isMuted = PrefsAdvanced.muteSound

        self.playerLayer.player = self.player
        self.playerLayer.opacity = AerialView.shouldFade ? 0 : 1.0
        if self.isPreview {
            AerialView.previewPlayer = player
        }

        debugLog("🖼️ \(self.description) Setting player for all player layers in \(AerialView.sharedViews)")
        for view in AerialView.sharedViews {
            view.playerLayer.player = player
        }

        if oldPlayer == AerialView.previewPlayer {
            AerialView.previewView?.playerLayer.player = self.player
        }

        playerLayer.drawsAsynchronously = true

        // get a list of current videos that should be excluded from the candidate selection
        // for the next video. This prevents the same video from being shown twice in a row
        // as well as the same video being shown on two different monitors even when sharingPlayers
        // is false
        let currentVideos: [AerialVideo] = AerialView.players.compactMap { (player) -> AerialVideo? in
            (player.currentItem as? AerialPlayerItem)?.video
        }

        let (randomVideo, pshouldLoop) = VideoList.instance.randomVideo(excluding: currentVideos, isVertical: isScreenVertical())

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
            if let value = PrefsVideos.vibrance[video.id], !video.isHDR() {
                item.setVibrance(value)
            }
            if PrefsAdvanced.invertColors {
                item.setColorInvert()
            }

            player.replaceCurrentItem(with: item)
            debugLog("🖼️ \(self.description) streaming video (not fully available offline) : \(video.url)")

            guard let currentItem = player.currentItem else {
                errorLog("\(self.description) No current item!")
                return
            }

            debugLog("🖼️ \(self.description) observing current item \(currentItem)")

            // Descriptions and fades are set when we begin playback
            if !self.observerWasSet {
                observerWasSet = true
                playerLayer.addObserver(self, forKeyPath: "readyForDisplay", options: .initial, context: nil)
            }
            
            sendNotification(video: video)
            setNotifications(currentItem)

            player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none

            // Let's never download stuff in preview...
            if !isPreview {
                Cache.fillOrRollCache()
            }
        } else {
            // The new localpath getter
            let localPath = VideoList.instance.localPathFor(video: video)

            // let localurl = URL(fileURLWithPath: VideoCache.cachePath(forVideo: video)!)
            let localurl = URL(fileURLWithPath: localPath)
            let localitem = AVPlayerItem(url: localurl)
            if !video.isHDR() {
                let value = PrefsVideos.vibrance[video.id] ?? 0
                localitem.setVibrance(value)
            }
            if PrefsAdvanced.invertColors {
                localitem.setColorInvert()
            }
            
            DispatchQueue.global(qos: .default).async { [self] in
                player.replaceCurrentItem(with: localitem)
                debugLog("🖼️ \(self.description) playing video (OFFLINE MODE) : \(localurl)")
                guard let currentItem = player.currentItem else {
                    errorLog("\(self.description) No current item!")
                    return
                }

                debugLog("🖼️ \(self.description) observing current item \(currentItem)")

                // Descriptions and fades are set when we begin playback
                if !self.observerWasSet {
                    observerWasSet = true
                    playerLayer.addObserver(self, forKeyPath: "readyForDisplay", options: .initial, context: nil)
                }

                sendNotification(video: video)
                setNotifications(currentItem)

                player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none

                // Let's never download stuff in preview...
                if !isPreview {
                    Cache.fillOrRollCache()
                }
            }
        }
    }

    // Is the current screen vertical?
    func isScreenVertical() -> Bool {
        return self.frame.size.width < self.frame.size.height
    }

    override func keyDown(with event: NSEvent) {
        debugLog("🖼️ keyDown")

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
                    debugLog("🖼️⚠️ Right arrow key currently locked")
                }
            } else if event.keyCode == 125 {
                stopAnimation()
            } else {
                self.nextResponder!.keyDown(with: event)
                // super.keyDown(with: event)
            }
        } else {
            self.nextResponder?.keyDown(with: event)
            // super.keyDown(with: event)
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
        if !Aerial.helper.underCompanion {
            fadeOutAnimation.duration = AerialView.fadeDuration
        } else {
            fadeOutAnimation.values = [1, 1] as [Int]
            fadeOutAnimation.duration = 0.1
        }
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
            debugLog("🖼️ stop and next")
            playerLayer.removeAllAnimations()   // Make sure we get rid of our anim
            playNextVideo()
        } else {
            debugLog("🖼️ stop")
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

        let controller = PanelWindowController()
        preferencesController = controller
        return controller.window
    }
}
