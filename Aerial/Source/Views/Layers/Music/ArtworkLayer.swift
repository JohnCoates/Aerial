//
//  ArtworkLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 30/06/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Cocoa
import Foundation

class ArtworkLayer: CALayer {
    var defaultImg: NSImage?
    override init() {
        super.init()

        if #available(macOS 11.0, *) {
            let size: CGFloat = 200

            if let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "music.note") {
                image.isTemplate = true

                // return image
                let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
                let img = image.withSymbolConfiguration(config)?.tinting(with: .white)

                if let img = img {
                    frame.size.height = size
                    frame.size.width = size
                    contents = img
                    defaultImg = img
                }
            }
        }

    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateArtwork(id: String) {
        Music.instance.getArtworkUrl(id: id) { [self] artworkUrl in
            guard let artworkUrl = artworkUrl else {
                debugLog("no url found")
                if let defaultImg = defaultImg {
                    contents = defaultImg
                }
                return
            }

            print(artworkUrl)

            // Then grab said url
            getData(from: URL(string: artworkUrl)!) { data, _, error in
                guard let data = data, error == nil else {
                    if let defaultImg = defaultImg {
                        contents = defaultImg
                    }
                    return
                }

                DispatchQueue.main.async() {
                    let img = NSImage(data: data)
                    // Update it in the main thread
                    contents = img
                }
            }
        }
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
}
