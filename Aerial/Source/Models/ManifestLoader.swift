//
//  ManifestLoader.swift
//  Aerial
//
//  Created by John Coates on 10/28/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import ScreenSaver

typealias ManifestLoadCallback = ([AerialVideo]) -> Void

// swiftlint:disable:next type_body_length
class ManifestLoader {
    static let instance: ManifestLoader = ManifestLoader()

    lazy var preferences = Preferences.sharedInstance
    var callbacks = [ManifestLoadCallback]()
    var loadedManifest = [AerialVideo]()
    var processedVideos = [AerialVideo]()
    var lastPluckedFromPlaylist: AerialVideo?

    var manifestTvOS10: Data?
    var manifestTvOS11: Data?
    var manifestTvOS12: Data?

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
                     "comp_LA_A009_C009_t9_6M_tag0.mov", ]    // Low quality version of Los Angeles night 89B1643B-06DD-4DEC-B1B0-774493B0F7B7

    // This is used for videos where URLs should be merged with different ID
    let dupePairs = ["88025454-6D58-48E8-A2DB-924988FAD7AC": "6E2FC8AC-832D-46CF-B306-BB2A05030C17"] // Liwa

    // Extra info to be merged for a given ID, as of right now only one known video
    let mergeInfo = ["2F11E857-4F77-4476-8033-4A1E4610AFCC":
        ["url-1080-SDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_2K_SDR_HEVC.mov",
         "url-4K-SDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_4K_SDR_HEVC.mov", ], ]   // Dubai night 2

    // Extra POI
    let mergePOI = [
        "b6-1": "C001_C005_",    // China day 4
        "b2-1": "C004_C003_",    // China day 5
        "b5-1": "C003_C003_",    // China day 6
        "7D4710EB-5BA4-42E6-AA60-68D77F67D9B9": "GL_G010_C006_",             // Greenland night 1
        "b7-1": "H007_C003",                                                 // Hawaii day 1
        "b1-1": "H005_C012_",                                                // Hawaii day 2
        "b2-2": "H010_C006_",                                                // Hawaii day 3
        "b4-1": "H004_C007_",                                                // Hawaii day 4
        "b6-2": "H012_C009_",                                                // Hawaii night 1
        "b8-1": "H004_C009_",                                                // Hawaii night 2
        "6E2FC8AC-832D-46CF-B306-BB2A05030C17": "LW_L001_C006_",             // Liwa day 1 LW_L001_C006_0
        "b6-3": "L010_C006_",                                                // London day 1
        "b5-2": "L007_C007_",                                                // London day 2
        "b1-2": "L012_C002_",                                                // London night 1
        "b3-1": "L004_C011_",                                                // London night 2
        "A284F0BF-E690-4C13-92E2-4672D93E8DE5": "LA_A011_C003_",             // Los Angeles night 3
        "b7-2": "N008_C009_",                                                // New York day 1
        "b1-3": "N006_C003_",                                                // New York day 2
        "b3-2": "N003_C006_",                                                // New York day 3
        "b2-3": "N013_C004_",                                                // New York night 1
        "b4-2": "N008_C003_",                                                // New York night 2

        "b8-2": "A008_C007_",                                                // San Francisco day 1
        // "b10-3": ,                                               // San Francisco day 2
        "b9-3": "A006_C003_",                                                // San Francisco day 3
        //"b8-3":"",     San Francisco day 4 (no extra poi ?)
        "b3-3": "A012_C014_",                                                // San Francisco day 5
                                                                            //   maybe A013_C004 ?
        "b4-3": "A013_C005_",                                                // San Francisco day 6
        "b6-4": "A004_C012_",                                                // San Francisco night 1
        "b7-3": "A007_C017_",                                                // San Francisco night 2
        "b5-3": "A015_C014_",                                                // San Francisco night 3
        "b1-4": "A015_C018_",                                                // San Francisco night 4
        "b2-4": "A018_C014_",                                                 // San Francisco night 5
    ]

    // MARK: - Playlist generation
    func generatePlaylist(isRestricted: Bool, restrictedTo: String) {
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
        while playlist.count > 1 && lastPluckedFromPlaylist == playlist.first {
            playlist.shuffle()
        }
    }

    func randomVideo(excluding: [AerialVideo]) -> AerialVideo? {
        let timeManagement = TimeManagement.sharedInstance
        let (shouldRestrictByDayNight, restrictTo) = timeManagement.shouldRestrictPlaybackToDayNightVideo()
        debugLog("shouldRestrictByDayNight : \(shouldRestrictByDayNight) (\(restrictTo))")
        if playlist.isEmpty || restrictTo != playlistRestrictedTo || shouldRestrictByDayNight != playlistIsRestricted {
            generatePlaylist(isRestricted: shouldRestrictByDayNight, restrictedTo: restrictTo)
        }

        if !playlist.isEmpty {
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

        warnLog("Empty playlist, not good !")

        if lastPluckedFromPlaylist != nil {
            warnLog("returning last played video after condition change not met !")
            return lastPluckedFromPlaylist!
        } else {
            // Start with a shuffled list
            let shuffled = loadedManifest.shuffled()

            if shuffled.isEmpty {
                // This is super bad, no manifest at all
                errorLog("No manifest, nothing to play !")
                return nil
            }

            for video in shuffled {
                // We exclude videos not in rotation
                let inRotation = preferences.videoIsInRotation(videoID: video.id)

                // If we find anything cached and in rotation, we send that back
                if video.isAvailableOffline && inRotation {
                    warnLog("returning random cached in rotation video after condition change not met !")
                    return video
                }
            }
            // Nothing ? Sorry but you'll get a non cached file
            warnLog("returning random video after condition change not met !")
            return shuffled.first!
        }
    }

    // MARK: - Lifecycle

    init() {
        debugLog("Manifest init")
        // We try to load our video manifests in 3 steps :
        // - reload from local variables (unused for now)
        // - reprocess the saved files in cache directory (full offline mode)
        // - download the manifests from servers

        debugLog("isManifestCached 10 \(isManifestCached(manifest: .tvOS10))")
        debugLog("isManifestCached 11 \(isManifestCached(manifest: .tvOS11))")
        debugLog("isManifestCached 12 \(isManifestCached(manifest: .tvOS12))")

        if areManifestsFilesLoaded() {
            debugLog("Files were already loaded")
            loadManifestsFromLoadedFiles()
        } else {
            debugLog("Files were not already loaded")
            // Manifests are not in our preferences plist, are they cached on disk ?
            if areManifestsCached() {
                debugLog("Manifests are cached on disk, loading")
                loadCachedManifests()
            } else {
                // Ok then, we fetch them...
                debugLog("Fetching missing manifests online")
                let downloadManager = DownloadManager()

                var urls: [URL] = []

                // For tvOS12, json is now in a tar file
                if !isManifestCached(manifest: .tvOS12) {
                    urls.append(URL(string: "https://sylvan.apple.com/Aerials/resources.tar")!)
                }

                if !isManifestCached(manifest: .tvOS11) {
                    urls.append(URL(string: "https://sylvan.apple.com/Aerials/2x/entries.json")!)
                }

                if !isManifestCached(manifest: .tvOS10) {
                    urls.append(URL(string: "http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json")!)
                }

                let completion = BlockOperation {
                    debugLog("Fetching manifests all done")
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

    func addCallback(_ callback:@escaping ManifestLoadCallback) {
        if !loadedManifest.isEmpty {
            callback(loadedManifest)
        } else {
            callbacks.append(callback)
        }
    }

    // MARK: - Manifests

    // Check if the Manifests have been loaded in this class already
    func areManifestsFilesLoaded() -> Bool {
        if manifestTvOS12 != nil && manifestTvOS11 != nil && manifestTvOS10 != nil {
            debugLog("Manifests files were loaded in class")
            return true
        } else {
            debugLog("Manifests files were not loaded in class")
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
        } else {
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
                manifestTvOS12 = ndata
            } catch {
                errorLog("Can't load entries.json from cached directory (tvOS12)")
            }

            // tvOS11
            cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
            cacheFileUrl.appendPathComponent("tvos11.json")
            do {
                let ndata = try Data(contentsOf: cacheFileUrl)
                manifestTvOS11 = ndata
            } catch {
                errorLog("Can't load tvos11.json from cached directory")
            }

            // tvOS10
            cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
            cacheFileUrl.appendPathComponent("tvos10.json")
            do {
                let ndata = try Data(contentsOf: cacheFileUrl)
                manifestTvOS10 = ndata
            } catch {
                errorLog("Can't load tvos10.json from cached directory")
            }

            if manifestTvOS10 != nil || manifestTvOS11 != nil || manifestTvOS12 != nil {
                loadManifestsFromLoadedFiles()
            } else {
                // No internet, no anything, nothing to do
                errorLog("No video to load, no internet connexion ?")
            }
        }
    }

    // Load Manifests from the saved preferences
    func loadManifestsFromLoadedFiles() {
        // Reset our array
        processedVideos = []

        if manifestTvOS12 != nil {
            // We start with the more recent one, it has more information (poi, etc)
            readJSONFromData(manifestTvOS12!, manifest: .tvOS12)
        } else {
            warnLog("tvOS12 manifest is absent")
        }

        if manifestTvOS11 != nil {
            // This one has a couple videos not in the tvOS12 JSON. No H264 for these !
            readJSONFromData(manifestTvOS11!, manifest: .tvOS11)
        } else {
            warnLog("tvOS11 manifest is absent")
        }

        if manifestTvOS10 != nil {
            // The original manifest is in another format
            readOldJSONFromData(manifestTvOS10!, manifest: .tvOS10)
        } else {
            warnLog("tvOS10 manifest is absent")
        }

        // We sort videos by secondary names, so they can display sorted in our view later
        processedVideos = processedVideos.sorted { $0.secondaryName < $1.secondaryName }

        self.loadedManifest = processedVideos
        /*
         // POI Extracter code
        infoLog("\(processedVideos.count) videos processed !")
        let poiStringProvider = PoiStringProvider.sharedInstance
        for video in processedVideos {
            infoLog(video.name + " " + video.secondaryName)
            for poi in video.poi {
                infoLog(poi.key + ": " + poiStringProvider.getString(key: poi.value))
            }
        }*/

        // callbacks
        for callback in self.callbacks {
            callback(self.loadedManifest)
        }
        self.callbacks.removeAll()
    }

    // MARK: - JSON
    func readJSONFromData(_ data: Data, manifest: Manifests) {
        do {
            let poiStringProvider = PoiStringProvider.sharedInstance

            let options = JSONSerialization.ReadingOptions.allowFragments
            let batches = try JSONSerialization.jsonObject(with: data, options: options)

            guard let batch = batches as? NSDictionary else {
                errorLog("Encountered unexpected content type for batch, please report !")
                return
            }

            let assets = batch["assets"] as! [NSDictionary]

            for item in assets {
                let id = item["id"] as! String
                let url1080pH264 = item["url-1080-H264"] as? String
                let url1080pHEVC = item["url-1080-SDR"] as? String
                let url4KHEVC = item["url-4K-SDR"] as? String
                let name = item["accessibilityLabel"] as! String
                var secondaryName = ""
                // We may have a secondary name
                if let mergename = poiStringProvider.getCommunityName(id: id) {
                    secondaryName = mergename
                }
/*                if let mergeName = mergeName[id] {
                    secondaryName = mergeName
                }*/

                let timeOfDay = "day"   // TODO, this is hardcoded as it's no longer available in the modern JSONs
                let type = "video"
                var poi: [String: String]?
                if let mergeId = mergePOI[id] {
                    poi = poiStringProvider.fetchExtraPoiForId(id: mergeId)
                } else {
                    poi = item["pointsOfInterest"] as? [String: String]
                }

                let communityPoi = poiStringProvider.getCommunityPoi(id: id)

                let (isDupe, foundDupe) = findDuplicate(id: id, url1080pH264: url1080pH264 ?? "")
                if isDupe {
                    foundDupe!.sources.append(manifest)
                } else {
                    let video = AerialVideo(id: id,             // Must have
                        name: name,                             // Must have
                        secondaryName: secondaryName,           // Optional
                        type: type,                             // Not sure the point of this one ?
                        timeOfDay: timeOfDay,
                        url1080pH264: url1080pH264 ?? "",
                        url1080pHEVC: url1080pHEVC ?? "",
                        url4KHEVC: url4KHEVC ?? "",
                        manifest: manifest,
                        poi: poi ?? [:],
                        communityPoi: communityPoi)

                    processedVideos.append(video)
                }
            }
        } catch {
            errorLog("Error retrieving content listing")
            return
        }
    }

    func readOldJSONFromData(_ data: Data, manifest: Manifests) {
        do {
            let poiStringProvider = PoiStringProvider.sharedInstance

            let options = JSONSerialization.ReadingOptions.allowFragments
            let batches = try JSONSerialization.jsonObject(with: data,
                                                           options: options) as! [NSDictionary]

            for batch: NSDictionary in batches {
                let assets = batch["assets"] as! [NSDictionary]

                for item in assets {
                    let url = item["url"] as! String
                    let name = item["accessibilityLabel"] as! String
                    let timeOfDay = item["timeOfDay"] as! String
                    let id = item["id"] as! String
                    let type = item["type"] as! String

                    if type != "video" {
                        continue
                    }

                    // We may have a secondary name
                    var secondaryName = ""
                    if let mergename = poiStringProvider.getCommunityName(id: id) {
                        secondaryName = mergename
                    }

                    // We may have POIs to merge
                    var poi: [String: String]?
                    if let mergeId = mergePOI[id] {
                        let poiStringProvider = PoiStringProvider.sharedInstance
                        poi = poiStringProvider.fetchExtraPoiForId(id: mergeId)
                    }

                    let communityPoi = poiStringProvider.getCommunityPoi(id: id)

                    // We may have dupes...
                    let (isDupe, foundDupe) = findDuplicate(id: id, url1080pH264: url)
                    if isDupe {
                        if foundDupe != nil {
                            foundDupe!.sources.append(manifest)

                            if foundDupe?.url1080pH264 == "" {
                                foundDupe?.url1080pH264 = url
                            }
                        }
                    } else {
                        var url4khevc = ""
                        var url1080phevc = ""
                        // Check if we have some HEVC urls to merge
                        if let val = mergeInfo[id] {
                            url1080phevc = val["url-1080-SDR"]!
                            url4khevc = val["url-4K-SDR"]!
                        }

                        // Now we can finally add...
                        let video = AerialVideo(id: id,             // Must have
                            name: name,         // Must have
                            secondaryName: secondaryName,
                            type: type,         // Not sure the point of this one ?
                            timeOfDay: timeOfDay,
                            url1080pH264: url,
                            url1080pHEVC: url1080phevc,
                            url4KHEVC: url4khevc,
                            manifest: manifest,
                            poi: poi ?? [:],
                            communityPoi: communityPoi)

                        processedVideos.append(video)
                    }
                }
            }
        } catch {
            errorLog("Error retrieving content listing")
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
    func findDuplicate(id: String, url1080pH264: String) -> (Bool, AerialVideo?) {
        // We blacklist some duplicates
        if url1080pH264 != "" {
            if blacklist.contains((URL(string: url1080pH264)?.lastPathComponent)!) {
                return (true, nil)
            }
        }

        // We also have a Dictionary of duplicates that need source merging
        for (pid, replace) in dupePairs where id == pid {
            for vid in processedVideos where vid.id == replace {
                return (true, vid)
            }
        }

        for video in processedVideos {
            if id == video.id {
                return (true, video)
            } else if url1080pH264 != "" && video.url1080pH264 != "" {
                if URL(string: url1080pH264)?.lastPathComponent == URL(string: video.url1080pH264)?.lastPathComponent {
                    return (true, video)
                }
            }
        }

        return (false, nil)
    }
}
