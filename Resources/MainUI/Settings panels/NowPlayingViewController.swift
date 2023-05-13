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
    @IBOutlet var playingCollectionView: NowPlayingCollectionView!

    // Status stuff
    @IBOutlet var statusDriveImageView: NSImageView!
    @IBOutlet var statusDriveLabel: NSTextField!

    @IBOutlet var statusTimeImageView: NSImageView!
    @IBOutlet var statusTimeLabel: NSTextField!

    @IBOutlet weak var statusHiddenVideoButton: NSButton!

    @IBOutlet weak var statusFavoriteButton: NSButton!
    
    var sources: [String] = []
    var currentSource: VideoList.FilterMode = .location

    override func viewDidLoad() {
        super.viewDidLoad()

        // This is the filter we use to populate the view
        updateCurrentSource()

        // Reflect on UI
        currentlySelectedPopupButton.selectItem(at: PrefsVideos.intNewShouldPlay)



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
            
            if self.isSelectionEmpty() {
                self.selectAllClick(self.selectAllButton!)
            }
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
        
        if self.isSelectionEmpty() {
            self.selectAllClick(self.selectAllButton!)
        }
    }

    func isSelectionEmpty() -> Bool {
        let subSources = VideoList.instance.getSources(mode: currentSource)

        let mode = String(describing: currentSource) + ":"

        for source in subSources {
            let path = mode + source
            if PrefsVideos.newShouldPlayString.contains(path) {
                return false
            }
        }
        
        return true
    }
    
    
    @IBAction func selectAllClick(_ sender: Any) {
        let subSources = VideoList.instance.getSources(mode: currentSource)

        let mode = String(describing: currentSource) + ":"

        for source in subSources {
            let path = mode + source

            if !PrefsVideos.newShouldPlayString.contains(path) {
                PrefsVideos.newShouldPlayString.append(path)
            }
        }
        playingCollectionView.reloadData()
    }

    @IBAction func statusHiddenVideoButtonClick(_ sender: Any) {
        Aerial.helper.windowController?.browseTo("hidden:0")
    }
   
    @IBAction func statusFavoritesButtonClick(_ sender: Any) {
        Aerial.helper.windowController?.browseTo("favorites:0")
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

    public func reloadSources() {
        sources = VideoList.instance.getSources(mode: currentSource)
        playingCollectionView.reloadData()
    }

    func updateStatusBar() {
        if PrefsCache.enableManagement {
            // We are in managed mode
            if PrefsCache.cacheLimit >= 101 {
                statusDriveImageView.image = Aerial.helper.getAccentedSymbol("externaldrive.badge.checkmark")
                statusDriveLabel.stringValue = String(Cache.size().rounded(toPlaces: 1)) + " GB"
            } else if Cache.isFull() {
                statusDriveImageView.image = Aerial.helper.getAccentedSymbol("externaldrive.badge.xmark")
                statusDriveLabel.stringValue = Cache.sizeString() + " (your cache is full)"
            } else {
                statusDriveImageView.image = Aerial.helper.getAccentedSymbol("externaldrive.badge.checkmark")
                statusDriveLabel.stringValue = String(Cache.size().rounded(toPlaces: 1)) + " / " + String(PrefsCache.cacheLimit.rounded(toPlaces: 1)) + " GB"
            }
        } else {
            // Manual mode
            statusDriveImageView.image = Aerial.helper.getAccentedSymbol("internaldrive")
            statusDriveLabel.stringValue = Cache.sizeString()
        }

        // May get removed
        statusTimeImageView.isHidden = true
        statusTimeLabel.isHidden = true
        
        if PrefsVideos.hidden.isEmpty {
            statusHiddenVideoButton.title = "No hidden videos"
        } else if PrefsVideos.hidden.count == 1 {
            statusHiddenVideoButton.title = String(PrefsVideos.hidden.count) + " hidden video"
        } else {
            statusHiddenVideoButton.title = String(PrefsVideos.hidden.count) + " hidden videos"
        }
        
        if (PrefsVideos.favorites.isEmpty) {
            statusFavoriteButton.title = "No favorites"
        } else if PrefsVideos.favorites.count == 1 {
            statusFavoriteButton.title = String(PrefsVideos.favorites.count) + " favorite"
        } else {
            statusFavoriteButton.title = String(PrefsVideos.favorites.count) + " favorites"
        }
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

        playingCollectionViewItem.nowPlayingViewController = self
        
        let path = String(describing: currentSource) + ":" + sources[indexPath[1]]
        playingCollectionViewItem.hiddenPath.stringValue = path

        playingCollectionViewItem.numberedPath.stringValue = String(describing: currentSource) + ":" + String(indexPath[1])
        
        if PrefsVideos.newShouldPlayString.contains(path) {
            playingCollectionViewItem.checkImageButton?.state = .on
            playingCollectionViewItem.checkImageButton?.image = Aerial.helper.getSymbol("checkmark.circle.fill")
        } else {
            playingCollectionViewItem.checkImageButton?.state = .off
            playingCollectionViewItem.checkImageButton?.image = Aerial.helper.getSymbol("circle")
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
