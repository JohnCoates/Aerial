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

    //var delegate: VideoCellViewDelegate?
    var video: AerialVideo?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        checkButton.target = self
        checkButton.action = #selector(self.didChangeState(_:))

        let shadow: NSShadow = NSShadow()
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = NSSize(width: 0, height: 1)
        shadow.shadowColor = NSColor.black

        checkButton.shadow = shadow
        downloadButton.shadow = shadow

        // Drawing code here.
    }

    // Notify the delegate that the checkbox's state has changed
    @objc private func didChangeState(_ sender: NSObject) {
        let preferences = Preferences.sharedInstance
        preferences.setVideo(videoID: video!.id, inRotation: checkButton.state == .on)
    }

    @IBAction func downloadButtonClick(_ sender: NSButton) {
        print("download")
        let videoManager = VideoManager.sharedInstance
        Cache.ensureDownload {
            videoManager.queueDownload(self.video!)
        }
    }

}
