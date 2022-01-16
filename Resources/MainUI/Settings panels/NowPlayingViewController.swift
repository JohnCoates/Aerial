//
//  NowPlayingViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/11/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Cocoa

class NowPlayingViewController: NSViewController {

    // Top toolbar
    @IBOutlet var playIconImageView: NSImageView!

    @IBOutlet var currentlySelectedPopupButton: NSPopUpButton!

    @IBOutlet var selectAllButton: NSButton!
    @IBOutlet var deselectAllButton: NSButton!

    // Our main collection
    @IBOutlet var playingCollectionView: NSCollectionView!

    // Status stuff
    @IBOutlet var statusDriveImageView: NSImageView!
    @IBOutlet var statusDriveLabel: NSTextField!

    @IBOutlet var statusTimeImageView: NSImageView!
    @IBOutlet var statusTimeLabel: NSTextField!

    var sources: [String] = []
    var currentSource: VideoList.FilterMode = .location

    override func viewDidLoad() {
        super.viewDidLoad()

        // This is the filter we use to populate the view
        updateCurrentSource()

        // Reflect on UI
        currentlySelectedPopupButton.selectItem(at: PrefsVideos.intNewShouldPlay)

        if PrefsVideos.newShouldPlayString.isEmpty {
            print("empty, selecting all")
            selectAllClick(selectAllButton)
        }

        // Now update the UI
        reloadSources()
        updateStatusBar()

        // Setup collection
        playingCollectionView.dataSource = self
        playingCollectionView.wantsLayer = true

        VideoList.instance.addCallback {
            debugLog("NPrs")
            self.reloadSources()
            self.updateStatusBar()
        }
    }

    // This is our filter on this panel
    func updateCurrentSource() {
        switch PrefsVideos.newShouldPlay {
        case .location:
            currentSource = .location
        case .favorites:
            currentSource = .favorite
        case .time:
            currentSource = .time
        case .scene:
            currentSource = .scene
        case .source:
            currentSource = .source
        }
    }

    @IBAction func currentlySelectedChange(_ sender: NSPopUpButton) {
        PrefsVideos.newShouldPlay = NewShouldPlay(rawValue: sender.indexOfSelectedItem)!

        updateCurrentSource()
        reloadSources()
        updateStatusBar()
    }

    @IBAction func selectAllClick(_ sender: Any) {
        let subSources = VideoList.instance.getSources(mode: currentSource)

        let mode = String(describing: currentSource) + ":"

        for source in subSources {
            let path = mode + source
            print(path)
            if !PrefsVideos.newShouldPlayString.contains(path) {
                PrefsVideos.newShouldPlayString.append(path)
            }
        }
        playingCollectionView.reloadData()
    }

    @IBAction func deselectAllClick(_ sender: Any) {
        let subSources = VideoList.instance.getSources(mode: currentSource)

        let mode = String(describing: currentSource) + ":"

        for source in subSources {
            let path = mode + source
            if PrefsVideos.newShouldPlayString.contains(path) {
                PrefsVideos.newShouldPlayString.remove(at: PrefsVideos.newShouldPlayString.firstIndex(of: path)!)
            }
        }
        playingCollectionView.reloadData()
    }

    func reloadSources() {
        sources = VideoList.instance.getSources(mode: currentSource)
        playingCollectionView.reloadData()
    }

    func updateStatusBar() {
        if PrefsCache.enableManagement {
            // We are in managed mode
            if Cache.isFull() {
                statusDriveImageView.image = Aerial.getAccentedSymbol("externaldrive.badge.xmark")
                statusDriveLabel.stringValue = Cache.sizeString() + " (your cache is full)"
            } else {
                statusDriveImageView.image = Aerial.getAccentedSymbol("externaldrive.badge.checkmark")
                statusDriveLabel.stringValue = String(Cache.size().rounded(toPlaces: 1)) + " / " + String(PrefsCache.cacheLimit.rounded(toPlaces: 1)) + " GB"
            }
        } else {
            // Manual mode
            statusDriveImageView.image = Aerial.getAccentedSymbol("internaldrive")
            statusDriveLabel.stringValue = Cache.sizeString()
        }

        // May get removed
        statusTimeImageView.isHidden = true
        statusTimeLabel.isHidden = true
    }

}

extension NowPlayingViewController: NSCollectionViewDataSource {

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return sources.count
    }

    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        let item = playingCollectionView.makeItem(withIdentifier:
                        NSUserInterfaceItemIdentifier(rawValue: "PlayingCollectionViewItem"), for: indexPath)

        guard let playingCollectionViewItem = item as? PlayingCollectionViewItem else {return item}

        let path = String(describing: currentSource) + ":" + sources[indexPath[1]]
        playingCollectionViewItem.hiddenPath.stringValue = path

        if PrefsVideos.newShouldPlayString.contains(path) {
            playingCollectionViewItem.checkImageButton?.state = .on
            playingCollectionViewItem.checkImageButton?.image = Aerial.getSymbol("checkmark.circle.fill")
        } else {
            playingCollectionViewItem.checkImageButton?.state = .off
            playingCollectionViewItem.checkImageButton?.image = Aerial.getSymbol("circle")
        }

        playingCollectionViewItem.textField?.stringValue = sources[indexPath[1]]

        let count = VideoList.instance.getVideosCountForSource(indexPath[1], mode: currentSource)

        if count == 1 {
            playingCollectionViewItem.extraTextField.stringValue =  "\(count) video"
        } else {
            playingCollectionViewItem.extraTextField.stringValue =  "\(count) videos"
        }

        let video = VideoList.instance.getVideosForSource(indexPath[1], mode: currentSource).first

        if let video = video {
            Thumbnails.get(forVideo: video) { [weak self] (img) in
                guard let _ = self else { return }
                if let img = img {
                    playingCollectionViewItem.mainImageButton?.image = img
                } else {
                    playingCollectionViewItem.mainImageButton?.image = nil
                }
            }
        }

        return item
    }

}
