//
//  LayerOffsets.swift
//  Aerial
//
//  Created by Guillaume Louel on 11/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation

class LayerOffsets {
    var corner = [Preferences.DescriptionCorner: CGFloat]()

    init() {
        corner[Preferences.DescriptionCorner.topLeft] = 0
        corner[Preferences.DescriptionCorner.topRight] = 0
        corner[Preferences.DescriptionCorner.bottomLeft] = 0
        corner[Preferences.DescriptionCorner.bottomRight] = 0
    }
}
