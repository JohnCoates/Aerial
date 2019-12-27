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
    var frame: CGRect?

    init(isPreview: Bool) {
        self.isPreview = isPreview
    }

    // Initial setup of all layers, at Aerial startup
    func setupExtraLayers(layer: CALayer, frame: CGRect) {
        self.frame = frame

        var topRow = [InfoType]()
        var bottomRow = [InfoType]()

        // The list of known layers is in an ordered array
        // we need to split the bottom row though, as drawing them "in order" would look
        // reversed to users as we draw from the corner out
        for layerType in PrefsInfo.layers {
            let pos = getPositionForLayerType(layerType)

            if pos == .topCenter || pos == .topLeft || pos == .topRight || pos == .screenCenter {
                topRow.append(layerType)
            } else {
                bottomRow.append(layerType)
            }
        }

        // Then add top row
        for layerType in topRow {
            addLayerForType(layerType, layer: layer)
        }

        // And reversed bottomRow
        for layerType in bottomRow.reversed() {
            addLayerForType(layerType, layer: layer)
        }

    }

    private func getPositionForLayerType(_ layerType: InfoType) -> InfoCorner {
        switch layerType {
        case .location:
            return PrefsInfo.location.corner
        case .message:
            return PrefsInfo.message.corner
        case .clock:
            return PrefsInfo.clock.corner
        case .battery:
            return PrefsInfo.battery.corner
        }
    }

    private func addLayerForType(_ layerType: InfoType, layer: CALayer) {
        var newLayer: AnimationLayer?

        switch layerType {
        case .location:
            if PrefsInfo.location.isEnabled && shouldEnableOnScreen(PrefsInfo.location.displays) {
                newLayer = LocationLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.location)
            }
        case .message:
            if PrefsInfo.message.isEnabled && shouldEnableOnScreen(PrefsInfo.message.displays) {
                newLayer = MessageLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.message)
            }
        case .clock:
            if PrefsInfo.clock.isEnabled && shouldEnableOnScreen(PrefsInfo.clock.displays) {
                newLayer = ClockLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.clock)
            }
        case .battery:
            if PrefsInfo.battery.isEnabled && shouldEnableOnScreen(PrefsInfo.clock.displays) {
                newLayer = BatteryLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.battery)
            }
        }

        if let nLayer = newLayer {
            additionalLayers.append(nLayer)
            layer.addSublayer(nLayer)
        }

    }

    // Each layer may not be displayed on each screen
    func shouldEnableOnScreen(_ displayMode: InfoDisplays) -> Bool {
        let displayDetection = DisplayDetection.sharedInstance
        let thisScreen = displayDetection.findScreenWith(frame: frame!)

        if let screen = thisScreen, !isPreview {
            switch displayMode {
            case .allDisplays:
                debugLog("allDisplays")
                return true
            case .mainOnly:
                debugLog("mainOnly")
                return screen.isMain
            case .secondaryOnly:
                debugLog("secOnly")
                return !screen.isMain
            }
        }

        // If it's an unknown screen, we leave it enabled
        return true
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
    // This is a best effort to try and avoid overlaps,
    // but it's not 100% depending on font choices
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
