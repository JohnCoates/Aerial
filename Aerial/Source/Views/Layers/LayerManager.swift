//
//  LayerManager.swift
//  Aerial
//
//  Created by Guillaume Louel on 12/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import AVKit

class LayerManager {
    var additionalLayers = [AnimationLayer]()
    let offsets = LayerOffsets()
    var isPreview: Bool

    init(isPreview: Bool) {
        self.isPreview = isPreview
    }

    // Initial setup of all layers, at Aerial startup
    func setupExtraLayers(layer: CALayer) {
        let layer1 = DescriptionLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self)

        additionalLayers.append(layer1)
        layer.addSublayer(layer1)

        let layer3 = ClockLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self)
        additionalLayers.append(layer3)
        layer.addSublayer(layer3)

    }

    // Called before starting a new video
    func clearLayerAnimations(player: AVPlayer) {
        for layer in additionalLayers {
            layer.clear(player: player)
            layer.removeAllAnimations()
        }
    }

    // Called at each new video
    func setupLayersForVideo(video: AerialVideo, player: AVPlayer) {
        for layer in additionalLayers {
            layer.setupForVideo(video: video, player: player)
        }
    }

    // This is called if a screen changes resolution
    // Can possibly happen when a new screen is connected/disconnected
    func setContentScale(scale: CGFloat) {
        for layer in additionalLayers {
            layer.contentsScale = scale
        }
    }

    // We use this to fully redraw all layers in a given corner
    // This is used by transient layers, like location information that's only shown
    // for a predefined amount of time
    func redrawCorner(corner: Preferences.DescriptionCorner) {
        // first clear the offset on that corner
        offsets.corner[corner] = 0

        // Then move all our layers on that corner
        for layer in additionalLayers {
            if let layerCorner = layer.currentCorner {
                if layerCorner == corner {
                    layer.move(corner: corner, fullRedraw: true)
                }
            }
        }
    }
}
