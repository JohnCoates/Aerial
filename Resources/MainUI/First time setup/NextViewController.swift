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
    @IBOutlet var previousButton: NSButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    func setNoPrev() {
        previousButton.isEnabled = false
        nextButton.isEnabled = true
        nextButton.title = "Next"
    }

    func setPrevNext() {
        previousButton.isEnabled = true
        nextButton.isEnabled = true
        nextButton.title = "Next"
    }

    func setClose() {
        previousButton.isEnabled = true
        nextButton.isEnabled = true
        nextButton.title = "Close"
    }

    @IBAction func previousButtonClick(_ sender: Any) {
        windowController!.previousAction()
    }

    @IBAction func nextButtonClick(_ sender: Any) {
        windowController!.nextAction()
    }
}
