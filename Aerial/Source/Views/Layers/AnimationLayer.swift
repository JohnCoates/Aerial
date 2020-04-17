//
//  AnimationLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class AnimationLayer: CALayer, AnimatableLayer {
    var layerManager: LayerManager
    var lastCorner = -1
    var isPreview: Bool
    var baseLayer: CALayer
    var offsets: LayerOffsets
    var corner: InfoCorner = .bottomLeft

    var currentCorner: InfoCorner?
    var currentHeight: CGFloat?
    var currentPosition: CGPoint?

    func clear(player: AVPlayer) {} // Optional
    func setupForVideo(video: AerialVideo, player: AVPlayer) {} // Pretty much required

    // Called by the extension to set the text alignment
    func setAlignment(mode: CATextLayerAlignmentMode) {
        // alignmentMode = mode
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our init
    init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        self.layerManager = manager
        self.isPreview = isPreview
        self.baseLayer = withLayer
        self.offsets = offsets
        super.init()

        // Same size as the screen
        self.frame = withLayer.bounds
        // Starts hidden, with a bit of shadow for text separation
        self.opacity = 0
        self.shadowRadius = CGFloat(PrefsInfo.shadowRadius)
        self.shadowOpacity = PrefsInfo.shadowOpacity
        self.shadowOffset = CGSize(width: PrefsInfo.shadowOffsetX,
                                   height: PrefsInfo.shadowOffsetY)

        self.shadowColor = CGColor.black
    }
}
