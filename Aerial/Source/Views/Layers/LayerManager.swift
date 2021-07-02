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
    var additionalLayers = [AnimatableLayer]()
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
            let pos = PrefsInfo.ofType(layerType).corner

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

        // Then we may need to add our special update layer
        // It doesn't show in the main UI, it's linked to
        // options in the Updates tab
        let preferences = Preferences.sharedInstance

        if preferences.updateWhileSaverMode && PrefsUpdates.sparkleUpdateMode == .notify {
            addLayerForType(.updates, layer: layer)
        }

        // And reversed bottomRow
        for layerType in bottomRow.reversed() {
            addLayerForType(layerType, layer: layer)
        }

    }

    // swiftlint:disable:next cyclomatic_complexity
    private func addLayerForType(_ layerType: InfoType, layer: CALayer) {
        var newLayer: AnimatableLayer?

        if PrefsInfo.ofType(layerType).isEnabled && shouldEnableOnScreen(PrefsInfo.ofType(layerType).displays) {
            switch layerType {
            case .location:
                newLayer = LocationLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.location)
            case .message:
                newLayer = MessageLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.message)
            case .clock:
                newLayer = ClockLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.clock)
            case .date:
                newLayer = DateLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.date)
            case .battery:
                newLayer = BatteryIconLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.battery)
            case .updates:
                newLayer = DownloadIndicatorLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.updates)
            case .weather:
                newLayer = WeatherLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.weather)
            case .countdown:
                newLayer = CountdownLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.countdown)
            case .timer:
                newLayer = TimerLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.timer)
            case .music:
                newLayer = MusicLayer(withLayer: layer, isPreview: isPreview, offsets: offsets, manager: self, config: PrefsInfo.music)
            }
        }

        if let nLayer = newLayer {
            nLayer.drawsAsynchronously = true

            if !PrefsInfo.highQualityTextRendering {
                // This seems to help on some configurations
                // It has no impact on others and wrecks retina fonts though...
                nLayer.shouldRasterize = true
            }
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

        // If it's an unknown screen or a preview, we leave it enabled
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
        // We first setup all the regular layers, this will fill up the margin information
        // and act as a preflight so we can calculate how to wrap things for long location layer text
        for layer in additionalLayers where !(layer is LocationLayer) {
            layer.setupForVideo(video: video, player: player)
        }

        // And only last the Location layer !
        for layer in additionalLayers where layer is LocationLayer {
            layer.setupForVideo(video: video, player: player)
        }
    }

    // This is called if a screen changes resolution
    // Can possibly happen when a new screen is connected/disconnected
    func setContentScale(scale: CGFloat) {
        for layer in additionalLayers {
            layer.contentsScale = scale
            layer.setContentScale(scale: scale)
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

        // If we have something in both topCenter and bottomCenter, we could infinite loop
        // So as a precaution we allow whatever was picked
        for layer in additionalLayers where layer.corner == .topCenter {
            for layer2 in additionalLayers where layer2.corner == .bottomCenter {
                return true
            }
        }

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
