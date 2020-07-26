//
//  YahooLogoLayer.swift
//  Aerial
//      CALayer for Yahoo logo (attribution is required for API access)
//
//  Created by Guillaume Louel on 17/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class YahooLayer: CALayer {
    override init() {
        super.init()
        let imagePath = Bundle(for: PanelWindowController.self).path(
            forResource: "white_retina",
            ofType: "png")

        let img = NSImage(contentsOfFile: imagePath!)
        frame.size.height = img!.size.height / 3
        frame.size.width = img!.size.width / 3
        contents = img
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
