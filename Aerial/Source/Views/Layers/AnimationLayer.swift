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
    func setContentScale(scale: CGFloat) {}

    // Called by the extension to set the text alignment
    func setAlignment(mode: CATextLayerAlignmentMode) {
        // alignmentMode = mode
    }

    // Super init, used by CATextLayer's setFont, etc
    override init(layer: Any) {
        layerManager = (layer as! AnimationLayer).layerManager
        isPreview = (layer as! AnimationLayer).isPreview
        baseLayer = (layer as! AnimationLayer).baseLayer
        offsets = (layer as! AnimationLayer).offsets
        corner = (layer as! AnimationLayer).corner
        super.init(layer: layer)
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

    // Update and move to a corner
    func update(redraw: Bool = false) {
        // This is the rect resized to our string
        let newCorner = getCorner()

        // For non text layer, we need to do this here, this is done in calculateRect for text layers...
        if frame.size.width+10 > offsets.maxWidth[corner]! {
            offsets.maxWidth[corner] = frame.size.width+10
        }
        move(toCorner: newCorner, fullRedraw: false)
    }
}
