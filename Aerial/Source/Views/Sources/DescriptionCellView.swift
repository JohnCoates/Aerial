//
//  DescriptionCellView.swift
//  Aerial
//
//  Created by Guillaume Louel on 09/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class DescriptionCellView: NSTableCellView {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var lastUpdatedLabel: NSTextField!
    @IBOutlet weak var videoCount: NSTextField!
    @IBOutlet weak var imageScene1: NSImageView!
    @IBOutlet weak var imageScene2: NSImageView!
    @IBOutlet weak var imageScene3: NSImageView!
    @IBOutlet weak var imageScene4: NSImageView!
    @IBOutlet weak var imageScene5: NSImageView!
    @IBOutlet weak var imageScene6: NSImageView!
    @IBOutlet weak var imageFilm: NSImageView!
    @IBOutlet weak var licenseButton: NSButton!
    @IBOutlet weak var moreButton: NSButton!
    @IBOutlet weak var refreshNowButton: NSButton!

    /// The item that represent the row in the outline view
    /// We may potentially use this cell for multiple outline views so let's make it generic
    var item: Any?

    /// The delegate of the cell
    // var delegate: CheckboxCellViewDelegate?

    override func awakeFromNib() {
        imageScene1.image = Aerial.getMiniSymbol("flame")
        imageScene2.image = Aerial.getMiniSymbol("tram.fill")
        imageScene3.image = Aerial.getMiniSymbol("sparkles")
        imageScene4.image = Aerial.getMiniSymbol("helm")
        imageScene5.image = Aerial.getMiniSymbol("helm")
        imageScene6.image = Aerial.getMiniSymbol("helm")
        imageFilm.image = Aerial.getMiniSymbol("film")

        // imageScene1.
        // checkboxButton.target = self
        // checkboxButton.action = #selector(self.didChangeState(_:))
    }

    /// Notify the delegate that the checkbox's state has changed
    @objc private func didChangeState(_ sender: NSObject) {
        // delegate?.checkboxCellView(self, didChangeState: checkboxButton.state)
    }

    @IBAction func licenseButtonClick(_ sender: NSButton) {
        if let source = item as? Source {
            let workspace = NSWorkspace.shared
            let url = URL(string: source.license)!
            workspace.open(url)
        }
    }

    @IBAction func moreButtonClick(_ sender: NSButton) {
        if let source = item as? Source {
            let workspace = NSWorkspace.shared
            let url = URL(string: source.more)!
            workspace.open(url)
        }
    }

    @IBAction func refreshNowButtonClick(_ sender: NSButton) {
        if let source = item as? Source {
            if source.isCachable {
                debugLog("Refreshing cacheable source")
                VideoList.instance.downloadSource(source: source)
            } else if source.type == .local {
                debugLog("Checking local directory")
                SourceList.updateLocalSource(source: source)
            } else {
                debugLog("Refreshing non-cacheable source")
                VideoList.instance.downloadSource(source: source)
            }
        }
    }
}
