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

    var source: Source?
    @IBAction func actionButton(_ sender: Any) {
        if let source = source {
            if source.type == .local {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: Cache.supportPath.appending("/"+source.name))
            } else {
                Cache.ensureDownload {
                    for video in VideoList.instance.videos.filter({ $0.source.name == source.name && !$0.isAvailableOffline }) {
                        VideoManager.sharedInstance.queueDownload(video)
                    }
                }
            }
        }
    }
}
