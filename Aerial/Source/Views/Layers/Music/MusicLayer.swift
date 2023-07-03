//
//  MusicLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 11/06/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class MusicLayer: AnimationLayer {
    var config: PrefsInfo.Music?
    var wasSetup = false
    var timer: Timer?
    var startTime: Date?
    var endTime: Date?

    let artworkLayer = ArtworkLayer()
    let nameLayer = CATextLayer()
    let artistLayer = CATextLayer()
    let albumLayer = CATextLayer()

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our inits
    override init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        super.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)

        self.opacity = 0
    }

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Music) {
        self.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
        self.config = config

        // Set our layer's font & corner now
        /*(self.font, self.fontSize) = getFont(name: config.fontName,
                                             size: config.fontSize)*/
        self.corner = config.corner
    }

    // Called at each new video, we only setup once though !
    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        // Only run this once
        if !wasSetup {
            setupLayer()

            // This is where the magic happens, we get notified if we need to display something
            Music.instance.addCallback { [self] songInfo in
                updateStatus(songInfo: songInfo)
                update()
            }

            wasSetup = true
            update()

            /*
            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")*/
        }

        // We trigger the first one manually, so we get data immediately
        debugLog("🎧🟧 manual triggering")
        Music.instance.mediaRemoteCallback(nil)
    }

    func setupLayer() {
        addSublayer(artworkLayer)

        // Song name on top
        nameLayer.string = ""
        (nameLayer.font, nameLayer.fontSize) = nameLayer.makeFont(name: PrefsInfo.music.fontName, size: PrefsInfo.music.fontSize)
        addSublayer(nameLayer)

        // Artist name below
        artistLayer.string = ""
        (artistLayer.font, artistLayer.fontSize) = artistLayer.makeFont(name: PrefsInfo.music.fontName, size: PrefsInfo.music.fontSize)
        addSublayer(artistLayer)

        // Artist name below
        albumLayer.string = ""
        (albumLayer.font, albumLayer.fontSize) = albumLayer.makeFont(name: PrefsInfo.music.fontName, size: PrefsInfo.music.fontSize)
        addSublayer(albumLayer)

        
        // frame/position stuff
        reframe()
    }

    func reframe() {
        // ReRect the name & artist
        let rect = nameLayer.calculateRect(string: nameLayer.string as! String,
                        font: nameLayer.font as! NSFont,
                        maxWidth: Double(layerManager.frame!.size.width))
        nameLayer.frame = rect
        nameLayer.contentsScale = self.contentsScale

        let rect2 = artistLayer.calculateRect(string: artistLayer.string as! String,
                                              font: artistLayer.font as! NSFont,
                                              maxWidth: Double(layerManager.frame!.size.width))
        artistLayer.frame = rect2
        artistLayer.contentsScale = self.contentsScale

        let rect3 = albumLayer.calculateRect(string: albumLayer.string as! String,
                                              font: albumLayer.font as! NSFont,
                                              maxWidth: Double(layerManager.frame!.size.width))
        albumLayer.frame = rect3
        albumLayer.contentsScale = self.contentsScale
        
        
        artworkLayer.contentsScale = self.contentsScale

        // Then calc our parent frame size
        let textHeight = nameLayer.frame.height + artistLayer.frame.height + albumLayer.frame.height
        let textWidth = max(nameLayer.frame.width, artistLayer.frame.width, albumLayer.frame.width)

        let artworkOffset = textHeight + 20

        frame.size = CGSize(width: textWidth + artworkOffset, height: textHeight)

        // If we don't have any song playing, we change the height to 0
        if (nameLayer.string as! String == "") && (artistLayer.string as! String == "") {
            frame.size.height = 0
        }

        // Position the things
        albumLayer.anchorPoint = CGPoint(x: 0, y: 0)
        albumLayer.position = CGPoint(x: artworkOffset, y: 0)

        nameLayer.anchorPoint = CGPoint(x: 0, y: 0)
        nameLayer.position = CGPoint(x: artworkOffset, y: albumLayer.frame.height - 6)

        artistLayer.anchorPoint = CGPoint(x: 0, y: 0)
        artistLayer.position = CGPoint(x: artworkOffset, y: albumLayer.frame.height + nameLayer.frame.height - 12)


        artworkLayer.anchorPoint = CGPoint(x: 0, y: 0)
        artworkLayer.position = CGPoint(x: 0, y: 0)
        artworkLayer.frame.size = CGSize(width: frame.size.height, height: frame.size.height)
    }

    func updateStatus(songInfo: SongInfo) {
        debugLog("🎧🟧 updateStatus")

        guard songInfo.name != "" else {
            opacity = 0
            frame.size.height = 0
            return
        }

        opacity = 1
        nameLayer.string = songInfo.name
        artistLayer.string = songInfo.artist
        albumLayer.string = songInfo.album
        artworkLayer.updateArtwork(artwork: songInfo.artwork)
        // frame/position stuff
        reframe()
    }
}
