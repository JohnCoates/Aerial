//
//  AerialVideo.swift
//  Aerial
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation

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
         timeOfDay: String, url1080pH264: String, url1080pHEVC: String, url4KHEVC: String) {
        self.id = id
        self.name = name
        self.type = type
        self.timeOfDay = timeOfDay
        self.url1080pH264 = URL(string: url1080pH264)!
        self.url1080pHEVC = URL(string: url1080pHEVC)!
        self.url4KHEVC = URL(string: url4KHEVC)!
    }
    
    var description: String {
        return "id=\(id), name=\(name), type=\(type), timeofDay=\(timeOfDay), url1080pH264=\(url1080pH264), url1080pHEVC=\(url1080pHEVC), url4KHEVC=\(url4KHEVC)"
    }
}
