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
    var processedVideos = [AerialVideo]()
    var lastPluckedFromPlaylist: AerialVideo?
    
    // Playlist management
    var playlistIsRestricted = false
    var playlistRestrictedTo = ""
    var playlist = [AerialVideo]()
    
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
         "url-4K-SDR":"https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_4K_SDR_HEVC.mov"]]   // Dubai night 2
    
    // Better Descriptions
    let mergeName = [
        "6C3D54AE-0871-498A-81D0-56ED24E5FE9F":"Korea and Japan Night",             // Fixint Typo
        "B876B645-3955-420E-99DF-60139E451CF3":"Wulingyuan National Park 1",        // China day 1
        "9CCB8297-E9F5-4699-AE1F-890CFBD5E29C":"Longji Rice Terraces",              // China day 2
        "D5E76230-81A3-4F65-A1BA-51B8CADED625":"Wulingyuan National Park 2",        // China day 3
        "b6-1":"Great Wall 1",                                                      // China day 4
        "b2-1":"Great Wall 2",                                                      // China day 5
        "b5-1":"Great Wall 3",                                                      // China day 6
        
        "AC9C09DD-1D97-4013-A09F-B0F5259E64C3":"Sheikh Zayed Road",                 // Dubai day 1
        "49790B7C-7D8C-466C-A09E-83E38B6BE87A":"Marina 1",                          // Dubai day 2
        "02EA5DBE-3A67-4DFA-8528-12901DFD6CC1":"Downtown",                          // Dubai day 3
        "802866E6-4AAF-4A69-96EA-C582651391F1":"Marina 2",                          // Dubai day 4
        
        "BAF76353-3475-4855-B7E1-CE96CC9BC3A7":"Approaching Burj Khalifa",          // Dubai night 1
        "2F11E857-4F77-4476-8033-4A1E4610AFCC":"Sheikh Zayed Road",                 // Dubai night 2
        
        "E4ED0B22-EB81-4D4F-A29E-7E1EA6B6D980":"Nuussuaq Peninsula",                // Greenland day 1
        "30047FDA-3AE3-4E74-9575-3520AD77865B":"Ilulissat Icefjord",                // Greenland day 2
        
        "7D4710EB-5BA4-42E6-AA60-68D77F67D9B9":"Ilulissat Icefjord",                // Greenland night 1
        
        "b7-1":"Laupāhoehoe Nui",                                                   // Hawaii day 1
        "b1-1":"Waimanu Valley",                                                    // Hawaii day 2
        "b2-2":"Honopū Valley",                                                     // Hawaii day 3
        "b4-1":"Pu‘u O ‘Umi",                                                       // Hawaii day 4
        
        "b6-2":"Kohala coastline",                                                  // Hawaii night 1
        "b8-1":"Pu‘u O ‘Umi",                                                       // Hawaii night 2
        
        "102C19D1-9D9F-48EC-B492-074C985C4D9F":"Victoria Harbour 1",                // Hong Kong day 1
        "560E09E8-E89D-4ADB-8EEA-4754415383D4":"Victoria Peak",                     // Hong Kong day 2
        "024891DE-B7F6-4187-BFE0-E6D237702EF0":"Wan Chai",                          // Hong Kong day 3
        "786E674C-BB22-4AA9-9BD3-114D2020EC4D":"Victoria Harbour 2",                // Hong Kong day 4
        
        "30313BC1-BF20-45EB-A7B1-5A6FFDBD2488":"Victoria Harbour",                  // Hong Kong night 1
        
        "6E2FC8AC-832D-46CF-B306-BB2A05030C17":"Liwa Oasis",                        // Liwa day 1
        
        "b6-3":"Tower Bridge",                                                      // London day 1
        "b5-2":"Buckingham Palace",                                                 // London day 2
        
        "b1-2":"Tower Bridge 1",                                                    // London night 1
        "b3-1":"Tower Bridge 2",                                                    // London night 2
        
        "829E69BA-BB53-4841-A138-4DF0C2A74236":"LAX",                               // Los Angeles day 1
        "30A2A488-E708-42E7-9A90-B749A407AE1C":"Interstate 110",                    // Los Angeles day 2
        "B730433D-1B3B-4B99-9500-A286BF7A9940":"Santa Monica Beach",                // Los Angeles day 3
        
        "89B1643B-06DD-4DEC-B1B0-774493B0F7B7":"Griffith Observatory",              // Los Angeles night 1
        "EC67726A-8212-4C5E-83CF-8412932740D2":"Hollywood Sign",                    // Los Angeles night 2
        "A284F0BF-E690-4C13-92E2-4672D93E8DE5":"Downtown",                          // Los Angeles night 3
        
        "b7-2":"Central Park",                                                      // New York day 1
        "b1-3":"Lower Manhattan",                                                   // New York day 2
        "b3-2":"Upper East Side",                                                   // New York day 3
        
        "b2-3":"7th avenue",                                                        // New York night 1
        "b4-2":"Lower Manhattan",                                                   // New York night 2
        
        
        "b8-2":"Marin Headlands",                                    // San Francisco day 1
        "b10-3":"Presidio to Golden Gate",                                          // San Francisco day 2
        "b9-3":"Bay and Golden Gate",                                               // San Francisco day 3
        "b8-3":"Downtown",                                                          // San Francisco day 4
        "b3-3":"Embarcadero/Market Street",                                      // San Francisco day 5
        "b4-3":"Golden Gate from SF",                                               // San Francisco day 6
        
        "b6-4":"Downtown/Coit Tower",                                               // San Francisco night 1
        "b7-3":"Fisherman's Wharf",                                                 // San Francisco night 2
        "b5-3":"Embarcadero/Market Street",                                      // San Francisco night 3
        "b1-4":"Bay Bridge",                                                        // San Francisco night 4
        "b2-4":"Downtown/Sutro Tower"                                               // San Francisco night 5
    ]
    
    // Extra POI
    let mergePOI = [
        "b6-1":"C001_C005_",    // China day 4
        "b2-1":"C004_C003_",    // China day 5
        "b5-1":"C003_C003_",    // China day 6
        "7D4710EB-5BA4-42E6-AA60-68D77F67D9B9":"GL_G010_C006_",             // Greenland night 1
        "b7-1":"H007_C003",                                                 // Hawaii day 1
        "b1-1":"H005_C012_",                                                // Hawaii day 2
        "b2-2":"H010_C006_",                                                // Hawaii day 3
        "b4-1":"H004_C007_",                                                // Hawaii day 4
        "b6-2":"H012_C009_",                                                // Hawaii night 1
        "b8-1":"H004_C009_",                                                // Hawaii night 2
        "6E2FC8AC-832D-46CF-B306-BB2A05030C17":"LW_L001_C006_",             // Liwa day 1 LW_L001_C006_0
        "b6-3":"L010_C006_",                                                // London day 1
        "b5-2":"L007_C007_",                                                // London day 2
        "b1-2":"L012_C002_",                                                // London night 1
        "b3-1":"L004_C011_",                                                // London night 2
        "A284F0BF-E690-4C13-92E2-4672D93E8DE5":"LA_A011_C003_",             // Los Angeles night 3
        "b7-2":"N008_C009_",                                                // New York day 1
        "b1-3":"N006_C003_",                                                // New York day 2
        "b3-2":"N003_C006_",                                                // New York day 3
        "b2-3":"N013_C004_",                                                // New York night 1
        "b4-2":"N008_C003_",                                                // New York night 2

        "b8-2":"A008_C007_",                                                // San Francisco day 1
        "b10-3":"A013_C005_",                                               // San Francisco day 2
        "b9-3":"A006_C003_",                                                // San Francisco day 3
        //"b8-3":"",     San Francisco day 4 (no extra poi ?)
        "b3-3":"A012_C014_",                                                // San Francisco day 5
                                                                            //   maybe A013_C004 ?
        "b4-3":"A013_C012_",                                                // San Francisco day 6
        "b6-4":"A004_C012_",                                                // San Francisco night 1
        "b7-3":"A007_C017_",                                                // San Francisco night 2
        "b5-3":"A015_C014_",                                                // San Francisco night 3
        "b1-4":"A015_C018_",                                                // San Francisco night 4
        "b2-4":"A018_C014_"                                                 // San Francisco night 5
    ]
    
    func addCallback(_ callback:@escaping manifestLoadCallback) {
        if loadedManifest.count > 0 {
            callback(loadedManifest)
        } else {
            callbacks.append(callback)
        }
    }
    
    func generatePlaylist(isRestricted:Bool, restrictedTo:String) {
        // Start fresh
        playlist = [AerialVideo]()
        playlistIsRestricted = isRestricted
        playlistRestrictedTo = restrictedTo
        
        // Start with a shuffled list
        let shuffled = loadedManifest.shuffled()

        for video in shuffled {
            // We exclude videos not in rotation
            let inRotation = preferences.videoIsInRotation(videoID: video.id)
            
            if !inRotation {
                //debugLog("randomVideo: video is disabled: \(video)")
                continue
            }

            // Do we restrict video types by day/night ?
            if isRestricted {
                if video.timeOfDay != restrictedTo {
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

            // All good ? Add to playlist
            playlist.append(video)
        }
        
        // On regenerating a new playlist, we try to avoid repeating
        while (playlist.count > 1 && lastPluckedFromPlaylist == playlist.first) {
            //NSLog("AerialDBG: Reshuffle")
            playlist.shuffle()
        }
    }
    
    func randomVideo(excluding: [AerialVideo]) -> AerialVideo? {
        let timeManagement = TimeManagement.sharedInstance
        let (shouldRestrictByDayNight,restrictTo) = timeManagement.shouldRestrictPlaybackToDayNightVideo()

        if (playlist.count == 0 || (restrictTo != playlistRestrictedTo) || (shouldRestrictByDayNight != playlistIsRestricted)) {
            //NSLog("AerialDBG: Generating new playlist")
            generatePlaylist(isRestricted: shouldRestrictByDayNight, restrictedTo: restrictTo)
        }
        
        if playlist.count > 0 {
            lastPluckedFromPlaylist = playlist.removeFirst()
            return lastPluckedFromPlaylist
        } else {
            return findBestEffortVideo()
        }

    }
    
    // Find a backup plan when conditions are not met
    func findBestEffortVideo() -> AerialVideo? {
        // So this is embarassing. This can happen if :
        // - No video checked
        // - No video for current conditions (only day video checked, and looking for night)
        // - We don't want to stream but don't have any video
        // - We may not have the manifests
        // At this point we're doing a best effort :
        // - Did we play something previously ? If so play that back (will loop)
        // - return a random one from the manifest that is cached
        // - return a random video that is not cached (slight betrayal of the Never stream videos)
        
        NSLog("AerialDBG: empty playlist, not good !")

        if lastPluckedFromPlaylist != nil {
            NSLog("AerialDBG: returning last played video after condition change not met !")
            return lastPluckedFromPlaylist!
        } else {
            // Start with a shuffled list
            let shuffled = loadedManifest.shuffled()
            
            if (shuffled.count == 0)
            {
                // This is super bad, no manifest at all
                NSLog("AerialDBG: No manifest, nothing to play !")
                return nil
            }
            
            for video in shuffled {
                // We exclude videos not in rotation
                let inRotation = preferences.videoIsInRotation(videoID: video.id)
                
                // If we find anything cached and in rotation, we send that back
                if video.isAvailableOffline && inRotation {
                    NSLog("AerialDBG: returning random cached in rotation video after condition change not met !")
                    return video
                }
            }
            // Nothing ? Sorry but you'll get a non cached file
            NSLog("AerialDBG: returning random video after condition change not met !")
            return shuffled.first!
        }
    }
    
    init() {
        NSLog("AerialML: Manifest init")
        // We try to load our video manifests in 3 steps :
        // - use locally saved data in preferences plist
        // - reprocess the saved files in cache directory (full offline mode)
        // - download the manifests from servers

        NSLog("AerialML: 10 \(isManifestCached(manifest: .tvOS10))")
        NSLog("AerialML: 11 \(isManifestCached(manifest: .tvOS11))")
        NSLog("AerialML: 12 \(isManifestCached(manifest: .tvOS12))")
        
        if areManifestsSaved() {
            NSLog("AerialML: Loading from plist")
            loadSavedManifests()
        }
        else
        {
            NSLog("AerialML: Not available from plist")
            // Manifests are not in our preferences plist, are they cached on disk ?
            if areManifestsCached() {
                NSLog("AerialML: Manifests are cached on disk, loading")
                loadCachedManifests()
            }
            else {
                // Ok then, we fetch them...
                NSLog("AerialML: fetching missing manifests online")
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
                    NSLog("AerialML: fetching all done")
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
            NSLog("AerialML: manifests are saved in preferences")
            return true
        }
        else {
            NSLog("AerialML: manifests are NOT saved in preferences")
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
            
            NSLog("AerialML: \(manifest.rawValue) manifest is cached")
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
            NSLog("AerialML: 12path : \(cacheFileUrl)")
            do {
                let ndata = try Data(contentsOf: cacheFileUrl)
                self.preferences.manifestTvOS12 = ndata
            }
            catch {
                NSLog("Aerial: Error can't load entries.json from cached directory (tvOS12)")
            }
            
            // tvOS11
            cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
            cacheFileUrl.appendPathComponent("tvos11.json")
            NSLog("AerialML: 11path : \(cacheFileUrl)")

            do {
                let ndata = try Data(contentsOf: cacheFileUrl)
                self.preferences.manifestTvOS11 = ndata
            }
            catch {
                NSLog("Aerial: Error can't load tvos11.json from cached directory ")
            }

            // tvOS10
            cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
            cacheFileUrl.appendPathComponent("tvos10.json")
            NSLog("AerialML: 10path : \(cacheFileUrl)")

            do {
                let ndata = try Data(contentsOf: cacheFileUrl)
                self.preferences.manifestTvOS10 = ndata
            }
            catch {
                NSLog("Aerial: Error can't load tvos10.json from cached directory")
            }

            if self.preferences.manifestTvOS10 != nil || self.preferences.manifestTvOS11 != nil || self.preferences.manifestTvOS12 != nil {
                loadSavedManifests()
            } else {
                // No internet, no anything, nothing to do
                NSLog("AerialDBG: No video to load, no internet connexion ?")
            }
        }
    }
    
    // Load Manifests from the saved preferences
    func loadSavedManifests() {
        NSLog("AerialML: LSM")
        
        // Reset our array
        processedVideos = []

        if (preferences.manifestTvOS12 != nil) {
            NSLog("AerialML: lsm12")
            // We start with the more recent one, it has more information (poi, etc)
            readJSONFromData(preferences.manifestTvOS12!, manifest: .tvOS12)
        }
        if (preferences.manifestTvOS11 != nil) {
            NSLog("AerialML: lsm11")
            // This one has a couple videos not in the tvOS12 JSON. No H264 for these !
            readJSONFromData(preferences.manifestTvOS11!, manifest: .tvOS11)
        }
        if (preferences.manifestTvOS10 != nil) {
            NSLog("AerialML: lsm10")
            // The original manifest is in another format
            readOldJSONFromData(preferences.manifestTvOS10!, manifest: .tvOS10)
        }

        NSLog("AerialML: post json loading")

        processedVideos = processedVideos.sorted { $0.secondaryName < $1.secondaryName }    // Only matters for Space videos, this way they show sorted in the Space category
        
        self.loadedManifest = processedVideos
        
        NSLog("AerialML: \(processedVideos.count) videos processed !")
        
        // callbacks
        for callback in self.callbacks {
            NSLog("AerialML: Calling back")
            callback(self.loadedManifest)
        }
        self.callbacks.removeAll()
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
                let id = item["id"] as! String
                let url1080pH264 = item["url-1080-H264"] as? String
                let url1080pHEVC = item["url-1080-SDR"] as? String
                let url4KHEVC = item["url-4K-SDR"] as? String
                let name = item["accessibilityLabel"] as! String
                var secondaryName = ""
                // We may have a secondary name
                if let mergeName = mergeName[id] {
                    secondaryName = mergeName
                }
                
                let timeOfDay = "day"   // TODO, this is hardcoded as it's no longer available in the modern JSONs
                let type = "video"
                var poi : [String:String]?

                if let mergeId = mergePOI[id] {
                    let poiStringProvider = PoiStringProvider.sharedInstance
                    poi = poiStringProvider.fetchExtraPoiForId(id: mergeId)
                }
                else {
                    poi = item["pointsOfInterest"] as? [String: String]
                }
                let (isDupe,foundDupe) = findDuplicate(id: id, url1080pH264: url1080pH264 ?? "")
                if (isDupe) {
                    //debugLog("duplicate found, adding \(manifest) as source to \(name)")
                    foundDupe!.sources.append(manifest)
                }
                else {
                    let video = AerialVideo(id: id,             // Must have
                        name: name,                             // Must have
                        secondaryName: secondaryName,           // Optional
                        type: type,                             // Not sure the point of this one ?
                        timeOfDay: timeOfDay,
                        url1080pH264: url1080pH264 ?? "",
                        url1080pHEVC: url1080pHEVC ?? "",
                        url4KHEVC: url4KHEVC ?? "",
                        manifest: manifest,
                        poi: poi ?? [:] )                       // tvOS12 only
                    
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
                    
                    var secondaryName = ""
                    // We may have a secondary name
                    if let mergeName = mergeName[id] {
                        secondaryName = mergeName
                    }
                    
                    var poi : [String:String]?
                    if let mergeId = mergePOI[id] {
                        let poiStringProvider = PoiStringProvider.sharedInstance
                        poi = poiStringProvider.fetchExtraPoiForId(id: mergeId)
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
                            secondaryName: secondaryName,
                            type: type,         // Not sure the point of this one ?
                            timeOfDay: timeOfDay,
                            url1080pH264: url,
                            url1080pHEVC: url1080phevc,
                            url4KHEVC: url4khevc,
                            manifest: manifest,
                            poi: poi ?? [:])    // tvOS12 only
                        
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
