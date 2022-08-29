//
//  NowPlayingCollectionView.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/08/2022.
//  Copyright © 2022 Guillaume Louel. All rights reserved.
//

import Cocoa

class NowPlayingCollectionView: NSCollectionView {

    var clickedIndex: Int?

    override func menu(for event: NSEvent) -> NSMenu? {
        clickedIndex = nil

        let point = convert(event.locationInWindow, from: nil)
        for index in 0..<numberOfItems(inSection: 0) {
            let frame = frameForItem(at: index)
            if NSMouseInRect(point, frame, isFlipped) {
                clickedIndex = index
                break
            }
        }

        return super.menu(for: event)
    }
    
}
