//
//  FiltersViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 02/08/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import AVKit

class FiltersViewController: NSViewController {
    @IBOutlet var imageView1: NSImageView!
    @IBOutlet var imageView2: NSImageView!
    @IBOutlet var imageView3: NSImageView!
    @IBOutlet var imageView4: NSImageView!

    @IBOutlet var vibranceSlider: NSSlider!

    @IBOutlet var infoIcon: NSButton!
    @IBOutlet var allowPerVideo: NSButton!
    var images: [NSImageView: CIImage] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        vibranceSlider.doubleValue = PrefsVideos.globalVibrance

        setupImages()
        redrawFilteredImages()

        infoIcon.setIcons("info.circle")

        allowPerVideo.state = PrefsVideos.allowPerVideoVibrance ? .on : .off
    }

    func setupImages() {
        // Let's reset
        images = [:]

        // Get the cached currentRotation
        let videos = VideoList.instance.currentRotation().filter({ $0.isAvailableOffline && !$0.isHDR() }).shuffled()

        if !videos.isEmpty {
            images[imageView1] = getImage(videos.first!)
        }
        if videos.count > 1 {
            images[imageView2] = getImage(videos[1])
        }
        if videos.count > 2 {
            images[imageView3] = getImage(videos[2])
        }
        if videos.count > 3 {
            images[imageView4] = getImage(videos[3])
        }

    }

    func redrawFilteredImages() {
        for (view, image) in images {
            setupImage(for: view, ciImage: image)
        }
    }

    func getImage(_ video: AerialVideo) -> CIImage? {
        if let url = Thumbnails.getLargeURL(forVideo: video) {
            return CIImage(contentsOf: url)!
        } else {
            return nil
        }
    }

    func setupImage(for imageView: NSImageView, ciImage: CIImage) {
        if #available(OSX 10.14, *) {
            if let vibrantImage = CIFilter(name: "CIVibrance",
                                           parameters: [kCIInputImageKey: ciImage, kCIInputAmountKey: PrefsVideos.globalVibrance] )?.outputImage {
                let rep = NSCIImageRep(ciImage: vibrantImage)
                let nsImage = NSImage(size: rep.size)
                nsImage.addRepresentation(rep)
                imageView.image = nsImage
            } else {
                errorLog("Couldn't apply vibrance filter, please report")
            }
        } else {
            // Fallback on earlier versions
            imageView.image = nil
        }

    }

    @IBAction func vibranceSliderChange(_ sender: NSSlider) {
        PrefsVideos.globalVibrance = sender.doubleValue
        redrawFilteredImages()
    }

    @IBAction func allowPerVideoChange(_ sender: NSButton) {
        PrefsVideos.allowPerVideoVibrance = sender.state == .on
    }

}
