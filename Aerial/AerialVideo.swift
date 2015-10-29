//
//  AerialVideo.swift
//  Aerial
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation


class AerialVideo {
    let id:String;
    let name:String;
    let type:String;
    let timeOfDay:String;
    let url:NSURL;
    let localPath:NSURL;
    let cached:Bool;
    var arrayPosition:Int = 1;
    
    
    init(id:String, name:String, type:String, timeOfDay:String, url:String) {
        self.id = id;
        self.name = name;
        self.type = type;
        self.timeOfDay = timeOfDay;
        self.url = NSURL(string:url)!;
        let localPath = CACHE_DIR + self.url.lastPathComponent!
        self.localPath = NSURL(fileURLWithPath: localPath)
        self.cached = NSFileManager.defaultManager().fileExistsAtPath(localPath)
    }
    
}