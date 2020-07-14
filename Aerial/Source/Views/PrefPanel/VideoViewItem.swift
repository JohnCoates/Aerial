//
//  VideoViewItem.swift
//  Aerial
//
//  Created by Guillaume Louel on 13/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class VideoViewItem: NSCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
    }

    /*var videoFile: VideoFile? {
        didSet {
            guard isViewLoaded else { return }
            if let videoFile = videoFile {
                imageView.image = videoFile.thumba
            }
        }
    }*/
}
