//
//  ManifestLoader.swift
//  Aerial
//
//  Created by John Coates on 10/28/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import ScreenSaver

typealias manifestLoadCallback = ([AerialVideo]) -> (Void)

class ManifestLoader {
    static let instance: ManifestLoader = ManifestLoader()
    
    lazy var preferences = Preferences.sharedInstance
    var callbacks = [manifestLoadCallback]()
    var loadedManifest = [AerialVideo]()
    var playedVideos = [AerialVideo]()
    
    func addCallback(_ callback:@escaping manifestLoadCallback) {
        if loadedManifest.count > 0 {
            callback(loadedManifest)
        } else {
            callbacks.append(callback)
        }
    }
    
    func randomVideo(excluding: [AerialVideo]) -> AerialVideo? {
        let shuffled = loadedManifest.shuffled()
        for video in shuffled {
            let inRotation = preferences.videoIsInRotation(videoID: video.id)
            
            if !inRotation {
                debugLog("randomVideo: video is disabled: \(video)")
                continue
            }
            
            if excluding.contains(video) && preferences.neverStreamVideos == false {
                debugLog("randomVideo: video is excluded because it's already in use: \(video)")
                continue
            }
            
            // We may not want to stream
            if preferences.neverStreamVideos == true {
                if video.isAvailableOffline == false {
                    debugLog("randomVideo: video is excluded because it's not available offline \(video)")
                    continue
                }
            }
            
            return video
        }
        
        // nothing available??? return first thing we find
        if preferences.neverStreamVideos == true {
            if excluding.count > 0 {
                debugLog("randomVideo: no new video available and no streaming allowed, returning previous video !")
                return excluding.first
            }
            else {
                debugLog("randomVideo: no video available and no streaming allowed !")
                return nil
            }
        }
        else {
            debugLog("randomVideo: no video available, taking one from shuffled manifest")
            return shuffled.first
        }
    }
    
    init() {
        // start loading right away!
        let completionHandler = { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let error = error {
                debugLog("Error Loading Manifest: \(error)")
                self.loadSavedManifest()
                return
            }
            
            guard let data = data else {
                debugLog("No data from Manifest")
                self.loadSavedManifest()
                return
            }
            
            // Save tar file to cache path and extract json
            if let cacheDirectory = VideoCache.cacheDirectory {
                var cacheResourcesUrl = URL(fileURLWithPath: cacheDirectory as String)
                cacheResourcesUrl.appendPathComponent("resources.tar")
                
                var cacheResourcesString = cacheDirectory
                cacheResourcesString.append(contentsOf: "/resources.tar")
                
                do {
                    try data.write(to: cacheResourcesUrl)
                }
                catch
                {
                    debugLog("Error saving resources.tar.")
                }
                
                // Extract json
                let process:Process = Process()
                
                process.currentDirectoryPath = cacheDirectory
                process.launchPath = "/usr/bin/tar"
                process.arguments = ["-xvf",cacheResourcesString]

                process.launch()
                
                process.waitUntilExit()
                
                var cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
                cacheFileUrl.appendPathComponent("entries.json")
                do {
                    let ndata = try Data(contentsOf: cacheFileUrl)
                    
                    self.preferences.manifestTvOS12 = ndata
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.readJSONFromData(ndata)
                    })
                }
                catch {
                    NSLog("Aerial: Error can't load entries.json")
                }
            }
        }

        // Temporary fix until rewrite for multiple jsons, use saved preferences, or redownload json in that order. Intermediary step to be added : reload tar file !
        if preferences.manifestTvOS12 != nil {
            debugLog("using manifest from saved preferences")
            loadSavedManifest()
        }
        else {
            /*if let cacheDirectory = VideoCache.cacheDirectory {
                var cacheResourcesString = cacheDirectory
                cacheResourcesString.append(contentsOf: "/resources.tar")
                
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: cacheResourcesString) {
                    debugLog("using manifest from saved preferences")
                    loadSavedManifest()
                } else {*/
            debugLog("fetching manifest online")
            // updated url for tvOS12, json is now in a tar file
            let apiURL = "https://sylvan.apple.com/Aerials/resources.tar"
            guard let url = URL(string: apiURL) else {
                fatalError("Couldn't init URL from string")
            }
            // use ephemeral session so when we load json offline it fails and puts us in offline mode
            let configuration = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: configuration)
            let task = session.dataTask(with: url, completionHandler: completionHandler)
            task.resume()
                //}
            //}
        }
    }
    
    func loadSavedManifest() {
        guard let savedJSON = preferences.manifestTvOS12 else {
            debugLog("Couldn't find saved manifest for tvOS12")
            return
        }
        
        readJSONFromData(savedJSON)
    }
    
    func readJSONFromData(_ data: Data) {
        var videos = [AerialVideo]()
        
        do {
            let options = JSONSerialization.ReadingOptions.allowFragments
            
            let batches = try JSONSerialization.jsonObject(with: data,

                                                           options: options)
            
            guard let batch = batches as? NSDictionary else {
                NSLog("Aerial: Encountered unexpected content type for batch")
                return
            }
            
            let assets = batch["assets"] as! Array<NSDictionary>
            
            for item in assets {
                let url1080pH264 = item["url-1080-H264"] as? String
                let url1080pHEVC = item["url-1080-SDR"] as! String
                let url4KHEVC = item["url-4K-SDR"] as! String
                let name = item["accessibilityLabel"] as! String
                let timeOfDay = "day"   // TODO, this is hardcoded as it's no longer available in the JSON
                let id = item["id"] as! String
                let type = "video"
                let poi = item["pointsOfInterest"] as! [String: String]
                
                
                // NSLog("0 for \(name) \(String(describing: poi["0"]))")
                
                if (url1080pH264 != nil) {
                    let video = AerialVideo(id: id,
                                            name: name,
                                            type: type,
                                            timeOfDay: timeOfDay,
                                            url1080pH264: url1080pH264!,
                                            url1080pHEVC: url1080pHEVC,
                                            url4KHEVC: url4KHEVC,
                                            poi: poi)
                    
                    videos.append(video)
                
                    checkContentLength(video)
                }
            }
            
            self.loadedManifest = videos
        } catch {
            NSLog("Aerial: Error retrieving content listing.")
            return
        }
    }
    
    func checkContentLength(_ video: AerialVideo) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let request = NSMutableURLRequest(url: video.url as URL)
        
        request.httpMethod = "HEAD"
        
        let task = session.dataTask(with: request as URLRequest,
                                    completionHandler: {
                                        data, response, error in
            video.contentLengthChecked = true
            
            if let error = error {
                NSLog("error fetching content length: \(error)")
                DispatchQueue.main.async(execute: { () -> Void in
                    self.receivedContentLengthResponse()
                })
                return
            }
            
            guard let response = response else {
                return
            }
            
            video.contentLength = Int(response.expectedContentLength)
//            NSLog("content length: \(response.expectedContentLength)")
            DispatchQueue.main.async(execute: { () -> Void in
                self.receivedContentLengthResponse()
            })
        }) 
        
        task.resume()
    }
    
    func receivedContentLengthResponse() {
        // check if content length on all videos has been checked
        for video in loadedManifest {
            if video.contentLengthChecked == false {
                return
            }
        }
        
        filterVideoAndProcessCallbacks()
    }
    
    func filterVideoAndProcessCallbacks() {
        let unfiltered = loadedManifest
        
        var filtered = [AerialVideo]()
        for video in unfiltered {
            // offline? eror? just put it through
            if video.contentLength == 0 {
                filtered.append(video)
                continue
            }
            
            // check to see if we find another video with the same content length
            var isDuplicate = false
            for videoCheck in filtered {
                if videoCheck.id == video.id {
                    isDuplicate = true
                    continue
                }
                
                if videoCheck.name != video.name {
                    continue
                }
                
                if videoCheck.timeOfDay != video.timeOfDay {
                    continue
                }
                
                if videoCheck.contentLength == video.contentLength {
//                    NSLog("removing duplicate video \(videoCheck.name) \(videoCheck.timeOfDay)")
                    isDuplicate = true
                    break
                }
            } // dupe check
            
            if isDuplicate == true {
                continue
            }
            
            filtered.append(video)
        }
        
        loadedManifest = filtered
        
        // callbacks
        for callback in self.callbacks {
            callback(filtered)
        }
        self.callbacks.removeAll()
    }
}
