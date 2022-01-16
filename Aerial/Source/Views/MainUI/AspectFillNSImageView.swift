//
//  AspectFillNSImageView.swift
//  Aerial
//
//  Created by Guillaume Louel on 20/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

open class AspectFillNSImageView: NSImageView {

    open override var image: NSImage? {
        get {
            return super.image
        }

        set {
            self.layer = CALayer()
            self.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
            self.layer?.contents = newValue
            self.wantsLayer = true

            super.image = newValue
        }
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    // the image setter isn't called when loading from a storyboard
    // manually set the image if it is already set
    required public init?(coder: NSCoder) {
        super.init(coder: coder)

        if let theImage = image {
            self.image = theImage
        }
    }

}
