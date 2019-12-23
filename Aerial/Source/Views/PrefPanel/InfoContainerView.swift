//
//  InfoContainerView.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoContainerView: NSView {
    // We need to override the coordinate mode (bottom left origin to top left origin)
    // so we can later add our child views from top to bottom
    override var isFlipped: Bool { return true }
}
