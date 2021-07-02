//
//  InfoMusicView.swift
//  Aerial
//
//  Created by Guillaume Louel on 11/06/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoMusicView: NSView {
    @IBOutlet var storefrontPopup: NSPopUpButton!
    @IBOutlet var storefrontLabel: NSTextField!
    @IBOutlet var providerPopup: NSPopUpButton!

    // Init(ish)
    func setStates() {
        makeStoreFrontPopup()
        // Make sure we select the storefront
        storefrontPopup.selectItem(withTitle: PrefsInfo.appleMusicStoreFront)

        providerPopup.selectItem(withTitle: PrefsInfo.musicProvider)

        updatePopups()
    }

    @IBAction func providerPopupChange(_ sender: Any) {
        PrefsInfo.musicProvider = providerPopup.selectedItem!.title
        updatePopups()
    }

    @IBAction func storefrontPopupChange(_ sender: NSPopUpButton) {
        PrefsInfo.appleMusicStoreFront = storefrontPopup.selectedItem!.title
    }

    func updatePopups() {
        if PrefsInfo.musicProvider == "Apple Music" {
            storefrontPopup.isHidden = false
            storefrontLabel.isHidden = false
        } else {
            storefrontPopup.isHidden = true
            storefrontLabel.isHidden = true
        }
    }

    func makeStoreFrontPopup() {
        for storename in Music.instance.storefronts.keys.sorted() {
            storefrontPopup.addItem(withTitle: storename)
        }
    }

}
