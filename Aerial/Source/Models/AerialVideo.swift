//
//  AerialVideo.swift
//  Aerial
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import AVFoundation

enum Manifests: String {
    case tvOS10 = "tvos10.json", tvOS11 = "tvos11.json", tvOS12 = "entries.json"
}

private let spaceVideos = [
    "A837FA8C-C643-4705-AE92-074EFDD067F7",
    "2F72BC1E-3D76-456C-81EB-842EBA488C27",
    "A2BE2E4A-AD4B-428A-9C41-BDAE1E78E816",
    "12318CCB-3F78-43B7-A854-EFDCCE5312CD",
    "D5CFB2FF-5F8C-4637-816B-3E42FC1229B8",
    "4F881F8B-A7D9-4FDB-A917-17BF6AC5A589",
    "6A74D52E-2447-4B84-AE45-0DEF2836C3CC",
    "7825C73A-658F-48EE-B14C-EC56673094AC",
    "E5DB138A-F04E-4619-B896-DE5CB538C534",
    "F439B0A7-D18C-4B14-9681-6520E6A74FE9",
    "62A926BE-AA0B-4A34-9653-78C4F130543F",
    "7C643A39-C0B2-4BA0-8BC2-2EAA47CC580E",
    "6C3D54AE-0871-498A-81D0-56ED24E5FE9F",
    "009BA758-7060-4479-8EE8-FB9B40C8FB97",
    "78911B7E-3C69-47AD-B635-9C2486F6301D",
    "D60B4DDA-69EB-4841-9690-E8BAE7BC4F80",
    "7719B48A-2005-4011-9280-2F64EEC6FD91",
    "63C042F0-90EF-4A95-B7CC-CC9A64BF8421",
    "B1B5DDC5-73C8-4920-8133-BACCE38A08DE",
]

private let timeInformation = [
    "A837FA8C-C643-4705-AE92-074EFDD067F7": "night",    // Africa Night
    "2F72BC1E-3D76-456C-81EB-842EBA488C27": "day",      // Africa and the Middle East
    "A2BE2E4A-AD4B-428A-9C41-BDAE1E78E816": "night",    // California to Vegas (v7)
    "12318CCB-3F78-43B7-A854-EFDCCE5312CD": "night",    // California to Vegas (v8)
    "D5CFB2FF-5F8C-4637-816B-3E42FC1229B8": "day",      // Carribean
    "4F881F8B-A7D9-4FDB-A917-17BF6AC5A589": "day",      // Carribean day
    "6A74D52E-2447-4B84-AE45-0DEF2836C3CC": "night",    // China
    "7825C73A-658F-48EE-B14C-EC56673094AC": "night",    // China (new id)
    "E5DB138A-F04E-4619-B896-DE5CB538C534": "night",    // Italy to Asia
    "F439B0A7-D18C-4B14-9681-6520E6A74FE9": "night",    // Iran and Afghanistan
    "62A926BE-AA0B-4A34-9653-78C4F130543F": "night",    // Ireland to Asia
    "7C643A39-C0B2-4BA0-8BC2-2EAA47CC580E": "night",    // Ireland to Asia
    "6C3D54AE-0871-498A-81D0-56ED24E5FE9F": "night",    // Korean and Japan Night (v17)
    "009BA758-7060-4479-8EE8-FB9B40C8FB97": "night",    // Korean and Japan Night (v18)
    "78911B7E-3C69-47AD-B635-9C2486F6301D": "day",      // New Zealand (sunrise...)
    "D60B4DDA-69EB-4841-9690-E8BAE7BC4F80": "day",      // Sahara and Italy
    "7719B48A-2005-4011-9280-2F64EEC6FD91": "day",      // Southern California to Baja
    "63C042F0-90EF-4A95-B7CC-CC9A64BF8421": "day",      // Western Africa to the Alps (sunset...)
    "BAF76353-3475-4855-B7E1-CE96CC9BC3A7": "night",    // Dubai
    "30313BC1-BF20-45EB-A7B1-5A6FFDBD2488": "night",    // Hong Kong
    "89B1643B-06DD-4DEC-B1B0-774493B0F7B7": "night",    // Los Angeles
    "EC67726A-8212-4C5E-83CF-8412932740D2": "night",    // Los Angeles
    "A284F0BF-E690-4C13-92E2-4672D93E8DE5": "night",    // Los Angeles
    "B1B5DDC5-73C8-4920-8133-BACCE38A08DE": "night",    // New York night
    "9680B8EB-CE2A-4395-AF41-402801F4D6A6": "night",    // Approaching Burj Khalifa
    "EE01F02D-1413-436C-AB05-410F224A5B7B": "night",    // Ilulissat Icefjord
    "E99FA658-A59A-4A2D-9F3B-58E7BDC71A9A": "night",    // Hong Kong Victoria Harbour
    "3E94AE98-EAF2-4B09-96E3-452F46BC114E": "night",    // Bay Bridge
    "29BDF297-EB43-403A-8719-A78DA11A2948": "night",    // Fisherman's Wharf
    "82BD33C9-B6D2-47E7-9C42-AA3B7758921A": "night",    // Pu'u O 'Umi Night
    "3D729CFC-9000-48D3-A052-C5BD5B7A6842": "night",    // Kohala Coastline
    "F604AF56-EA77-4960-AEF7-82533CC1A8B3": "night",    // River Thames near sunset
    "7F4C26C2-67C2-4C3A-8F07-8A7BF6148C97": "night",    // River Thames at dusk
    "F5804DD6-5963-40DA-9FA0-39C0C6E6DEF9": "night",    // Downtown (LA)
    "640DFB00-FBB9-45DA-9444-9F663859F4BC": "night",    // Lower Manhattan
    "44166C39-8566-4ECA-BD16-43159429B52F": "night",    // Seventh Avenue
]

final class AerialVideo: CustomStringConvertible, Equatable {
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
    let communityPoi: [String: String]
    var duration: Double

    var arrayPosition = 1
    var contentLength = 0
    var contentLengthChecked = false

    var isAvailableOffline: Bool {
        return VideoCache.isAvailableOffline(video: self)
    }

    var url: URL {
        let preferences = Preferences.sharedInstance
        let timeManagement = TimeManagement.sharedInstance
        // We may override on battery
        if preferences.overrideOnBattery && timeManagement.isOnBattery() {
            return getClosestAvailable(wanted: preferences.alternateVideoFormat!-1) // Slightly dirty
        }

        return getClosestAvailable(wanted: preferences.videoFormat!)
    }

    func getClosestAvailable(wanted: Int) -> URL {
        if wanted == Preferences.VideoFormat.v4KHEVC.rawValue {
            if url4KHEVC != "" {
                return URL(string: self.url4KHEVC)!
            } else if url1080pHEVC != "" {
                return URL(string: self.url1080pHEVC)!
            } else {
                return URL(string: self.url1080pH264)!
            }
        } else if wanted == Preferences.VideoFormat.v1080pHEVC.rawValue {
            if url1080pHEVC != "" {
                return URL(string: self.url1080pHEVC)!
            } else if url1080pH264 != "" {
                return URL(string: self.url1080pH264)!
            } else {
                return URL(string: self.url4KHEVC)!
            }
        } else {
            if url1080pH264 != "" {
                return URL(string: self.url1080pH264)!
            } else if url1080pHEVC != "" {
                // With the latest versions, we should always have a H.264 fallback so this is just for future proofing
                return URL(string: self.url1080pHEVC)!
            } else {
                return URL(string: self.url4KHEVC)!
            }
        }
    }

    init(id: String,
         name: String,
         secondaryName: String,
         type: String,
         timeOfDay: String,
         url1080pH264: String,
         url1080pHEVC: String,
         url4KHEVC: String,
         manifest: Manifests,
         poi: [String: String],
         communityPoi: [String: String]
    ) {
        self.id = id

        // We override names for known space videos
        if spaceVideos.contains(id) {
            self.name = "Space"
            if secondaryName != "" {
                self.secondaryName = secondaryName
            } else {
                self.secondaryName = name
            }
        } else {
            // We align to the new jsons...
            if name == "New York City" {
                self.name = "New York"
            } else {
                self.name = name
            }
            self.secondaryName = secondaryName      // We may have a secondary name from our merges too now !
        }

        self.type = type

        // We override timeOfDay based on our own list
        if let val = timeInformation[id] {
            self.timeOfDay = val
        } else {
            self.timeOfDay = timeOfDay
        }

        self.url1080pH264 = url1080pH264
        self.url1080pHEVC = url1080pHEVC
        self.url4KHEVC = url4KHEVC
        self.sources = [manifest]
        self.poi = poi
        self.communityPoi = communityPoi
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
        if self.url1080pH264 != "" {
            videoCache1080pH264Path = cacheDirectoryPath.appendingPathComponent((URL(string: url1080pH264)?.lastPathComponent)!)
        }
        if self.url1080pHEVC != "" {
            videoCache1080pHEVCPath = cacheDirectoryPath.appendingPathComponent((URL(string: url1080pHEVC)?.lastPathComponent)!)
        }
        if self.url4KHEVC != "" {
            videoCache4KHEVCPath = cacheDirectoryPath.appendingPathComponent((URL(string: url4KHEVC)?.lastPathComponent)!)
        }

        if fileManager.fileExists(atPath: videoCache4KHEVCPath) {
            let asset = AVAsset(url: URL(fileURLWithPath: videoCache4KHEVCPath))
            self.duration = CMTimeGetSeconds(asset.duration)
        } else if fileManager.fileExists(atPath: videoCache1080pHEVCPath) {
            let asset = AVAsset(url: URL(fileURLWithPath: videoCache1080pHEVCPath))
            self.duration = CMTimeGetSeconds(asset.duration)
        } else if fileManager.fileExists(atPath: videoCache1080pH264Path) {
            let asset = AVAsset(url: URL(fileURLWithPath: videoCache1080pH264Path))
            self.duration = CMTimeGetSeconds(asset.duration)
        } else {
            debugLog("Could not determine duration, video is not cached in any format")
            self.duration = 0
        }
    }

    var description: String {
        return """
        id=\(id),
        name=\(name),
        type=\(type),
        timeofDay=\(timeOfDay),
        url1080pH264=\(url1080pH264),
        url1080pHEVC=\(url1080pHEVC),
        url4KHEVC=\(url4KHEVC)"
        """
    }
}
