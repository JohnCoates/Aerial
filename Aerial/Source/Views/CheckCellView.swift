//
//  CheckCellView.swift
//  Aerial
//
//  Created by John Coates on 10/24/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Cocoa

enum VideoStatus {
    case unknown, notAvailable,queued,downloading,downloaded
}
class CheckCellView: NSTableCellView {

    @IBOutlet var checkButton: NSButton!
    @IBOutlet var addButton: NSButton!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet var formatLabel: NSTextField!
    @IBOutlet var queuedImage: NSImageView!
    @IBOutlet var mainTextField: NSTextField!
    
    var onCheck: ((Bool) -> (Void))?
    var video: (AerialVideo)?
    var status = VideoStatus.unknown
    
    override required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        checkButton.target = self
        checkButton.action = #selector(CheckCellView.check(_:))
    }
    
    @objc func check(_ button: AnyObject?) {        
        guard let onCheck = self.onCheck else {
            return
        }
        
        onCheck(checkButton.state == NSControl.StateValue.on)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func adaptIndicators() {
        let videoManager = VideoManager.sharedInstance
        
        if #available(OSX 10.12.2, *) {
            queuedImage.image = NSImage(named: NSImage.touchBarDownloadTemplateName)
        }
        
        if video!.isAvailableOffline {
            status = .downloaded
            addButton.isHidden = true
            progressIndicator.isHidden = true
            queuedImage.isHidden = true
        }
        else if videoManager.isVideoQueued(id: video!.id) {
            status = .queued
            addButton.isHidden = true
            progressIndicator.isHidden = true
            queuedImage.isHidden = false
        } else {
            status = .notAvailable
            addButton.isHidden = false
            progressIndicator.isHidden = true
            queuedImage.isHidden = true
        }

        if video!.url4KHEVC == "" {
            formatLabel.isHidden = true        // Hide the 4K indicator
        } else {
            formatLabel.isHidden = false
        }
    }
    
    func updateProgressIndicator(progress: Double) {
        if status != .downloading {
            addButton.isHidden = true
            progressIndicator.isHidden = false
            queuedImage.isHidden = true
            status = .downloading
        }

        progressIndicator.doubleValue = Double(progress)
    }
    
    // Add video handling
    func setVideo(video:AerialVideo) {
        self.video = video
    }
    
    func markAsDownloaded() {
        addButton.isHidden = true
        progressIndicator.isHidden = true
        queuedImage.isHidden = true
        status = .downloaded
        
        NSLog("video download finished")
        video!.updateDuration()
    }
    
    func markAsQueued() {
        debugLog("queued \(video!)")
        status = .queued
        addButton.isHidden = true
        progressIndicator.isHidden = true
        queuedImage.isHidden = false
    }

    func queueVideo() {
        let videoManager = VideoManager.sharedInstance
        videoManager.queueDownload(video!)
    }

    @IBAction func addClick(_ button: NSButton?) {
        queueVideo()
    }
    
}


class VerticallyAlignedTextFieldCell: NSTextFieldCell {
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let newRect = NSRect(x: 0, y: (rect.size.height - 20) / 2, width: rect.size.width, height: 20)
        return super.drawingRect(forBounds: newRect)
    }
}
