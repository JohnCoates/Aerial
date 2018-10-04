//
//  AerialVideo.swift
//  Aerial
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import AVFoundation

enum Manifests : String {
    case tvOS10 = "tvos10.json", tvOS11 = "tvos11.json", tvOS12 = "entries.json"
}

class AerialVideo: CustomStringConvertible, Equatable {
    static func ==(lhs: AerialVideo, rhs: AerialVideo) -> Bool {
        return lhs.id == rhs.id && lhs.url1080pHEVC == rhs.url1080pHEVC
    }
    
    let id: String
    let name: String
    let type: String
    let timeOfDay: String
    let url1080pH264: String
    let url1080pHEVC: String
    let url4KHEVC: String
    var sources: [Manifests]
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

            // We need to return the closest available format, not pretty
            if (preferences.videoFormat == Preferences.VideoFormat.v4KHEVC.rawValue)
            {
                if (url4KHEVC != "") {
                    return URL(string: self.url4KHEVC)!
                }
                else if (url1080pHEVC != "") {
                    debugLog("4K NOT AVAILABLE, retunring 1080P HEVC as closest available")
                    return URL(string: self.url1080pHEVC)!
                }
                else {
                    debugLog("4K NOT AVAILABLE, retunring 1080P H264 as closest available")
                    return URL(string: self.url1080pH264)!
                }
            }
            else if (preferences.videoFormat == Preferences.VideoFormat.v1080pHEVC.rawValue)
            {
                if (url1080pHEVC != "") {
                    return URL(string: self.url1080pHEVC)!
                }
                else if (url1080pH264 != "") {
                    debugLog("1080pHEVC NOT AVAILABLE, retunring 1080P H264 as closest available")
                    return URL(string: self.url1080pH264)!
                }
                else {
                    debugLog("1080pHEVC NOT AVAILABLE, retunring 4K HEVC as closest available")
                    return URL(string: self.url4KHEVC)!
                }
            }
            else
            {
                if (url1080pH264 != "") {
                    return URL(string: self.url1080pH264)!
                }
                else if (url1080pHEVC != "") {
                    debugLog("1080pH264 NOT AVAILABLE, retunring 1080P HEVC as closest available")
                    return URL(string: self.url1080pHEVC)!
                }
                else {
                    debugLog("1080pHEVC NOT AVAILABLE, retunring 4K HEVC as closest available")
                    return URL(string: self.url4KHEVC)!
                }
            }

            
            /*switch preferences.videoFormat {
                case Preferences.VideoFormat.v1080pH264.rawValue:
                    return URL(string: self.url1080pH264)!
                case Preferences.VideoFormat.v1080pHEVC.rawValue:
                    return URL(string: self.url1080pHEVC)!
                case Preferences.VideoFormat.v4KHEVC.rawValue:
                    return URL(string: self.url4KHEVC)!
                default:
                    return URL(string: url1080pH264)!
            }*/
            
        }
    }
    
    init(id: String, name: String, type: String,
         timeOfDay: String, url1080pH264: String, url1080pHEVC: String, url4KHEVC: String, manifest: Manifests, poi: [String: String]) {
        self.id = id
        self.name = name
        self.type = type
        self.timeOfDay = timeOfDay
        self.url1080pH264 = url1080pH264
        self.url1080pHEVC = url1080pHEVC
        self.url4KHEVC = url4KHEVC
        self.sources = [manifest]
        self.poi = poi
        
        // We need to retrieve video duration from the cached files.
        // This is a workaround as currently, the VideoCache infrastructure
        // relies on AVAsset with an external URL all the time, even when
        // working on a cached copy which makes the native duration retrieval fail
        
        // Not the prettiest code !
        let cacheDirectoryPath = VideoCache.cacheDirectory! as NSString
        let fileManager = FileManager.default

        var videoCache1080pH264Path = "", videoCache1080pHEVCPath = "", videoCache4KHEVCPath = ""
        if (self.url1080pH264 != "")
        {
            videoCache1080pH264Path = cacheDirectoryPath.appendingPathComponent((URL(string: url1080pH264)?.lastPathComponent)!)
        }
        if (self.url1080pHEVC != "")
        {
            videoCache1080pHEVCPath = cacheDirectoryPath.appendingPathComponent((URL(string: url1080pHEVC)?.lastPathComponent)!)
        }
        if (self.url4KHEVC != "")
        {
            videoCache4KHEVCPath = cacheDirectoryPath.appendingPathComponent((URL(string: url4KHEVC)?.lastPathComponent)!)
        }


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
            print("Could not determine duration, video is not cached")
            self.duration = 0
        }
    }

    var description: String {
        return "id=\(id), name=\(name), type=\(type), timeofDay=\(timeOfDay), url1080pH264=\(url1080pH264), url1080pHEVC=\(url1080pHEVC), url4KHEVC=\(url4KHEVC)"
    }
}
