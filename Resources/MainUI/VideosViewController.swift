//
//  VideosViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 15/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import AVKit

// swiftlint:disable:next type_body_length
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

    @IBOutlet var vibrancyLabel: NSTextField!
    @IBOutlet var vibrancySlider: NSSlider!

    @IBOutlet var playbackSpeedLabel: NSTextField!

    @IBOutlet var playbackSpeedSlider: NSSlider!

    var path: String?
    var mode: String?

    var currentVibrancy: Double = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        rotationView.isHidden = false

        // Our video list
        videoListTableView.delegate = self
        videoListTableView.dataSource = self

        // Our large player view
        heroPlayerView.player = AVPlayer()
        heroPlayerView.controlsStyle = .none
        if #available(OSX 10.10, *) {
            heroPlayerView.videoGravity = .resizeAspectFill
        }

        downloadButton.setIcons("arrow.down.circle")
        hideButton.setIcons("eye.slash")
        showButton.setIcons("eye")
        setShadows()
        fixIcons()

        updateVideoView()
        updateRotationMenu()

        // This needs cleanup someday
        rotationSecondaryPopup.isHidden = true
        rotationCacheNow.isHidden = true
    }

    @objc func playerItemDidReachEnd(_ aNotification: Notification) {
        debugLog("\(self.description) played did reach end")
        debugLog("\(self.description) notification: \(aNotification)")

        debugLog("Rewinding video!")
        if let playerItem = aNotification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
            heroPlayerView.player?.play()
        }
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
        vibrancyLabel.shadow = shadow
        vibrancySlider.shadow = shadow
        playbackSpeedLabel.shadow = shadow
        playbackSpeedSlider.shadow = shadow

        timeImageView.shadow = imgShadow
        sceneTypeImageView.shadow = imgShadow
        isCachedImageView.shadow = imgShadow
    }

    /// Since we can't directly use SF Symbols, we use our own icon wrappers
    func fixIcons() {
        // rotationPopup.item(at: 0)?.setIcons("film")
        // rotationPopup.item(at: 1)?.setIcons("star")
        // rotationPopup.item(at: 2)?.setIcons("mappin.and.ellipse")
        // rotationPopup.item(at: 3)?.setIcons("clock")
        // rotationPopup.item(at: 4)?.setIcons("tram.fill")
        // rotationPopup.item(at: 5)?.setIcons("antenna.radiowaves.left.and.right")
        rotationImage.image = Aerial.getAccentedSymbol("film")
        rotationCacheNow.setIcons("arrow.down.circle")
    }

    func switchMainTo(filter: VideoList.FilterMode) {
        switch filter {
        case .location:
            rotationPopup.selectItem(at: 2)
        case .time:
            rotationPopup.selectItem(at: 3)
        case .scene:
            rotationPopup.selectItem(at: 4)
        case .source:
            rotationPopup.selectItem(at: 5)
        case .favorite:
            rotationPopup.selectItem(at: 1)
        case .hidden:
            rotationPopup.selectItem(at: 6)
        default:
            rotationPopup.selectItem(at: 1)
        }
    }
    /// Reload with a named path
    /// This is used by the
    func reloadPath(path: String) {
        if let foundMode = VideoList.instance.modeFromPath(path) {
            switchMainTo(filter: foundMode)

            rotationPopupChange(rotationPopup)

            let subpath = path.split(separator: ":")[1]

            print(subpath)

            // Very unswift
            var index = 0
            for item in VideoList.instance.getSources(mode: foundMode) {
                if subpath == item {
                    print(index)
                    rotationSecondaryPopup.selectItem(at: index)
                    rotationSecondaryPopupChange(rotationSecondaryPopup)
                }
                index += 1
            }
        }
    }

    /// Reload the video view for a given path
    func reloadFor(path: String) {
        self.path = path
        print("rf " + self.path!)

        updateRotationMenu()
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
        if let mode = VideoList.instance.modeFromPath(path) {
            let index = Int(path.split(separator: ":")[1])!
            videos = VideoList.instance.getVideosForSource(index, mode: mode)
        } else {
            // all
            videos = VideoList.instance.videos.filter({ !PrefsVideos.hidden.contains($0.id) }).sorted { $0.secondaryName < $1.secondaryName }
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

        switch sender.indexOfSelectedItem {
        case 0:
            mode = "all"
        case 1:
            mode = "favorites"
        case 2:
            mode = "location"
        case 3:
            mode = "time"
        case 4:
            mode = "scene"
        case 5:
            mode = "source"
        case 6:
            mode = "hidden"
        default:
            mode = "all"
        }

        print("rpc " + mode!)

        // Cascade to a secondary popup for the various filters
        if mode == "all" || mode == "favorites" || mode == "hidden" {
            rotationSecondaryPopup.isHidden = true
            path = mode! + ":0"
            reloadFor(path: path!)
        } else {
            rotationSecondaryPopup.isHidden = false
            updateRotationSecondaryMenu()
        }

        // print(path!)
    }

    /// Secondary popup change event
    @IBAction func rotationSecondaryPopupChange(_ sender: NSPopUpButton) {
        // PrefsVideos.shouldPlayString = sender.selectedItem!.title
        path = mode! + ":\(sender.indexOfSelectedItem)"
        print(path!)
        reloadFor(path: path!)
    }

    func updateRotationMenu() {
        // rotationPopup.selectItem(at: PrefsVideos.intShouldPlay)

        // Cascade to a secondary popup for the various filters
       /* if PrefsVideos.shouldPlay == .everything || PrefsVideos.shouldPlay == .favorites {
            rotationSecondaryPopup.isHidden = true
        } else {
            rotationSecondaryPopup.isHidden = false
            // updateRotationSecondaryMenu()
        }*/
/*
        if VideoList.instance.currentRotation().filter({ !$0.isAvailableOffline }).isEmpty {
            rotationCacheNow.isHidden = true
        } else {
            rotationCacheNow.isHidden = false
        }*/
    }

    func updateRotationSecondaryMenu() {
        var filter: VideoList.FilterMode

        filter = VideoList.instance.modeFromPath(mode!) ?? .location
        print("ursm : \(mode) \(filter)")
        rotationSecondaryPopup.removeAllItems()

        // Very unswift
        var index = 0
        for item in VideoList.instance.getSources(mode: filter) {
            rotationSecondaryPopup.addItem(withTitle: item)

            index += 1
        }

        // We select the first one
        if rotationSecondaryPopup.numberOfItems > 0 {
            // PrefsVideos.shouldPlayString = rotationSecondaryPopup.itemTitle(at: 0)
            rotationSecondaryPopup.selectItem(at: 0)
            path = mode! + ":0"
            print(path!)
            reloadFor(path: path!)
        }
    }

    // MARK: - Video view
    func updateVideoView() {
        if let video = getSelectedVideo() {
            debugLog("\"\(video.id)\": \"sunrise\", // \(video.name) - \(video.secondaryName)")
            debugLog("\"\(video.id)\": \"sunset\", // \(video.name) - \(video.secondaryName)")
            debugLog("\"\(video.id)\": \"night\", // \(video.name) - \(video.secondaryName)")

            titleLabel.isHidden = false
            locationLabel.isHidden = false
            sourceLabel.isHidden = false
            formatLabel.isHidden = false

            titleLabel.stringValue = video.secondaryName
            locationLabel.stringValue = video.name
            sourceLabel.stringValue = video.source.name
            formatLabel.stringValue = video.getCurrentFormat()

            if PrefsVideos.hidden.contains(video.id) {
                hideButton.isHidden = true
                showButton.isHidden = false
            } else {
                hideButton.isHidden = false
                showButton.isHidden = true
            }

            if video.isAvailableOffline {
                showVideo(video)

            } else {
                showImage(video)
            }

            setTimeIcon(video)
            setSceneIcon(video)
        } else {
            hideEverything()
        }
    }

    func stopVideo() {
        if let player = heroPlayerView.player {
            debugLog("Stopping player")
            player.pause()
        }
    }

    func updateDurationLabel(_ video: AerialVideo) {
        let speed = PlaybackSpeed.forVideo(video.id)
        if speed == 1 {
            durationLabel.stringValue = "Duration: " + timeString(video.duration)
        } else if speed > 1 {
            durationLabel.stringValue = "Duration(sped up): " + timeString(video.duration/Double(speed))
        } else {
            durationLabel.stringValue = "Duration(slowed down): " + timeString(video.duration/Double(speed))
        }
    }

    /// Show video player
    func showVideo(_ video: AerialVideo) {
        heroPlayerView.isHidden = false
        heroImageView.isHidden = true
        isCachedImageView.isHidden = false

        durationLabel.isHidden = false

        updateDurationLabel(video)

        downloadButton.isHidden = true

        if let player = heroPlayerView.player {
            let path = VideoList.instance.localPathFor(video: video)
            debugLog("heropath : \(path)")

            let asset = AVAsset(url: URL(fileURLWithPath: path))
            let localitem = AVPlayerItem(asset: asset)

            // Set slider for the playback speed
            playbackSpeedSlider.doubleValue = Double(PlaybackSpeed.forVideo(video.id))

            // Vibrancy filter requires 10.14, and doesn't work on HDR content
            if #available(OSX 10.14, *), !video.isHDR() {
                if PrefsVideos.allowPerVideoVibrance {
                    vibrancyLabel.isHidden = false
                    vibrancySlider.isHidden = false
                    if let value = PrefsVideos.vibrance[video.id] {
                        vibrancySlider.doubleValue = value
                    } else {
                        vibrancySlider.doubleValue = 0.0
                    }
                    if vibrancySlider.doubleValue == 0 {
                        currentVibrancy = PrefsVideos.globalVibrance
                    } else {
                        currentVibrancy = vibrancySlider.doubleValue
                    }
                } else {
                    vibrancyLabel.isHidden = true
                    vibrancySlider.isHidden = true
                }

                let filter = CIFilter(name: "CIVibrance")!
                localitem.videoComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                    let source = request.sourceImage.clampedToExtent()
                    filter.setValue(source, forKey: kCIInputImageKey)
                    filter.setValue(self.currentVibrancy, forKey: kCIInputAmountKey)
                    let output = filter.outputImage

                    request.finish(with: output!, context: nil)
                })
            } else {
                vibrancyLabel.isHidden = true
                vibrancySlider.isHidden = true
            }

            player.replaceCurrentItem(with: localitem)
            // We may not auto play the video
            if PrefsAdvanced.autoPlayPreviews {
                player.play()

                // Set the playback speed if changed, it defaults to normal speed if not overriden
                player.rate = PlaybackSpeed.forVideo(video.id)
            }

            // Set notification...
            NotificationCenter.default.addObserver(self,
                                           selector: #selector(playerItemDidReachEnd(_:)),
                                           name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                           object: localitem)
        }
    }

    /// Show image
    func showImage(_ video: AerialVideo) {
        heroPlayerView.isHidden = true
        heroImageView.isHidden = false
        isCachedImageView.isHidden = true

        vibrancyLabel.isHidden = true
        vibrancySlider.isHidden = true

        playbackSpeedLabel.isHidden = true
        playbackSpeedSlider.isHidden = true

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

    /// Hide everything !
    func hideEverything() {
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

        vibrancyLabel.isHidden = true
        vibrancySlider.isHidden = true

        // Clear up any playing video
        if let player = heroPlayerView.player {
            player.replaceCurrentItem(with: nil)
            player.pause()
        }

        setTimeIcon(nil)
        setSceneIcon(nil)
    }

    @IBAction func vibrancySliderChange(_ sender: NSSlider) {
        currentVibrancy = vibrancySlider.doubleValue
        PrefsVideos.vibrance[getSelectedVideo()!.id] = vibrancySlider.doubleValue
    }

    @IBAction func playbackSpeedSliderChange(_ sender: NSSlider) {
        PlaybackSpeed.update(video: getSelectedVideo()!.id,
                             value: playbackSpeedSlider.floatValue)

        // Make sure we update the duration
        updateDurationLabel(getSelectedVideo()!)
        if PrefsAdvanced.autoPlayPreviews {
            if heroPlayerView.player?.rate != 0 {
                heroPlayerView.player?.rate = PlaybackSpeed.forVideo(getSelectedVideo()!.id)
            }
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
            if let mode = VideoList.instance.modeFromPath(path) {
                let index = Int(path.split(separator: ":")[1])!
                if index >= 0 && videoListTableView.selectedRow >= 0 {
                    return VideoList.instance.getVideoForSource(index, item: videoListTableView.selectedRow, mode: mode)
                }
            } else {
                // all
                return VideoList.instance.videos
                    .filter({ !PrefsVideos.hidden.contains($0.id) })
                    .sorted { $0.secondaryName < $1.secondaryName }[videoListTableView.selectedRow]
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
        case .nature:
            sceneTypeImageView.image = Aerial.getSymbol("leaf")
        case .beach:
            sceneTypeImageView.image = Aerial.getSymbol("leaf")
        case .countryside:
            sceneTypeImageView.image = Aerial.getSymbol("leaf")
        case .city:
            sceneTypeImageView.image = Aerial.getSymbol("tram.fill")
        case .space:
            sceneTypeImageView.image = Aerial.getSymbol("sparkles")
        case .sea:
            sceneTypeImageView.image = Aerial.getSymbol("helm")
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

        print("nor path : " + path)

        if let mode = VideoList.instance.modeFromPath(path) {
            let index = Int(path.split(separator: ":")[1])!
            return VideoList.instance.getVideosCountForSource(index, mode: mode)
        } else {
            // all
            return VideoList.instance.videos.filter({ !PrefsVideos.hidden.contains($0.id) }).count
        }
    }
}

extension VideosViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let path = path else {
            return nil
        }

        print("tv path : " + path)

        var video: AerialVideo
        if let mode = VideoList.instance.modeFromPath(path) {
            let index = Int(path.split(separator: ":")[1])!
            video = VideoList.instance.getVideoForSource(index, item: row, mode: mode)
        } else {
            // all
            video = VideoList.instance.videos.filter({ !PrefsVideos.hidden.contains($0.id) }).sorted { $0.secondaryName < $1.secondaryName }[row]
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
