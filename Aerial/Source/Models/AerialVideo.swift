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

let SpaceVideos = [ "A837FA8C-C643-4705-AE92-074EFDD067F7",
                    "2F72BC1E-3D76-456C-81EB-842EBA488C27",
                    "A2BE2E4A-AD4B-428A-9C41-BDAE1E78E816",
                    "D5CFB2FF-5F8C-4637-816B-3E42FC1229B8",
                    "4F881F8B-A7D9-4FDB-A917-17BF6AC5A589",
                    "6A74D52E-2447-4B84-AE45-0DEF2836C3CC",
                    "F439B0A7-D18C-4B14-9681-6520E6A74FE9",
                    "62A926BE-AA0B-4A34-9653-78C4F130543F",
                    "6C3D54AE-0871-498A-81D0-56ED24E5FE9F",
                    "78911B7E-3C69-47AD-B635-9C2486F6301D",
                    "D60B4DDA-69EB-4841-9690-E8BAE7BC4F80",
                    "7719B48A-2005-4011-9280-2F64EEC6FD91",
                    "63C042F0-90EF-4A95-B7CC-CC9A64BF8421"]

let TimeInformation = [ "A837FA8C-C643-4705-AE92-074EFDD067F7":"night",     // Africa Night
                        "2F72BC1E-3D76-456C-81EB-842EBA488C27":"day",       // Africa and the Middle East
                        "A2BE2E4A-AD4B-428A-9C41-BDAE1E78E816":"night",     // California to Vegas
                        "D5CFB2FF-5F8C-4637-816B-3E42FC1229B8":"day",       // Carribean
                        "4F881F8B-A7D9-4FDB-A917-17BF6AC5A589":"day",       // Carribean day
                        "6A74D52E-2447-4B84-AE45-0DEF2836C3CC":"night",     // China
                        "F439B0A7-D18C-4B14-9681-6520E6A74FE9":"night",     // Iran and Afghanistan
                        "62A926BE-AA0B-4A34-9653-78C4F130543F":"night",     // Ireland to Asia
                        "6C3D54AE-0871-498A-81D0-56ED24E5FE9F":"night",     // Korean and Japan Night
                        "78911B7E-3C69-47AD-B635-9C2486F6301D":"day",       // New Zealand (sunrise...)
                        "D60B4DDA-69EB-4841-9690-E8BAE7BC4F80":"day",       // Sahara and Italy
                        "7719B48A-2005-4011-9280-2F64EEC6FD91":"day",       // Southern California to Baja
                        "63C042F0-90EF-4A95-B7CC-CC9A64BF8421":"day",       // Western Africa to the Alps (sunset...)
                        "BAF76353-3475-4855-B7E1-CE96CC9BC3A7":"night",     // Dubai
                        "30313BC1-BF20-45EB-A7B1-5A6FFDBD2488":"night",     // Hong Kong
                        "89B1643B-06DD-4DEC-B1B0-774493B0F7B7":"night",     // Los Angeles
                        "EC67726A-8212-4C5E-83CF-8412932740D2":"night",     // Los Angeles
                        "A284F0BF-E690-4C13-92E2-4672D93E8DE5":"night"
                        ]

class AerialVideo: CustomStringConvertible, Equatable {
    static func ==(lhs: AerialVideo, rhs: AerialVideo) -> Bool {
        return lhs.id == rhs.id && lhs.url1080pHEVC == rhs.url1080pHEVC
    }
    
    let id: String
    let name: String
    let secondaryName: String
    let type: String
    let timeOfDay: String
    var url1080pH264: String
    let url1080pHEVC: String
    let url4KHEVC: String
    var sources: [Manifests]
    let poi: [String: String]
    var duration: Double
    
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
                    //debugLog("4K NOT AVAILABLE, retunring 1080P HEVC as closest available")
                    return URL(string: self.url1080pHEVC)!
                }
                else {
                    //debugLog("4K NOT AVAILABLE, retunring 1080P H264 as closest available")
                    return URL(string: self.url1080pH264)!
                }
            }
            else if (preferences.videoFormat == Preferences.VideoFormat.v1080pHEVC.rawValue)
            {
                if (url1080pHEVC != "") {
                    return URL(string: self.url1080pHEVC)!
                }
                else if (url1080pH264 != "") {
                    //debugLog("1080pHEVC NOT AVAILABLE, retunring 1080P H264 as closest available")
                    return URL(string: self.url1080pH264)!
                }
                else {
                    //debugLog("1080pHEVC NOT AVAILABLE, retunring 4K HEVC as closest available")
                    return URL(string: self.url4KHEVC)!
                }
            }
            else
            {
                if (url1080pH264 != "") {
                    return URL(string: self.url1080pH264)!
                }
                else if (url1080pHEVC != "") {
                    //debugLog("1080pH264 NOT AVAILABLE, retunring 1080P HEVC as closest available")
                    return URL(string: self.url1080pHEVC)!
                }
                else {
                    //debugLog("1080pHEVC NOT AVAILABLE, retunring 4K HEVC as closest available")
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
    
    init(id: String, name: String, secondaryName: String, type: String,
         timeOfDay: String, url1080pH264: String, url1080pHEVC: String, url4KHEVC: String, manifest: Manifests, poi: [String: String]) {
        self.id = id

        // We override names for known space videos
        if (SpaceVideos.contains(id)) {
            self.name = "Space"
            if (secondaryName != "") {
                self.secondaryName = secondaryName
            } else {
                self.secondaryName = name
            }
        } else {
            self.name = name
            self.secondaryName = secondaryName      // We may have a secondary name from our merges
        }
        
        self.type = type

        // We override timeOfDay based on our own list
        if let val = TimeInformation[id] {
            self.timeOfDay = val
        }
        else {
            self.timeOfDay = timeOfDay
        }

        self.url1080pH264 = url1080pH264
        self.url1080pHEVC = url1080pHEVC
        self.url4KHEVC = url4KHEVC
        self.sources = [manifest]
        self.poi = poi
        
        self.duration = 0
        updateDuration()
    }

    func updateDuration() {
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
