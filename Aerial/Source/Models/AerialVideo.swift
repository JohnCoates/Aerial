//
//  AerialVideo.swift
//  Aerial
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import AVFoundation

class AerialVideo: CustomStringConvertible, Equatable {
    static func ==(lhs: AerialVideo, rhs: AerialVideo) -> Bool {
        return lhs.id == rhs.id && lhs.url1080pHEVC == rhs.url1080pHEVC
    }
    
    let id: String
    let name: String
    let type: String
    let timeOfDay: String
    let url1080pH264: URL
    let url1080pHEVC: URL
    let url4KHEVC: URL
    let poi: [String: String]
    let duration: Double
    
    var arrayPosition = 1
    var contentLength = 0
    var contentLengthChecked = false
    
    var isAvailableOffline: Bool {
        get {
            return VideoCache.isAvailableOffline(video: self)
        }
    }
    
    var url : URL {
        get {
            let preferences = Preferences.sharedInstance
            switch preferences.videoFormat {
                case Preferences.VideoFormat.v1080pH264.rawValue:
                    return self.url1080pH264
                case Preferences.VideoFormat.v1080pHEVC.rawValue:
                    return self.url1080pHEVC
                case Preferences.VideoFormat.v4KHEVC.rawValue:
                    return self.url4KHEVC
                default:
                    return url1080pH264
            }
            
        }
    }
    
    init(id: String, name: String, type: String,
         timeOfDay: String, url1080pH264: String, url1080pHEVC: String, url4KHEVC: String, poi: [String: String]) {
        self.id = id
        self.name = name
        self.type = type
        self.timeOfDay = timeOfDay
        self.url1080pH264 = URL(string: url1080pH264)!
        self.url1080pHEVC = URL(string: url1080pHEVC)!
        self.url4KHEVC = URL(string: url4KHEVC)!
        self.poi = poi
        
        // We need to retrieve video duration from the cached files.
        // This is a workaround as currently, the VideoCache infrastructure
        // relies on AVAsset with an external URL all the time, even when
        // working on a cached copy which makes the native duration retrieval fail
        
        // Not the prettiest code !
        let cacheDirectoryPath = VideoCache.cacheDirectory! as NSString
        let fileManager = FileManager.default

        let videoCache1080pH264Path = cacheDirectoryPath.appendingPathComponent(self.url1080pH264.lastPathComponent)
        let videoCache1080pHEVCPath = cacheDirectoryPath.appendingPathComponent(self.url1080pHEVC.lastPathComponent)
        let videoCache4KHEVCPath = cacheDirectoryPath.appendingPathComponent(self.url4KHEVC.lastPathComponent)

        if fileManager.fileExists(atPath: videoCache4KHEVCPath) {
            let asset = AVAsset(url: URL(fileURLWithPath: videoCache4KHEVCPath))
            self.duration = CMTimeGetSeconds(asset.duration)
        }
        else if fileManager.fileExists(atPath: videoCache1080pHEVCPath) {
            let asset = AVAsset(url: URL(fileURLWithPath: videoCache1080pHEVCPath))
            self.duration = CMTimeGetSeconds(asset.duration)
        }
        else if fileManager.fileExists(atPath: videoCache1080pH264Path) {
            let asset = AVAsset(url: URL(fileURLWithPath: videoCache1080pH264Path))
            self.duration = CMTimeGetSeconds(asset.duration)
        }
        else
        {
            self.duration = 0
        }
        //print("Duration \(duration)")
    }

    var description: String {
        return "id=\(id), name=\(name), type=\(type), timeofDay=\(timeOfDay), url1080pH264=\(url1080pH264), url1080pHEVC=\(url1080pHEVC), url4KHEVC=\(url4KHEVC)"
    }
}
