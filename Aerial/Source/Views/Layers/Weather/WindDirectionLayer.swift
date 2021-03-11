//
//  WindDirectionLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 05/03/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class WindDirectionLayer: CALayer {
    init(direction: CGFloat, size: CGFloat) {
        super.init()
        let imagePath = Bundle(for: PanelWindowController.self).path(
            forResource: "location.north",
            ofType: "pdf")

        let img = NSImage(contentsOfFile: imagePath!)
        frame.size.height = size
        frame.size.width = size
        contents = img
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
