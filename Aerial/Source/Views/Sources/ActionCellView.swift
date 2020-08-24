//
//  ActionCellView.swift
//  Aerial
//
//  Created by Guillaume Louel on 31/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class ActionCellView: NSTableCellView {
    @IBOutlet var actionButton: NSButton!
    @IBOutlet var spinner: NSProgressIndicator!
    var source: Source?
    @IBAction func actionButton(_ sender: NSButton) {
        if let source = source {
            if source.type == .local {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: Cache.supportPath.appending("/"+source.name))
            } else {
                if source.isCachable {
                    Cache.ensureDownload {
                        sender.isHidden = true
                        self.spinner.isHidden = false
                        self.spinner.startAnimation(self)

                        for video in VideoList.instance.videos.filter({ $0.source.name == source.name && !$0.isAvailableOffline }) {
                            VideoManager.sharedInstance.queueDownload(video)
                        }
                    }
                } else {
                    sender.isHidden = true
                    spinner.isHidden = false
                    spinner.startAnimation(self)

                    for video in VideoList.instance.videos.filter({ $0.source.name == source.name && !$0.isAvailableOffline }) {
                        VideoManager.sharedInstance.queueDownload(video)
                    }
                }
            }
        }
    }
}
