//
//  VideosViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 15/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import AVKit

class VideosViewController: NSViewController {
    // Top rotation view
    @IBOutlet var rotationView: NSView!
    @IBOutlet var rotationPopup: NSPopUpButton!

    @IBOutlet var locationMenu: NSMenu!
    @IBOutlet var timeMenu: NSMenu!
    @IBOutlet var sceneMenu: NSMenu!
    @IBOutlet var setMenu: NSMenu!

    @IBOutlet var videoListTableView: NSTableView!

    @IBOutlet var heroPlayerView: AVPlayerView!
    @IBOutlet var heroImageView: NSImageView!

    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var locationLabel: NSTextField!
    @IBOutlet var durationLabel: NSTextField!

    @IBOutlet var sourceLabel: NSTextField!
    @IBOutlet var formatLabel: NSTextField!

    @IBOutlet var timeImageView: NSImageView!
    @IBOutlet var sceneTypeImageView: NSImageView!

    @IBOutlet var downloadButton: NSButton!

    var path: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        rotationView.isHidden = true
        // Our video list
        videoListTableView.delegate = self
        videoListTableView.dataSource = self

        // Drop shadow we use on the overlayed items
        let shadow: NSShadow = NSShadow()
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = NSSize(width: 0, height: 3)
        shadow.shadowColor = NSColor.black
        // For images the height coordinates are reversed, obviously...
        let imgShadow: NSShadow = NSShadow()
        imgShadow.shadowBlurRadius = 2
        imgShadow.shadowOffset = NSSize(width: 0, height: -3)
        imgShadow.shadowColor = NSColor.black

        titleLabel.shadow = shadow
        locationLabel.shadow = shadow
        durationLabel.shadow = shadow
        timeImageView.shadow = imgShadow
        sceneTypeImageView.shadow = imgShadow

        heroPlayerView.player = AVPlayer()
        heroPlayerView.controlsStyle = .none
        if #available(OSX 10.10, *) {
            heroPlayerView.videoGravity = .resizeAspectFill
        }
        // tmp
        /*largeImageView.imageScaling = .scaleAxesIndependently
        let imagePath = Bundle(for: PreferencesWindowController.self).path(
            forResource: "previewtest",
            ofType: "jpg")

        if let imagePath = imagePath {
            largeImageView.image = NSImage(contentsOfFile: imagePath)
        } else {
            print("bla no img")
        }*/

        updateVideoView()
        updateRotationMenu()
    }

    func reloadFor(path: String) {
        print("reload for : \(path)")

        self.path = path

        // We show/hide the top panel to pick the playing mode
        rotationView.isHidden = !path.starts(with: "rotation")
        if path.starts(with: "rotation") {
            updateRotationMenu()
        }

        if videoListTableView != nil {
            videoListTableView.reloadData()
            videoListTableView.selectRowIndexes([0], byExtendingSelection: false)
            videoListTableView.scrollRowToVisible(0)
        }
    }

    func updateVideoView() {
        if let video = getSelectedVideo() {
            titleLabel.isHidden = false
            locationLabel.isHidden = false
            sourceLabel.isHidden = false
            formatLabel.isHidden = false

            titleLabel.stringValue = video.secondaryName
            titleLabel.sizeToFit()

            locationLabel.stringValue = video.name
            locationLabel.sizeToFit()

            sourceLabel.stringValue = video.source.name
            sourceLabel.sizeToFit()

            formatLabel.stringValue = video.getBestFormat()
            formatLabel.sizeToFit()

            if video.isAvailableOffline {
                // Show player
                heroPlayerView.isHidden = false
                heroImageView.isHidden = true

                durationLabel.isHidden = false
                durationLabel.stringValue = "Duration: " + timeString(video.duration)

                downloadButton.isHidden = true
                if let player = heroPlayerView.player {
                    let path = VideoCache.cachePath(forVideo: video)!
                    debugLog("heropath : \(path)")

                    let localitem = AVPlayerItem(url: URL(fileURLWithPath: path))

                    player.replaceCurrentItem(with: localitem)
                    player.play()
                }
            } else {
                // Show image
                heroPlayerView.isHidden = true
                heroImageView.isHidden = false

                durationLabel.isHidden = true
                downloadButton.isHidden = false

                // Clear up any playing video
                if let player = heroPlayerView.player {
                    player.replaceCurrentItem(with: nil)
                    player.pause()
                }

                heroImageView.imageScaling = .scaleProportionallyDown

                Thumbnails.getLarge(forVideo: video) { [weak self] (img) in
                    guard let _ = self else { return }
                    if let img = img {
                        self!.heroImageView.image = img
                    } else {
                        self!.heroImageView.image = nil
                    }
                }
            }

            setTimeIcon(video)
            setSceneIcon(video)
        } else {
            titleLabel.isHidden = true
            locationLabel.isHidden = true
            durationLabel.isHidden = true
            sourceLabel.isHidden = true
            formatLabel.isHidden = true
        }
    }

    func updateRotationMenu() {

        //locationMenu.removeAllItems()
        for location in VideoList.instance.getSources(mode: .location) {
            print(location.string)

            let item = NSMenuItem(title: location.string, action: #selector(self.setRotationToLocation(menuItem:)), keyEquivalent: "")
                                    //#selector(VideosViewController.setRotationToLocation(menuItem:)), keyEquivalent: "")
            item.isEnabled = true
            locationMenu.addItem(item)
        }

    }

    //
    @objc func setRotationToLocation(menuItem: NSMenuItem) {
        print("menuitem")
        print(menuItem)
    }

    // Helper
    func timeString(_ double: Double) -> String {
        let intValue = Int(double)
        if intValue % 60 < 10 {
            return String(intValue / 60) + ":0" + String(intValue % 60)
        } else {
            return String(intValue / 60) + ":" + String(intValue % 60)
        }
    }

    func getSelectedVideo() -> AerialVideo? {
        if let path = path {
            print(path)
            if let mode = modeFromPath(path) {
                let index = Int(path.split(separator: ":")[1])!
                return VideoList.instance.getVideoForSource(index, item: videoListTableView.selectedRow, mode: mode)
            } else {
                // all
                return VideoList.instance.videos[videoListTableView.selectedRow]
            }
        }

        return nil
    }

    // Set the time icon
    func setTimeIcon(_ video: AerialVideo) {
        var name = ""
        switch video.timeOfDay {
        case "sunset":
            name = "sunset"
        case "sunrise":
            name = "sunrise"
        case "night":
            name = "moon.stars"
        default:    // day
            name = "sun.max"
        }

        if let imagePath = Bundle(for: PreferencesWindowController.self).path(
            forResource: name,
            ofType: "pdf") {
            timeImageView.image = NSImage(contentsOfFile: imagePath)
        }
    }

    // Set the scene icon (landscape...)
    func setSceneIcon(_ video: AerialVideo) {
        if #available(OSX 10.16, *) {
            switch video.scene {
            case .landscape:
                sceneTypeImageView.image = NSImage(systemSymbolName: "leaf", accessibilityDescription: "Landscape")?.tinting(with: .white)
            case .city:
                sceneTypeImageView.image = NSImage(systemSymbolName: "building", accessibilityDescription: "City")?.tinting(with: .white)
            case .space:
                sceneTypeImageView.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Space")?.tinting(with: .white)
            case .sea:
                sceneTypeImageView.image = NSImage(systemSymbolName: "drop", accessibilityDescription: "Sea")?.tinting(with: .white)
            }
        } else {
            // Fallback on earlier versions
        }
    }

    func modeFromPath(_ path: String) -> VideoList.FilterMode? {
        if path.starts(with: "location:") {
            return .location
        } else if path.starts(with: "cache:") {
            return .cache
        } else if path.starts(with: "time:") {
            return .time
        } else if path.starts(with: "scene:") {
            return .scene
        } else if path.starts(with: "rotation:") {
            return .rotation
        } else {
            return nil
        }
    }

    @IBAction func downloadButton(_ sender: Any) {
        downloadButton.isHidden = true
        if let video = getSelectedVideo() {
            let videoManager = VideoManager.sharedInstance
            Cache.ensureDownload {
                videoManager.queueDownload(video)
            }
        }
    }

    func updateInPlace() {
        print("UPDATE IN PLACE")
        let row = videoListTableView.selectedRow

        if videoListTableView != nil {
            videoListTableView.reloadData()
            videoListTableView.selectRowIndexes([row], byExtendingSelection: false)
        }
    }

    @IBAction func rotationPopup(_ sender: NSPopUpButton) {
    }

}

extension VideosViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let path = path else {
            return 0
        }

        if let mode = modeFromPath(path) {
            let index = Int(path.split(separator: ":")[1])!
            return VideoList.instance.getVideosCountForSource(index, mode: mode)
        } else {
            // all
            return VideoList.instance.videos.count
        }
    }
}

extension VideosViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let path = path else {
            return nil
        }

        var video: AerialVideo
        if let mode = modeFromPath(path) {
            let index = Int(path.split(separator: ":")[1])!
            video = VideoList.instance.getVideoForSource(index, item: row, mode: mode)
        } else {
            // all
            video = VideoList.instance.videos[row]
        }

        if let cell = tableView.makeView(withIdentifier:
            NSUserInterfaceItemIdentifier(rawValue: "ImageCellID"), owner: nil) as? VideoCellView {
            cell.video = video
            cell.label.stringValue = video.secondaryName

            let preferences = Preferences.sharedInstance
            cell.checkButton.state = preferences.videoIsInRotation(videoID: video.id) ? .on : .off

            cell.downloadButton.isHidden = video.isAvailableOffline

            Thumbnails.get(forVideo: video) { [weak self] (img) in
                guard let _ = self else { return }
                if let img = img {
                    cell.thumbView.image = img
                } else {
                    cell.thumbView.image = nil
                }
            }

            return cell
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateVideoView()
    }

}
