//
//  AerialVideo.swift
//  Aerial
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation

class AerialVideo {
    let id: String
    let name: String
    let type: String
    let timeOfDay: String
    let url: URL
    var arrayPosition = 1
    var contentLength = 0
    var contentLengthChecked = false
    
    var isAvailableOffline: Bool {
        get {
            return VideoCache.isAvailableOffline(video: self)
        }
    }
    
    init(id: String, name: String, type: String,
         timeOfDay: String, url: String) {
        self.id = id
        self.name = name
        self.type = type
        self.timeOfDay = timeOfDay
        self.url = URL(string: url)!
    }
}
