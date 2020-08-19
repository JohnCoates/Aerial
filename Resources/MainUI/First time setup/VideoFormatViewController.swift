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

    @IBOutlet var labelBelow: NSTextField!
    var currentVideo: AerialVideo?

    var originalFormat: VideoFormat?
    override func viewDidLoad() {
        super.viewDidLoad()

        // We need catalina for HDR !
        if #available(OSX 10.15, *) {
        } else {
            menu1080pHDR.isHidden = true
            menu4KHDR.isHidden = true
        }

        // Only detect if we have the default basic format, don't override people's settings
        if PrefsVideos.videoFormat == .v1080pH264 {
            PrefsVideos.videoFormat = HardwareDetection.sharedInstance.getSuggestedFormat()
        } else {
            // swiftlint:ignore:next line_length
            labelBelow.stringValue = "Videos are usually available in multiple formats. Your current format is preselected, but you can pick another one."
            originalFormat = PrefsVideos.videoFormat
        }
        videoFormatPopup.selectItem(at: PrefsVideos.videoFormat.rawValue)

        previewView.player = AVPlayer()
        previewView.showsFullScreenToggleButton = true
        //previewView.controlsStyle = .none
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
        if let original = originalFormat {
            let candidateFormat = VideoFormat(rawValue: sender.indexOfSelectedItem)!

            if candidateFormat != original {
                if !Aerial.showAlert(question: "Changing format will delete all videos", text: "Changing format will delete your downloaded videos. They will be re-downloaded based on your preferences. \n\nYou can manually redownload videos in Custom Sources.", button1: "Change Format and Delete Videos", button2: "Cancel") {
                    videoFormatPopup.selectItem(at: PrefsVideos.videoFormat.rawValue)
                    return
                }
            }
        }

        PrefsVideos.videoFormat = VideoFormat(rawValue: sender.indexOfSelectedItem)!
        setupPlayer()
    }

    func setupPlayer() {
        if let player = previewView.player {
            if let video = currentVideo {
                player.pause()

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
        currentVideo = VideoList.instance.videos.filter({ $0.hasHDR() == true }).shuffled().first
    }
}
