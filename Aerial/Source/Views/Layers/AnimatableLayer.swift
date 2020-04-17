//
//  AnimatableLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

protocol AnimatableLayer {
    var layerManager: LayerManager { get set }
    func clear(player: AVPlayer)
    func setupForVideo(video: AerialVideo, player: AVPlayer)
}

extension AnimatableLayer {
    func clear(player: AVPlayer) {}
    func setupForVideo(video: AerialVideo, player: AVPlayer) {}

}
