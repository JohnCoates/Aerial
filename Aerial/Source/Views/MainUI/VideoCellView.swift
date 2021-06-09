//
//  VideoCellView.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class VideoCellView: NSTableCellView {

    @IBOutlet var thumbView: NSImageView!
    @IBOutlet var label: NSTextField!
    @IBOutlet var checkButton: NSButton!
    @IBOutlet var downloadButton: NSButton!

    // var delegate: VideoCellViewDelegate?
    var video: AerialVideo?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        checkButton.target = self
        checkButton.action = #selector(self.didChangeState(_:))
        checkButton.image = Aerial.getSymbol("star")!.tinting(with: .white)
        checkButton.alternateImage = Aerial.getSymbol("star.fill")!.tinting(with: .white)

        let shadow: NSShadow = NSShadow()
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = NSSize(width: 0, height: 2)
        shadow.shadowColor = NSColor.black

        checkButton.shadow = shadow
        downloadButton.shadow = shadow

        // Drawing code here.
    }

    // Notify the delegate that the checkbox's state has changed
    @objc private func didChangeState(_ sender: NSObject) {
        if PrefsVideos.favorites.contains(video!.id) {
            PrefsVideos.favorites.remove(at: PrefsVideos.favorites.firstIndex(of: video!.id)!)
        } else {
            if !video!.isAvailableOffline {
                Cache.ensureDownload {
                    PrefsVideos.favorites.append(self.video!.id)
                    VideoManager.sharedInstance.queueDownload(self.video!)
                }
            } else {
                PrefsVideos.favorites.append(self.video!.id)
            }
        }
    }

    @IBAction func downloadButtonClick(_ sender: NSButton) {
        let videoManager = VideoManager.sharedInstance
        Cache.ensureDownload {
            videoManager.queueDownload(self.video!)
        }
    }

}
