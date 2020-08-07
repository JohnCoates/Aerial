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

    var video: AerialVideo? {
        didSet {
            guard isViewLoaded else { return }
            if let video = video {
                Thumbnails.get(forVideo: video) { [weak self] (img) in
                    guard let _ = self else { return }
                    if let img = img {
                        self!.imageView?.image = img
                    } else {
                        self!.imageView?.image = nil
                    }
                }

                if video.secondaryName != "" {
                    textField?.stringValue = video.secondaryName
                } else {
                    textField?.stringValue = video.name
                }

            } else {
                imageView?.image = nil
                textField?.stringValue = ""
            }
        }
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
