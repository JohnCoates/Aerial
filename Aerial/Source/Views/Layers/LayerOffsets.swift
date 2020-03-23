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
    var maxWidth = [InfoCorner: CGFloat]()
    init() {
        corner[.topLeft] = 0
        corner[.topCenter] = 0
        corner[.topRight] = 0
        corner[.bottomLeft] = 0
        corner[.bottomCenter] = 0
        corner[.bottomRight] = 0
        corner[.screenCenter] = 0
        corner[.absTopRight] = 0

        maxWidth[.topLeft] = 0
        maxWidth[.topCenter] = 0
        maxWidth[.topRight] = 0
        maxWidth[.bottomLeft] = 0
        maxWidth[.bottomCenter] = 0
        maxWidth[.bottomRight] = 0
        maxWidth[.screenCenter] = 0
        maxWidth[.absTopRight] = 0
    }
}
