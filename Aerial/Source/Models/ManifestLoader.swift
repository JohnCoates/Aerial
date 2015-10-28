//
//  ManifestLoader.swift
//  Aerial
//
//  Created by John Coates on 10/28/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import ScreenSaver

typealias manifestLoadCallback = ([AerialVideo]) -> (Void);

class ManifestLoader {
    static let instance:ManifestLoader = ManifestLoader();
    
    let defaults:NSUserDefaults = ScreenSaverDefaults(forModuleWithName: "com.JohnCoates.Aerial")! as ScreenSaverDefaults
    var callbacks = [manifestLoadCallback]();
    var loadedManifest = [AerialVideo]();
    var playedVideos = [AerialVideo]();
    
    func addCallback(callback:manifestLoadCallback) {
        if (loadedManifest.count > 0) {
            callback(loadedManifest);
        }
        else {
            callbacks.append(callback);
        }
    }
    
    func randomVideo() -> AerialVideo? {
        
        let shuffled = loadedManifest.shuffle();
        
        for video in shuffled {
            let possible = defaults.objectForKey(video.id);
            
            if let possible = possible as? NSNumber {
                if possible.boolValue == false {
                    continue;
                }
            }
            
            return video;
        }
        
        // nothing available??? return first thing we find
        return shuffled.first;
    }
    
    init() {
        // start loading right away!
        let completionHandler = { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            if let error = error {
                NSLog("Aerial Error Loading Manifest: \(error)");
                return;
            }
            
            guard let data = data else {
                NSLog("Couldn't load manifest!");
                return;
            }
            
            var videos = [AerialVideo]();
            
            do {
                let batches = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! Array<NSDictionary>;
                
                for batch:NSDictionary in batches {
                    let assets = batch["assets"] as! Array<NSDictionary>;
                    
                    for item in assets {
                        let url = item["url"] as! String;
                        let name = item["accessibilityLabel"] as! String;
                        let timeOfDay = item["timeOfDay"] as! String;
                        let id = item["id"] as! String;
                        let type = item["type"] as! String;
                        
                        if (type != "video") {
                            continue;
                        }
                        
                        
                        let video = AerialVideo(id: id, name: name, type: type, timeOfDay: timeOfDay, url: url);
                        
                        videos.append(video)
                    }
                }
                
                self.loadedManifest = videos;
                
                // callbacks
                for callback in self.callbacks {
                    callback(videos);
                }
                self.callbacks.removeAll()
                
            }
            catch {
                NSLog("Aerial: Error retrieving content listing.");
                return;
            }
            
            
        };
        let url = NSURL(string: "http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json");
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:completionHandler);
        task.resume();
    }
}