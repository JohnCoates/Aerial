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
    var processedVideos = [AerialVideo]()
    
    // Those videos will be ignored
    let blacklist = ["b10-1.mov",           // Dupe of b1-1 (Hawaii, day)
                     "b10-2.mov",           // Dupe of b2-3 (New York, night)
                     "b10-4.mov",           // Dupe of b2-4 (San Francisco, night)
                     "b9-1.mov",            // Dupe of b2-2 (Hawaii, day)
                     "b9-2.mov",            // Dupe of b3-1 (London, night)
                     "comp_LA_A005_C009_v05_t9_6M.mov",     // Low quality version of Los Angeles day 687B36CB-BA5D-4434-BA99-2F2B8B6EC163
                     "comp_LA_A009_C009_t9_6M_tag0.mov"]    // Low quality version of Los Angeles night 89B1643B-06DD-4DEC-B1B0-774493B0F7B7
    
    // This is used for videos where URLs should be merged with different ID
    let dupePairs = ["88025454-6D58-48E8-A2DB-924988FAD7AC":"6E2FC8AC-832D-46CF-B306-BB2A05030C17"] // Liwa
    
    // Extra info to be merged for a given ID, as of right now only one known video
    let mergeInfo = ["2F11E857-4F77-4476-8033-4A1E4610AFCC":
        ["url-1080-SDR":"https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_2K_SDR_HEVC.mov",
         "url-4K-SDR":"https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_4K_SDR_HEVC.mov"]]
    func addCallback(_ callback:@escaping manifestLoadCallback) {
        if loadedManifest.count > 0 {
            callback(loadedManifest)
        } else {
            callbacks.append(callback)
        }
    }
    
    func randomVideo(excluding: [AerialVideo]) -> AerialVideo? {
        let timeManagement = TimeManagement.sharedInstance
        let (shouldRestrictByDayNight,restrictTo) = timeManagement.shouldRestrictPlaybackToDayNightVideo()
        //debugLog("randomVideo shouldRestrict : \(shouldRestrictByDayNight) to : \(restrictTo)")
        
        let shuffled = loadedManifest.shuffled()
        for video in shuffled {
            let inRotation = preferences.videoIsInRotation(videoID: video.id)
            
            if !inRotation {
                //debugLog("randomVideo: video is disabled: \(video)")
                continue
            }
            
            if excluding.contains(video) && preferences.neverStreamVideos == false {
                //debugLog("randomVideo: video is excluded because it's already in use: \(video)")
                continue
            }
            
            // Do we restrict video types by day/night ?
            if shouldRestrictByDayNight {
                if video.timeOfDay != restrictTo {
                    //debugLog("randomVideo: video is excluded as we only play \(restrictTo) (is: \(video.timeOfDay))")
                    continue
                }
                
            }
            // We may not want to stream
            if preferences.neverStreamVideos == true {
                if video.isAvailableOffline == false {
                    //debugLog("randomVideo: video is excluded because it's not available offline \(video)")
                    continue
                }
            }
            
            //debugLog("randomVideo: picked \(video)")
            return video
        }
        
        // nothing available??? return first thing we find
        if preferences.neverStreamVideos == true {
            if excluding.count > 0 {
                //debugLog("randomVideo: no new video available and no streaming allowed, returning previous video !")
                return excluding.first
            }
            else {
                //debugLog("randomVideo: no video available and no streaming allowed !")
                return nil
            }
        }
        else {
            debugLog("randomVideo: no video available, taking one from shuffled manifest")
            return shuffled.first
        }
    }
    
    init() {
        // We try to load our video manifests in 3 steps :
        // - use locally saved data in preferences plist
        // - reprocess the saved files in cache directory (full offline mode)
        // - download the manifests from servers
        if areManifestsSaved() {
            loadSavedManifests()
        }
        else
        {
            // Manifests are not in our preferences plist, are they cached on disk ?
            if areManifestsCached() {
                debugLog("Manifests are cached, loading")
                loadCachedManifests()
            }
            else {
                // Ok then, we fetch them...
                debugLog("fetching missing manifests online")
                let downloadManager = DownloadManager()
                
                var urls: [URL] = []
                
                // For tvOS12, json is now in a tar file
                if (!isManifestCached(manifest: .tvOS12)) {
                    urls.append(URL(string: "https://sylvan.apple.com/Aerials/resources.tar")!)
                }

                if (!isManifestCached(manifest: .tvOS11)) {
                    urls.append(URL(string: "https://sylvan.apple.com/Aerials/2x/entries.json")!)
                }
                
                if (!isManifestCached(manifest: .tvOS10)) {
                    urls.append(URL(string: "http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json")!)
                }

                let completion = BlockOperation {
                    debugLog("fetching all done")
                    // We can now load from the newly cached files
                    self.loadCachedManifests()
                }
                
                for url in urls {
                    let operation = downloadManager.queueDownload(url)
                    completion.addDependency(operation)
                }
                
                OperationQueue.main.addOperation(completion)
            }
        }
    }

    // Check if the Manifests have been saved in our preferences plist
    func areManifestsSaved() -> Bool {
        if (preferences.manifestTvOS12 != nil && preferences.manifestTvOS11 != nil && preferences.manifestTvOS10 != nil) {
            debugLog("manifests are saved in preferences")
            return true
        }
        else {
            debugLog("manifests are NOT saved in preferences")
            return false
        }
    }

    // Check if the Manifests are saved in our cache directory
    func areManifestsCached() -> Bool {
        return isManifestCached(manifest: .tvOS10) && isManifestCached(manifest: .tvOS11) && isManifestCached(manifest: .tvOS12)
    }
    
    // Check if a Manifest is saved in our cache directory
    func isManifestCached(manifest: Manifests) -> Bool {
        if let cacheDirectory = VideoCache.cacheDirectory {
            let fileManager = FileManager.default
            
            var cacheResourcesString = cacheDirectory
            cacheResourcesString.append(contentsOf: "/" + manifest.rawValue)
            
            if !fileManager.fileExists(atPath: cacheResourcesString) {
                return false
            }
            
            debugLog("\(manifest.rawValue) manifest is cached")
        }
        else
        {
            return false
        }
        
        return true
    }
    
    // Load the JSON Data cached on disk
    func loadCachedManifests() {
        if let cacheDirectory = VideoCache.cacheDirectory {
            // tvOS12
            var cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
            cacheFileUrl.appendPathComponent("entries.json")

            do {
                let ndata = try Data(contentsOf: cacheFileUrl)
                self.preferences.manifestTvOS12 = ndata
            }
            catch {
                NSLog("Aerial: Error can't load entries.json from cached directory (tvOS12)")
            }
            
            // tvOS11
            cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
            cacheFileUrl.appendPathComponent("tvOS11.json")
            
            do {
                let ndata = try Data(contentsOf: cacheFileUrl)
                self.preferences.manifestTvOS11 = ndata
            }
            catch {
                NSLog("Aerial: Error can't load tvos11.json from cached directory ")
            }

            // tvOS11
            cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
            cacheFileUrl.appendPathComponent("tvos10.json")
            
            do {
                let ndata = try Data(contentsOf: cacheFileUrl)
                self.preferences.manifestTvOS10 = ndata
            }
            catch {
                NSLog("Aerial: Error can't load tvos10.json from cached directory")
            }
            
            loadSavedManifests()
        }
    }
    
    // Load Manifests from the saved preferences
    func loadSavedManifests() {
        // Reset our array
        processedVideos = []

        // We start with the more recent one, it has more information (poi, etc)
        readJSONFromData(preferences.manifestTvOS12!, manifest: .tvOS12)
        // This one has a couple videos not in the tvOS12 JSON. No H264 for these !
        readJSONFromData(preferences.manifestTvOS11!, manifest: .tvOS11)
        // The original manifest is in another format
        readOldJSONFromData(preferences.manifestTvOS10!, manifest: .tvOS10)

        processedVideos = processedVideos.sorted { $0.secondaryName < $1.secondaryName }    // Only matters for Space videos, this way they show sorted in the Space category
        self.loadedManifest = processedVideos
        
        debugLog("\(processedVideos.count) videos processed !")
    }
    
    func readJSONFromData(_ data: Data, manifest: Manifests) {
        //var videos = [AerialVideo]()
        
        do {
            let options = JSONSerialization.ReadingOptions.allowFragments
            let batches = try JSONSerialization.jsonObject(with: data, options: options)
            
            guard let batch = batches as? NSDictionary else {
                NSLog("Aerial: Encountered unexpected content type for batch, please report !")
                return
            }
            
            let assets = batch["assets"] as! Array<NSDictionary>
            
            for item in assets {
                let url1080pH264 = item["url-1080-H264"] as? String
                let url1080pHEVC = item["url-1080-SDR"] as? String
                let url4KHEVC = item["url-4K-SDR"] as? String
                let name = item["accessibilityLabel"] as! String //.appending(" (" + manifest.rawValue + ")")
                
                let timeOfDay = "day"   // TODO, this is hardcoded as it's no longer available in the modern JSONs
                let id = item["id"] as! String
                let type = "video"
                let poi = item["pointsOfInterest"] as? [String: String]
                let (isDupe,foundDupe) = findDuplicate(id: id, url1080pH264: url1080pH264 ?? "")
                if (isDupe) {
                    //debugLog("duplicate found, adding \(manifest) as source to \(name)")
                    foundDupe!.sources.append(manifest)
                }
                else {
                    let video = AerialVideo(id: id,             // Must have
                        name: name,         // Must have
                        type: type,         // Not sure the point of this one ?
                        timeOfDay: timeOfDay,
                        url1080pH264: url1080pH264 ?? "",
                        url1080pHEVC: url1080pHEVC ?? "",
                        url4KHEVC: url4KHEVC ?? "",
                        manifest: manifest,
                        poi: poi ?? [:])    // tvOS12 only
                    
                    processedVideos.append(video)
                    //checkContentLength(video)
                }
            }
        } catch {
            NSLog("Aerial: Error retrieving content listing.")
            return
        }
    }
    
    func readOldJSONFromData(_ data: Data, manifest: Manifests) {
        do {
            let options = JSONSerialization.ReadingOptions.allowFragments
            let batches = try JSONSerialization.jsonObject(with: data,
                                                           options: options) as! Array<NSDictionary>
            
            for batch: NSDictionary in batches {
                let assets = batch["assets"] as! Array<NSDictionary>
                
                for item in assets {
                    let url = item["url"] as! String
                    let name = item["accessibilityLabel"] as! String
                    let timeOfDay = item["timeOfDay"] as! String
                    let id = item["id"] as! String
                    let type = item["type"] as! String
                    
                    if type != "video" {
                        continue
                    }
                    
                    let (isDupe,foundDupe) = findDuplicate(id: id, url1080pH264: url)
                    if isDupe {
                        if (foundDupe != nil) {
                            //debugLog("duplicate found, adding \(manifest) as source to \(name)")
                            foundDupe!.sources.append(manifest)
                            
                            if (foundDupe?.url1080pH264 == "") {
                                //debugLog("merging urls for \(url)")
                                foundDupe?.url1080pH264 = url
                            }
                            
                        }
                    }
                    else {
                        var url4khevc = ""
                        var url1080phevc = ""
                        // Check if we have some HEVC urls to merge
                        if let val = mergeInfo[id] {
                            url1080phevc = val["url-1080-SDR"]!
                            url4khevc = val["url-4K-SDR"]!
                        }

                        let video = AerialVideo(id: id,             // Must have
                            name: name,         // Must have
                            type: type,         // Not sure the point of this one ?
                            timeOfDay: timeOfDay,
                            url1080pH264: url,
                            url1080pHEVC: url1080phevc,
                            url4KHEVC: url4khevc,
                            manifest: manifest,
                            poi: [:])    // tvOS12 only
                        
                        processedVideos.append(video)
                        //checkContentLength(video)
                    }
                    /*let video = AerialVideo(id: id,
                                            name: name,
                                            type: type,
                                            timeOfDay: timeOfDay,
                                            url: url)
                    
                    videos.append(video)
                    
                    checkContentLength(video)*/
                }
            }
            
            //self.loadedManifest = videos
        } catch {
            NSLog("Aerial: Error retrieving content listing.")
            return
        }
    }
    
    // Look for a previously processed similar video
    //
    // tvOS11 and 12 JSON are using the same ID (and tvOS12 JSON always has better data,
    // so no need for a fancy merge)
    //
    // tvOS10 however JSON DOES NOT use the same ID, so we need to dupecheck on the h264
    // (only available format there) filename (they actually have different URLs !)
    func findDuplicate(id: String, url1080pH264: String) -> (Bool,AerialVideo?)
    {
        // We blacklist some duplicates
        if (url1080pH264 != "") {
            if (blacklist.contains((URL(string:url1080pH264)?.lastPathComponent)!))
            {
                //debugLog("Blacklisted video : \(url1080pH264)")
                return (true,nil)
            }
        }
        
        // We also have a Dictionary of duplicates that need source merging
        for (pid,replace) in dupePairs {
            if (id == pid)
            {
                //debugLog("duplicate found by dupePairs \(id)")
                for vid in processedVideos {
                    if vid.id == replace {
                        return (true,vid)
                    }
                }
            }
        }
        
        for video in processedVideos {
            if id == video.id {
                //debugLog("duplicate found by ID")
                return (true,video)
            }
            else if (url1080pH264 != "" && video.url1080pH264 != "") {
                if (URL(string:url1080pH264)?.lastPathComponent == URL(string:video.url1080pH264)?.lastPathComponent) {
                    //debugLog("duplicate found by filename")
                    return (true,video)
                }
            }
        }
        
        return (false,nil)
    }
    
/*    func checkContentLength(_ video: AerialVideo) {
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
    }*/
}
