//
//  RecapViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 12/08/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class RecapViewController: NSViewController {
    @IBOutlet var imageDial: NSImageView!
    @IBOutlet var imageFav: NSImageView!
    @IBOutlet var imageHide: NSImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        imageDial.image = Aerial.getSymbol("dial")?.tinting(with: .secondaryLabelColor)
        imageFav.image = Aerial.getSymbol("star")?.tinting(with: .secondaryLabelColor)
        imageHide.image = Aerial.getSymbol("eye.slash")?.tinting(with: .secondaryLabelColor)
    }

    @IBAction func checkFAQ(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://aerialscreensaver.github.io/faq.html")!
        workspace.open(url)
    }

    @IBAction func checkJoshHal(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://www.jetsoncreative.com/aerial")!
        workspace.open(url)
    }
}
