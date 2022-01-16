//
//  CacheSetupViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 12/08/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class CacheSetupViewController: NSViewController {
    @IBOutlet var imageView1: NSButton!
    @IBOutlet var imageView2: NSButton!
    @IBOutlet var imageView3: NSButton!

    @IBOutlet var choice1: NSButton!
    @IBOutlet var choice2: NSButton!
    @IBOutlet var choice3: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        imageView1.setLargeIcon("wand.and.stars")
        imageView2.setLargeIcon("wand.and.rays")
        imageView3.setLargeIcon("hand.raised")
        PrefsCache.enableManagement = true
        PrefsCache.cachePeriodicity = .weekly
    }

    @IBAction func radioChange(_ sender: NSButton) {
        switch sender {
        case choice1:
            PrefsCache.enableManagement = true
            PrefsCache.cachePeriodicity = .weekly
        case choice2:
            PrefsCache.enableManagement = true
            PrefsCache.cachePeriodicity = .never
        default:
            PrefsCache.enableManagement = false
        }
    }

}
