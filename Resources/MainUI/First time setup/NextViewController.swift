//
//  NextViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 29/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class NextViewController: NSViewController {
    var windowController: FirstSetupWindowController?

    @IBOutlet var nextButton: NSButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    @IBAction func nextButtonClick(_ sender: Any) {
        windowController!.nextAction()
    }
}
