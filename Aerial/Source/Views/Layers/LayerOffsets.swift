//
//  LayerOffsets.swift
//  Aerial
//
//  Created by Guillaume Louel on 11/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation

class LayerOffsets {
    var corner = [InfoCorner: CGFloat]()

    init() {
        corner[.topLeft] = 0
        corner[.topCenter] = 0
        corner[.topRight] = 0
        corner[.bottomLeft] = 0
        corner[.bottomCenter] = 0
        corner[.bottomRight] = 0
        corner[.screenCenter] = 0
    }
}
