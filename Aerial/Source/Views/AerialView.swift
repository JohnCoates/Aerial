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
  var playerLayerBack: AVPlayerLayer!
  var preferencesController: PreferencesWindowController?
  static var players: [AVPlayer] = [AVPlayer]()
  static var previewPlayer: AVPlayer?
  static var previewView: AerialView?

  var player: AVPlayer?
  var playerBack: AVPlayer?

  var currentPlayerIsFrontPlayer: Bool = false

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

  func setupPlayerLayers(withPlayer player: AVPlayer, andBackPlayer playerBack: AVPlayer) {

    if self.layer == nil {
      self.layer = CALayer()
    }
    guard let layer = self.layer else {
      NSLog("Aerial Errror: Couldn't create CALayer")
      return
    }
    self.wantsLayer = true
    layer.backgroundColor = NSColor.black.cgColor
    layer.needsDisplayOnBoundsChange = true
    layer.frame = self.bounds
    //        layer.backgroundColor = NSColor.greenColor().CGColor

    debugLog("setting up player layer with frame: \(self.bounds) / \(self.frame)")

    playerLayerBack = AVPlayerLayer(player: playerBack)
    if #available(OSX 10.10, *) {
      playerLayerBack.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    playerLayerBack.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
    playerLayerBack.frame = layer.bounds
    playerLayerBack.opacity = 1.0
    layer.addSublayer(playerLayerBack)

    playerLayer = AVPlayerLayer(player: player)
    if #available(OSX 10.10, *) {
      playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    playerLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
    playerLayer.frame = layer.bounds
    playerLayer.opacity = 0.5
    layer.addSublayer(playerLayer)



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


    let localPlayerBack = AVPlayer()
    self.playerBack = localPlayerBack
    setupPlayerLayers(withPlayer: player, andBackPlayer: localPlayerBack)



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

  func playerItemFailedtoPlayToEnd(_ aNotification: Notification) {
    NSLog("AVPlayerItemFailedToPlayToEndTimeNotification \(aNotification)")

    playNextVideo()
  }

  func playerItemNewErrorLogEntryNotification(_ aNotification: Notification) {
    NSLog("AVPlayerItemNewErrorLogEntryNotification \(aNotification)")
  }

  func playerItemPlaybackStalledNotification(_ aNotification: Notification) {
    NSLog("AVPlayerItemPlaybackStalledNotification \(aNotification)")
  }

  func playerItemDidReachEnd(_ aNotification: Notification) {
    debugLog("played did reach end")
    debugLog("notification: \(aNotification)")
//    playNextVideo()

    debugLog("playing next video for player \(player)")
  }

  // MARK: - Playing Videos


  func fadeLayerIn(layerToFade: AVPlayerLayer) {
    let inImation = CAKeyframeAnimation()
    inImation.keyPath = "opacity"
    inImation.keyTimes = [0,1]
    inImation.values = [0,1]
    inImation.duration = 3
    inImation.fillMode = kCAFillModeBoth
    inImation.isRemovedOnCompletion = false
    inImation.beginTime = CACurrentMediaTime()+0.5
    layerToFade.add(inImation, forKey: "inOpacity")
  }

  func fadeLayerOut(layerToFade: AVPlayerLayer) {
    let outImation = CAKeyframeAnimation()
    outImation.keyPath = "opacity"
    outImation.keyTimes = [0,1]
    outImation.values = [1,0]
    outImation.duration = 5
    outImation.fillMode = kCAFillModeBoth
    outImation.isRemovedOnCompletion = false
    // offset fade out at least by duration of fade in
    outImation.beginTime = CACurrentMediaTime()+4.0
    layerToFade.add(outImation, forKey: "outOpacity")
  }


  func playNextVideo() {
    let notificationCenter = NotificationCenter.default

    // remove old entries
    notificationCenter.removeObserver(self)

    let newPlayer = AVPlayer()
//    // play another video
//    let oldPlayer = self.player
//    self.player = player
//    self.playerLayer.player = self.player
//
//    if self.isPreview {
//      AerialView.previewPlayer = player
//    }
//
//    debugLog("Setting player for all player layers in \(AerialView.sharedViews)")
//    for view in AerialView.sharedViews {
//      view.playerLayer.player = player
//    }
//
//    if oldPlayer == AerialView.previewPlayer {
//      AerialView.previewView?.playerLayer.player = self.player
//    }

    let randomVideo = ManifestLoader.instance.randomVideo()

    guard let video = randomVideo else {
      NSLog("Aerial: Error grabbing random video!")
      return
    }
    let videoURL = video.url

    let asset = CachedOrCachingAsset(videoURL)
    let dummyAsset = AVAsset(url: videoURL)
    let fadeTime = CMTimeGetSeconds(dummyAsset.duration) - 10.0

    let item = AVPlayerItem(asset: asset)

    var currentItem: AVPlayerItem?

    //    player.replaceCurrentItem(with: item)
    if  !currentPlayerIsFrontPlayer {
      debugLog("\n\n---------\nplaying front player\n")
      debugLog("\(self.player?.currentItem)")
      self.player = newPlayer
      self.playerLayer.player = newPlayer
      self.player?.replaceCurrentItem(with: item)
      if self.player?.rate == 0 {
        self.player?.play()
      }
      if self.player?.currentItem !== nil {
        currentItem = self.player?.currentItem
      } else {
        NSLog("Aerial Error: No current item!")
        return
      }
      // fade in front player
      fadeLayerIn(layerToFade: self.playerLayer)

      self.player?.actionAtItemEnd = AVPlayerActionAtItemEnd.none
      self.player?.addBoundaryTimeObserver(forTimes: [NSValue(time:kCMTimeZero+CMTimeMakeWithSeconds(fadeTime,1))], queue: DispatchQueue.main) {
        self.playNextVideo()
      }
      self.currentPlayerIsFrontPlayer = true

    } else {
      debugLog("\n\n---------\nplaying back player\n")
      self.playerBack = newPlayer
      self.playerLayerBack.player = newPlayer
      self.playerBack?.replaceCurrentItem(with: item)
      if self.playerBack?.rate == 0 {
        self.playerBack?.play()
      }
      // start backplayer, fade it in then fade out front player
      if self.playerBack?.currentItem !== nil {
        currentItem = self.playerBack?.currentItem
      } else {
        NSLog("Aerial Error: No current item!")
        return
      }
//      fadeLayerIn(layerToFade: self.playerLayerBack)
      fadeLayerOut(layerToFade: self.playerLayer)

      self.playerBack?.actionAtItemEnd = AVPlayerActionAtItemEnd.none
      self.playerBack?.addBoundaryTimeObserver(forTimes: [NSValue(time:kCMTimeZero+CMTimeMakeWithSeconds(fadeTime,1))], queue: DispatchQueue.main) {
        self.playNextVideo()
      }
      self.currentPlayerIsFrontPlayer = false;

    }

    debugLog("playing video: \(video.url)")


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


  }

  // MARK: - Preferences

  override func hasConfigureSheet() -> Bool {
    return true
  }

  override func configureSheet() -> NSWindow? {
    if let controller = preferencesController {
      return controller.window
    }

    let controller = PreferencesWindowController(windowNibName: "PreferencesWindow")

    preferencesController = controller
    return controller.window
  }
}
