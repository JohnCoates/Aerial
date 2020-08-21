//
//  UpdatesLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 11/02/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class DownloadIndicatorLayer: AnimationTextLayer {
    var config: PrefsInfo.Updates?
    var wasSetup = false
    var updateTimer: Timer?

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our inits
    override init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        super.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)

        // We start with a full opacity
        self.opacity = 1
    }

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Updates) {
        self.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
        self.config = config

        // Set our layer's font & corner now
        (self.font, self.fontSize) = getFont(name: config.fontName,
                                             size: config.fontSize)
        self.corner = .absTopRight
    }

    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        if !wasSetup && PrefsCache.showBackgroundDownloads {
            update(string: "")
            setupDownloadIndicatorLayer()
        }
    }

    // Setup the callbacks
    func setupDownloadIndicatorLayer() {
        // Setup the updates for the download status
        let videoManager = VideoManager.sharedInstance
        videoManager.addCallback { done, total in
            self.updateDownloads(done: done, total: total, progress: 0)
        }
        videoManager.addProgressCallback { done, total, progress in
            self.updateDownloads(done: done, total: total, progress: progress)
        }
    }

    func updateDownloads(done: Int, total: Int, progress: Double) {
        if total == 0 {
            update(string: "")
        } else {
            let progInt = Int(progress * 100)
            update(string: "Downloading: \(progInt) %")
        }
    }
}
