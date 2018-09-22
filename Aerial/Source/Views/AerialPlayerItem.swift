//
//  AerialPlayerItem.swift
//  Aerial
//
//  Created by Ethan Setnik on 11/22/17.
//  Copyright © 2017 John Coates. All rights reserved.
//
import AVFoundation
import AVKit

class AerialPlayerItem: AVPlayerItem {
    var video: AerialVideo?
    
    init(video: AerialVideo) {
        let preferences = Preferences.sharedInstance
        let videoURL = preferences.use4KVideos ? video.url4K : video.url1080p
        //let videoURL = video.url
        let asset = CachedOrCachingAsset(videoURL)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        self.video = video
    }
}
