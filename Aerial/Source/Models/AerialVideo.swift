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
        return lhs.id == rhs.id && lhs.url1080p == rhs.url1080p
    }
    
    let id: String
    let name: String
    let type: String
    let timeOfDay: String
    let url1080p: URL
    let url4K: URL
    var arrayPosition = 1
    var contentLength = 0
    var contentLengthChecked = false
    
    var isAvailableOffline: Bool {
        get {
            return VideoCache.isAvailableOffline(video: self)
        }
    }
    
    init(id: String, name: String, type: String,
         timeOfDay: String, url1080p: String, url4K: String) {
        self.id = id
        self.name = name
        self.type = type
        self.timeOfDay = timeOfDay
        self.url1080p = URL(string: url1080p)!
        self.url4K = URL(string: url4K)!
    }
    
    var description: String {
        return "id=\(id), name=\(name), type=\(type), timeofDay=\(timeOfDay), url1080p=\(url1080p), url4K=\(url4K)"
    }
}
