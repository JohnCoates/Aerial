//
//  PlayingCollectionViewItem.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/11/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Cocoa

class PlayingCollectionViewItem: NSCollectionViewItem {
    @IBOutlet var hiddenPath: NSTextField!
    @IBOutlet var extraTextField: NSTextField!
    
    @IBOutlet var browseImageButton: NSButton!
    @IBOutlet var mainImageButton: NSButton!
    @IBOutlet var checkImageButton: NSButton!
    
    @IBOutlet var numberedPath: NSTextField!
    
    var nowPlayingViewController: NowPlayingViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // For images the height coordinates are reversed, obviously...
        let imgShadow: NSShadow = NSShadow()
        imgShadow.shadowBlurRadius = 2
        imgShadow.shadowOffset = NSSize(width: 0, height: 3)
        imgShadow.shadowColor = NSColor.black
        
        browseImageButton.shadow = imgShadow
        checkImageButton.shadow = imgShadow
        // Do view setup here.
    }
    
    
    @IBAction func browseButton(_ sender: Any) {
        Aerial.helper.windowController?.browseTo(hiddenPath.stringValue)
    }
    
    @IBAction func mainImageClick(_ sender: NSButton) {
        let path = hiddenPath.stringValue
        
        if checkImageButton.state == .on {
            checkImageButton.state = .off
            
            checkImageButton.image = Aerial.helper.getSymbol("circle")
            if PrefsVideos.newShouldPlayString.contains(path) {
                PrefsVideos.newShouldPlayString.remove(at: PrefsVideos.newShouldPlayString.firstIndex(of: path)!)
            }
            
        } else {
            checkImageButton.state = .on
            
            checkImageButton.image = Aerial.helper.getSymbol("checkmark.circle.fill")
            if !PrefsVideos.newShouldPlayString.contains(path) {
                PrefsVideos.newShouldPlayString.append(path)
            }
            
        }
    }
    @IBAction func imageButtonClick(_ sender: NSButton) {
        let path = hiddenPath.stringValue
        
        if sender.state == .on {
            sender.image = Aerial.helper.getSymbol("checkmark.circle.fill")
            if !PrefsVideos.newShouldPlayString.contains(path) {
                PrefsVideos.newShouldPlayString.append(path)
            }
        } else {
            sender.image = Aerial.helper.getSymbol("circle")
            if PrefsVideos.newShouldPlayString.contains(path) {
                PrefsVideos.newShouldPlayString.remove(at: PrefsVideos.newShouldPlayString.firstIndex(of: path)!)
            }
        }
    }
    
    /*   @IBAction func imageViewClick(_ sender: Any) {
     print("click")
     let path = hiddenPath.stringValue
     
     
     }*/
    /*
     @IBAction func checkButtonChange(_ sender: NSButton) {
     let path = hiddenPath.stringValue
     
     if sender.state == .on {
     if !PrefsVideos.newShouldPlayString.contains(path) {
     PrefsVideos.newShouldPlayString.append(path)
     }
     } else {
     if PrefsVideos.newShouldPlayString.contains(path) {
     PrefsVideos.newShouldPlayString.remove(at: PrefsVideos.newShouldPlayString.firstIndex(of: path)!)
     }
     }
     }*/
    
    
    @IBAction func hideAllVideosClick(_ sender: NSMenuItem) {
        let videos = VideoList.instance.getVideosForPath(numberedPath.stringValue)
        
        for video in videos.filter({ !PrefsVideos.hidden.contains($0.id) }) {
            PrefsVideos.hidden.append(video.id)
        }

        VideoList.instance.reloadSources()
    }
    
    @IBAction func favoriteAllClick(_ sender: Any) {
        let videos = VideoList.instance.getVideosForPath(numberedPath.stringValue)

        for video in videos.filter({ !PrefsVideos.favorites.contains($0.id) }) {
            PrefsVideos.favorites.append(video.id)
        }
        VideoList.instance.reloadSources()
    }

    @IBAction func cacheVideosClick(_ sender: Any) {
        Cache.ensureDownload {
            let videos = VideoList.instance.getVideosForPath(self.numberedPath.stringValue)

            for video in videos.filter({ !$0.isAvailableOffline }) {
                VideoManager.sharedInstance.queueDownload(video)
            }
        }
        VideoList.instance.reloadSources()
    }
    
    @IBAction func unfavoriteAllClick(_ sender: Any) {
        let videos = VideoList.instance.getVideosForPath(numberedPath.stringValue)

        for video in videos.filter({ PrefsVideos.favorites.contains($0.id) }) {
            PrefsVideos.favorites.remove(at: PrefsVideos.favorites.firstIndex(of: video.id)!)
        }
        VideoList.instance.reloadSources()
    }
    
    @IBAction func resetVibranceClick(_ sender: Any) {
        let videos = VideoList.instance.getVideosForPath(numberedPath.stringValue)

        for video in videos.filter({ PrefsVideos.vibrance.keys.contains($0.id) }) {
            PrefsVideos.vibrance.removeValue(forKey: video.id)
        }
    }
    
}
