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
    var offlineMode:Bool = false
    
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
            // check if this video id has been disabled in preferences
            let possible = defaults.objectForKey(video.id);
            
            if let possible = possible as? NSNumber {
                if possible.boolValue == false {
                    debugLog("video is disabled: \(video)");
                    continue;
                }
            }
            
            // check if we're in offline mode
            if offlineMode == true {
                if video.isAvailableOffline == false {
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
                self.loadSavedManifest();
                return;
            }
            
            guard let data = data else {
                NSLog("Couldn't load manifest!");
                self.loadSavedManifest();
                return;
            }
            // save data
            let defaults = self.defaults
            defaults.setObject(data, forKey: "manifest");
            defaults.synchronize()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.readJSONFromData(data);
            })
            
        };
        let url = NSURL(string: "http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json");
        // use ephemeral session so when we load json offline it fails and puts us in offline mode
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        let task = session.dataTaskWithURL(url!, completionHandler:completionHandler);
        task.resume();
    }
    
    func loadSavedManifest() {
        guard let savedJSON = defaults.objectForKey("manifest") as? NSData else {
            debugLog("Couldn't find saved manifest");
            return;
        }
        
        offlineMode = true;
        readJSONFromData(savedJSON)
    }
    
    func readJSONFromData(data:NSData) {
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
                    
                    checkContentLength(video)
                }
            }
            
            self.loadedManifest = videos;
        }
        catch {
            NSLog("Aerial: Error retrieving content listing.");
            return;
        }
    }
    
    func checkContentLength(video:AerialVideo) {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        let request = NSMutableURLRequest(URL: video.url)
        request.HTTPMethod = "HEAD"
        
        let task = session.dataTaskWithRequest(request) { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            video.contentLengthChecked = true
            
            if let error = error {
                NSLog("error fetching content length: \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.receivedContentLengthResponse()
                })
                return;
            }
            
            guard let response = response else {
                return;
            }
            
            video.contentLength = Int(response.expectedContentLength);
//            NSLog("content length: \(response.expectedContentLength)");
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.receivedContentLengthResponse()
            })
        }
        
        task.resume()
    }
    
    func receivedContentLengthResponse() {
        // check if content length on all videos has been checked
        for video in loadedManifest {
            if video.contentLengthChecked == false {
                return;
            }
        }
        
        filterVideoAndProcessCallbacks()
    }
    
    func filterVideoAndProcessCallbacks() {
        let unfiltered = loadedManifest
        
        var filtered = [AerialVideo]()
        for video in unfiltered {
            // offline? eror? just put it through
            if video.contentLength == 0  {
                filtered.append(video)
                continue;
            }
            
            // check to see if we find another video with the same content length
            var isDuplicate = false
            for videoCheck in filtered {
                if videoCheck.id == video.id {
                    isDuplicate = true;
                    continue;
                }
                
                if videoCheck.name != video.name {
                    continue;
                }
                
                if videoCheck.timeOfDay != video.timeOfDay {
                    continue
                }
                
                if videoCheck.contentLength == video.contentLength {
//                    NSLog("removing duplicate video \(videoCheck.name) \(videoCheck.timeOfDay)");
                    isDuplicate = true;
                    break;
                }
            } // dupe check
            
            if isDuplicate == true {
                continue;
            }
            
            filtered.append(video)
        }
        
        loadedManifest = filtered
        
        
        // callbacks
        for callback in self.callbacks {
            callback(filtered);
        }
        self.callbacks.removeAll()
    }
}