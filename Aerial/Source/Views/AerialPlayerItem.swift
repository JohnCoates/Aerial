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
        let videoURL = video.url
        let asset = CachedOrCachingAsset(videoURL)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        self.video = video
    }
}
