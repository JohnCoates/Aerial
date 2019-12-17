//
//  LayerManager.swift
//  Aerial
//
//  Created by Guillaume Louel on 12/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
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

        // The list of known layers is in an ordered array
        for layerType in PrefsInfo.layers {
            switch layerType {
            case .location:
                if PrefsInfo.location.isEnabled {
                    let newLayer = LocationLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.location)
                    additionalLayers.append(newLayer)
                    layer.addSublayer(newLayer)
                }
            case .message:
                if PrefsInfo.message.isEnabled {
                    let newLayer = MessageLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.message)
                    additionalLayers.append(newLayer)
                    layer.addSublayer(newLayer)
                }
            case .clock:
                if PrefsInfo.clock.isEnabled {
                    let newLayer = ClockLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.clock)
                    additionalLayers.append(newLayer)
                    layer.addSublayer(newLayer)
                }
            }
        }
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
    func redrawCorner(corner: InfoCorner) {
        // first clear the offset on that corner
        offsets.corner[corner] = 0

        // Then move all our layers on that corner
        for layer in additionalLayers {
            if let layerCorner = layer.currentCorner {
                if layerCorner == corner {
                    layer.move(toCorner: corner, fullRedraw: true)
                }
            }
        }
    }

    // Do we allow a random description in a corner or not ?
    // We want to avoid the case where there's a layer on a bottom/top center already,
    // in that case, we don't allow left/right of those to avoid visual overlaps as our offsets
    // are corner based for simplicity
    func isCornerAcceptable(corner: Int) -> Bool {
        // Not the prettiest helper, this is a bit of a hack

        // If we have something topCenter, never allow random on top left/right
        if corner == 0 || corner == 2 {
            for layer in additionalLayers where layer.corner == .topCenter {
                return false
            }
        }

        // Same thing on the bottom
        if corner == 3 || corner == 5 {
            for layer in additionalLayers where layer.corner == .bottomCenter {
                return false
            }
        }

        // And never allow center if there's something in a corner
        // this one is a bit drastic as overlap isn't guaranteed but...
        if corner == 1 {
            for layer in additionalLayers where layer.corner == .topLeft
                || layer.corner == .topRight {
                return false
            }
        }

        // And same at the bottom
        if corner == 4 {
            for layer in additionalLayers where layer.corner == .bottomLeft
                || layer.corner == .bottomRight {
                return false
            }
        }

        return true
    }
}
