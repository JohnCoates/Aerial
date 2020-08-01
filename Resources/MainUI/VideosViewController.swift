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
    @IBOutlet var rotationImage: NSImageView!
    @IBOutlet var rotationCacheNow: NSButton!

    @IBOutlet var rotationSecondaryPopup: NSPopUpButton!
    @IBOutlet var rotationSecondaryMenu: NSMenu!

    @IBOutlet var videoListTableView: NSTableView!
    @IBOutlet var videoListRuntimeLabel: NSTextField!

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
    @IBOutlet var hideButton: NSButton!
    @IBOutlet var showButton: NSButton!

    @IBOutlet var isCachedImageView: NSImageView!

    var path: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        rotationView.isHidden = true

        // Our video list
        videoListTableView.delegate = self
        videoListTableView.dataSource = self

        // Our large player view
        heroPlayerView.player = AVPlayer()
        heroPlayerView.controlsStyle = .none
        if #available(OSX 10.10, *) {
            heroPlayerView.videoGravity = .resizeAspectFill
        }

        setShadows()
        fixIcons()

        updateVideoView()
        updateRotationMenu()
    }

    // MARK: - UI init
    /// Set the shadows for the various UI elements that needs them
    func setShadows() {
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
        hideButton.shadow = shadow
        showButton.shadow = shadow
        downloadButton.shadow = shadow
        timeImageView.shadow = imgShadow
        sceneTypeImageView.shadow = imgShadow
        isCachedImageView.shadow = imgShadow
    }

    /// Since we can't directly use SF Symbols, we use our own icon wrappers
    func fixIcons() {
        rotationPopup.item(at: 0)?.setIcons("film")
        rotationPopup.item(at: 1)?.setIcons("star")
        rotationPopup.item(at: 2)?.setIcons("mappin.and.ellipse")
        rotationPopup.item(at: 3)?.setIcons("clock")
        rotationPopup.item(at: 4)?.setIcons("tram.fill")
        rotationPopup.item(at: 5)?.setIcons("antenna.radiowaves.left.and.right")
        rotationImage.image = Aerial.getAccentedSymbol("dial.min")
        rotationCacheNow.setIcons("arrow.down.circle")
    }

    /// Reload the video view for a given path
    func reloadFor(path: String) {
        self.path = path

        // We show/hide the top panel to pick the playing mode
        rotationView.isHidden = !path.starts(with: "rotation")
        if path.starts(with: "rotation") {
            updateRotationMenu()
        }

        updateRuntimeLabel()

        // Reload data and scroll back up
        if videoListTableView != nil {
            videoListTableView.reloadData()
            videoListTableView.selectRowIndexes([0], byExtendingSelection: false)
            videoListTableView.scrollRowToVisible(0)

            if videoListTableView.numberOfRows == 0 {
                updateVideoView()
            }
        }
    }

    /// Update the total runtime for the current view
    func updateRuntimeLabel() {
        guard let path = self.path else {
            videoListRuntimeLabel.stringValue = ""
            return
        }

        // Grab all videos in the path
        var videos: [AerialVideo]
        if let mode = modeFromPath(path) {
            let index = Int(path.split(separator: ":")[1])!
            videos = VideoList.instance.getVideosForSource(index, mode: mode)
        } else {
            // all
            videos = VideoList.instance.videos.sorted { $0.secondaryName < $1.secondaryName }
        }

        // Calculate their duration in minutes
        var duration: Double = 0
        for video in videos {
            duration += video.duration
        }

        let minutes: Int = Int(duration) / 60

        var minutesString: String
        if minutes < 2 {
            minutesString = "1 minute"
        } else {
            minutesString = "\(minutes) minutes"
        }

        // Update the label
        if videos.isEmpty {
            videoListRuntimeLabel.stringValue = ""
        } else if videos.count == 1 {
            videoListRuntimeLabel.stringValue = "1 video, \(minutesString)"
        } else {
            videoListRuntimeLabel.stringValue = "\(videos.count) videos, \(minutesString)"
        }
    }

    // MARK: - Rotation menu

    /// Cache missing rotation now !
    @IBAction func rotationCacheNowClick(_ sender: NSButton) {
        Cache.ensureDownload {
            for video in VideoList.instance.currentRotation().filter({ !$0.isAvailableOffline }) {
                VideoManager.sharedInstance.queueDownload(video)
            }
        }
    }

    /// Main popup change event
    @IBAction func rotationPopupChange(_ sender: NSPopUpButton) {
        PrefsVideos.shouldPlay = ShouldPlay(rawValue: sender.indexOfSelectedItem)!

        // Cascade to a secondary popup for the various filters
        if PrefsVideos.shouldPlay == .everything || PrefsVideos.shouldPlay == .favorites {
            rotationSecondaryPopup.isHidden = true
            reloadFor(path: path!)
        } else {
            rotationSecondaryPopup.isHidden = false
            updateRotationSecondaryMenu()
            reloadFor(path: path!)
        }
    }

    /// Secondary popup change event
    @IBAction func rotationSecondaryPopupChange(_ sender: NSPopUpButton) {
        PrefsVideos.shouldPlayString = sender.selectedItem!.title

        reloadFor(path: path!)
    }

    func updateRotationMenu() {
        rotationPopup.selectItem(at: PrefsVideos.intShouldPlay)

        // Cascade to a secondary popup for the various filters
        if PrefsVideos.shouldPlay == .everything || PrefsVideos.shouldPlay == .favorites {
            rotationSecondaryPopup.isHidden = true
        } else {
            rotationSecondaryPopup.isHidden = false
            updateRotationSecondaryMenu()
        }

        if VideoList.instance.currentRotation().filter({ !$0.isAvailableOffline }).isEmpty {
            rotationCacheNow.isHidden = true
        } else {
            rotationCacheNow.isHidden = false
        }
    }

    func updateRotationSecondaryMenu() {
        var filter: VideoList.FilterMode

        // ...
        switch PrefsVideos.shouldPlay {
        case .location:
            filter = .location
        case .scene:
            filter = .scene
        case .time:
            filter = .time
        case .source:
            filter = .source
        default:
            filter = .location // ...
        }

        rotationSecondaryPopup.removeAllItems()

        // Very unswift
        var index = 0
        var foundIndex = -1
        for item in VideoList.instance.getSources(mode: filter) {
            rotationSecondaryPopup.addItem(withTitle: item.string)
            if item.string == PrefsVideos.shouldPlayString {
                foundIndex = index
            }

            index += 1
        }
        if foundIndex > -1 {
            rotationSecondaryPopup.selectItem(at: foundIndex)
        } else {
            // We select the first one if nothing was found
            if rotationSecondaryPopup.numberOfItems > 0 {
                PrefsVideos.shouldPlayString = rotationSecondaryPopup.itemTitle(at: 0)
                rotationSecondaryPopup.selectItem(at: 0)
            }
        }
    }

    // MARK: - Video view
    func updateVideoView() {
        if let video = getSelectedVideo() {
            titleLabel.isHidden = false
            locationLabel.isHidden = false
            sourceLabel.isHidden = false
            formatLabel.isHidden = false

            titleLabel.stringValue = video.secondaryName
            locationLabel.stringValue = video.name
            sourceLabel.stringValue = video.source.name
            formatLabel.stringValue = video.getBestFormat()

            if PrefsVideos.hidden.contains(video.id) {
                hideButton.isHidden = true
                showButton.isHidden = false
            } else {
                hideButton.isHidden = false
                showButton.isHidden = true
            }

            if video.isAvailableOffline {
                // Show player
                heroPlayerView.isHidden = false
                heroImageView.isHidden = true
                isCachedImageView.isHidden = false

                durationLabel.isHidden = false
                durationLabel.stringValue = "Duration: " + timeString(video.duration)

                downloadButton.isHidden = true
                if let player = heroPlayerView.player {
                    let path = VideoCache.cachePath(forVideo: video)!
                    debugLog("heropath : \(path)")

                    // let filter = CIFilter(name: "CIVibrance")!
                    let asset = AVAsset(url: URL(fileURLWithPath: path))
                    let localitem = AVPlayerItem(asset: asset)
                    /*localitem.videoComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                        let source = request.sourceImage.clampedToExtent()
                        filter.setValue(source, forKey: kCIInputImageKey)
                        if #available(OSX 10.14, *) {
                            filter.setValue(0.3, forKey: kCIInputAmountKey)
                        } else {
                            // Fallback on earlier versions
                        }
                        let output = filter.outputImage

                        request.finish(with: output!, context: nil)
                    })*/

                    player.replaceCurrentItem(with: localitem)
                    player.play()
                }
            } else {
                // Show image
                heroPlayerView.isHidden = true
                heroImageView.isHidden = false
                isCachedImageView.isHidden = true

                durationLabel.isHidden = true
                if PrefsCache.enableManagement {
                    downloadButton.isHidden = true  // Always hide in managed mode
                } else {
                    downloadButton.isHidden = false
                }

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
            // Hide everything !
            titleLabel.isHidden = true
            locationLabel.isHidden = true
            durationLabel.isHidden = true
            sourceLabel.isHidden = true
            formatLabel.isHidden = true

            heroPlayerView.isHidden = true
            heroImageView.isHidden = true
            isCachedImageView.isHidden = true

            downloadButton.isHidden = true
            hideButton.isHidden = true
            showButton.isHidden = true

            // Clear up any playing video
            if let player = heroPlayerView.player {
                player.replaceCurrentItem(with: nil)
                player.pause()
            }

            setTimeIcon(nil)
            setSceneIcon(nil)

        }
    }

    // MARK: - Helpers
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
            if let mode = modeFromPath(path) {
                let index = Int(path.split(separator: ":")[1])!
                if index >= 0 && videoListTableView.selectedRow >= 0 {
                    return VideoList.instance.getVideoForSource(index, item: videoListTableView.selectedRow, mode: mode)
                }
            } else {
                // all
                return VideoList.instance.videos[videoListTableView.selectedRow]
            }
        }

        return nil
    }

    // Set the time icon
    func setTimeIcon(_ video: AerialVideo?) {
        guard let tvideo = video else {
            timeImageView.image = nil
            return
        }

        switch tvideo.timeOfDay {
        case "sunset":
            timeImageView.image = Aerial.getSymbol("sunset")
        case "sunrise":
            timeImageView.image = Aerial.getSymbol("sunrise")
        case "night":
            timeImageView.image = Aerial.getSymbol("moon.stars")
        default:    // day
            timeImageView.image = Aerial.getSymbol("sun.max")
        }
    }

    // Set the scene icon (landscape...)
    func setSceneIcon(_ video: AerialVideo?) {
        guard let tvideo = video else {
            sceneTypeImageView.image = nil
            return
        }

        switch tvideo.scene {
        case .landscape:
            sceneTypeImageView.image = Aerial.getSymbol("leaf")
        case .city:
            sceneTypeImageView.image = Aerial.getSymbol("tram.fill")
        case .space:
            sceneTypeImageView.image = Aerial.getSymbol("sparkles")
        case .sea:
            sceneTypeImageView.image = Aerial.getSymbol("helm")
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
        } else if path.starts(with: "source:") {
            return .source
        } else if path.starts(with: "favorites") {
            return .favorite
        } else if path.starts(with: "hidden") {
            return .hidden
        } else {
            return nil
        }
    }

    // MARK: - Buttons
    @IBAction func downloadButton(_ sender: Any) {
        downloadButton.isHidden = true
        if let video = getSelectedVideo() {
            let videoManager = VideoManager.sharedInstance
            Cache.ensureDownload {
                videoManager.queueDownload(video)
            }
        }
    }

    @IBAction func hideButtonClick(_ sender: Any) {
        if let video = getSelectedVideo() {
            PrefsVideos.hidden.append(video.id)
            hideButton.isHidden = true
            showButton.isHidden = false
            updateInPlace()
        }
    }

    @IBAction func showButtonClick(_ sender: Any) {
        if let video = getSelectedVideo() {
            if let index = PrefsVideos.hidden.firstIndex(of: video.id) {
                PrefsVideos.hidden.remove(at: index)
                hideButton.isHidden = false
                showButton.isHidden = true
                updateInPlace()
            } else {
                errorLog("Can't find video when unhiding, please report")
            }
        }
    }

    func updateInPlace() {
        let row = videoListTableView.selectedRow

        if videoListTableView != nil {
            videoListTableView.reloadData()
            videoListTableView.selectRowIndexes([row], byExtendingSelection: false)
        }

        updateRotationMenu()
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
            video = VideoList.instance.videos.sorted { $0.secondaryName < $1.secondaryName }[row]
        }

        if let cell = tableView.makeView(withIdentifier:
            NSUserInterfaceItemIdentifier(rawValue: "ImageCellID"), owner: nil) as? VideoCellView {
            cell.video = video
            cell.label.stringValue = video.secondaryName
            cell.checkButton.state = PrefsVideos.favorites.contains(video.id) ? .on : .off

            if PrefsVideos.hidden.contains(video.id) {
                cell.checkButton.isHidden = true
            } else {
                cell.checkButton.isHidden = false
            }

            if PrefsCache.enableManagement {
                cell.downloadButton.isHidden = true
            } else {
                cell.downloadButton.isHidden = video.isAvailableOffline
            }

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
