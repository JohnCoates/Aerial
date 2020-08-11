//
//  VideoFormatViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 11/08/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import AVKit

class VideoFormatViewController: NSViewController {

    @IBOutlet var videoFormatPopup: NSPopUpButton!
    @IBOutlet var previewView: AVPlayerView!
    // We need to hide HDR pre-Catalina
    @IBOutlet var menu1080pHDR: NSMenuItem!
    @IBOutlet var menu4KHDR: NSMenuItem!

    var currentVideo: AerialVideo?
    override func viewDidLoad() {
        super.viewDidLoad()

        // We need catalina for HDR !
        if #available(OSX 10.15, *) {
        } else {
            menu1080pHDR.isHidden = true
            menu4KHDR.isHidden = true
        }
        PrefsVideos.videoFormat = HardwareDetection.sharedInstance.getSuggestedFormat()
        videoFormatPopup.selectItem(at: PrefsVideos.videoFormat.rawValue)

        previewView.player = AVPlayer()
        previewView.controlsStyle = .none
        if #available(OSX 10.10, *) {
            previewView.videoGravity = .resizeAspectFill
        }

        getNewVideo()
        setupPlayer()
    }

    @IBAction func newVideoClick(_ sender: Any) {
        getNewVideo()
        setupPlayer()
    }
    @IBAction func formatChange(_ sender: NSPopUpButton) {
        PrefsVideos.videoFormat = VideoFormat(rawValue: sender.indexOfSelectedItem)!
        setupPlayer()
    }

    func setupPlayer() {
        if let player = previewView.player {
            if let video = currentVideo {
                player.pause()
                print("replacing")

                if let onlineUrl = URL(string: (video.urls[PrefsVideos.videoFormat])!) {
                    let asset = AVAsset(url: onlineUrl)
                    let item = AVPlayerItem(asset: asset)
                    player.replaceCurrentItem(with: item)
                    player.play()
                }
            }
        }
    }

    // Get a random video available in all format
    func getNewVideo() {
        print(VideoList.instance.videos.count)
        currentVideo = VideoList.instance.videos.shuffled().first
        //currentVideo = VideoList.instance.videos.filter({ $0. }).shuffled().first
        print(currentVideo)
    }
}
