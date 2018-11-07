//
//  AVPlayerViewExtension.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/10/2018.
//  Copyright © 2018 John Coates. All rights reserved.
//

import Foundation
import Cocoa
import AVKit

extension AVPlayerView {

    override open func scrollWheel(with event: NSEvent) {
        // Disable scrolling that can cause accidental video playback control (seek)
        return
    }

    override open func keyDown(with event: NSEvent) {
        // Disable space key (do not pause video playback)

        let spaceBarKeyCode = UInt16(49)
        if event.keyCode == spaceBarKeyCode {
            return
        }
    }
}
