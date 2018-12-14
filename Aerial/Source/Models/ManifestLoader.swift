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
    // This is used to dedupe old versions of videos
    // old : new
    let dupePairs = [
        "A2BE2E4A-AD4B-428A-9C41-BDAE1E78E816": "12318CCB-3F78-43B7-A854-EFDCCE5312CD",     // California to Vegas (v7 -> v8)
        "6A74D52E-2447-4B84-AE45-0DEF2836C3CC": "7825C73A-658F-48EE-B14C-EC56673094AC",     // China
        "6C3D54AE-0871-498A-81D0-56ED24E5FE9F": "009BA758-7060-4479-8EE8-FB9B40C8FB97",     // Korean and Japan night
        "b5-1": "044AD56C-A107-41B2-90CC-E60CCACFBCF5",                                     // Great Wall 3
        "b2-1": "22162A9B-DB90-4517-867C-C676BC3E8E95",                                     // Great wall 2
        "b6-1": "F0236EC5-EE72-4058-A6CE-1F7D2E8253BF",                                     // Great wall 1
        "BAF76353-3475-4855-B7E1-CE96CC9BC3A7": "9680B8EB-CE2A-4395-AF41-402801F4D6A6",     // Approaching Burj Khalifa (night)
        "B3BDC635-756D-4B82-B01A-A2620D1DBF10": "9680B8EB-CE2A-4395-AF41-402801F4D6A6",     // Approaching Burj Khalifa (night)
        "15F9B681-9EA8-4DD1-AD26-F111BC5CF64B": "E991AC0C-F272-44D8-88F3-05F44EDFE3AE",     // Marina 1
        "49790B7C-7D8C-466C-A09E-83E38B6BE87A": "E991AC0C-F272-44D8-88F3-05F44EDFE3AE",     // Marina 1
        "802866E6-4AAF-4A69-96EA-C582651391F1": "3FFA2A97-7D28-49EA-AA39-5BC9051B2745",     // Marina 2
        "D34A7B19-EC33-4300-B4ED-0C8BC494C035": "3FFA2A97-7D28-49EA-AA39-5BC9051B2745",     // Marina 2
        "02EA5DBE-3A67-4DFA-8528-12901DFD6CC1": "00BA71CD-2C54-415A-A68A-8358E677D750",     // Downtown
        "D388F00A-5A32-4431-A95C-38BF7FF7268D": "B8F204CE-6024-49AB-85F9-7CA2F6DCD226",     // Nuusuaq Peninsula
        "E4ED0B22-EB81-4D4F-A29E-7E1EA6B6D980": "B8F204CE-6024-49AB-85F9-7CA2F6DCD226",     // Nuusuaq Peninsula
        "30047FDA-3AE3-4E74-9575-3520AD77865B": "2F52E34C-39D4-4AB1-9025-8F7141FAA720",     // Ilulissat Icefjord day
        "7D4710EB-5BA4-42E6-AA60-68D77F67D9B9": "EE01F02D-1413-436C-AB05-410F224A5B7B",     // Ilulissat Icefjord Night
        "b8-1": "82BD33C9-B6D2-47E7-9C42-AA3B7758921A",                                     // Pu'u O 'Umi Night
        "b4-1": "258A6797-CC13-4C3A-AB35-4F25CA3BF474",                                     // Pu'u O 'Umi day
        "b1-1": "12E0343D-2CD9-48EA-AB57-4D680FB6D0C7",                                     // Waimanu Valley
        "b7-1": "499995FA-E51A-4ACE-8DFD-BDF8AFF6C943",                                     // Laupāhoehoe Nui
        "b6-2": "3D729CFC-9000-48D3-A052-C5BD5B7A6842",                                     // Kohala coastline
        "30313BC1-BF20-45EB-A7B1-5A6FFDBD2488": "E99FA658-A59A-4A2D-9F3B-58E7BDC71A9A",     // Hong Kong Victoria Harbour night
        "2A57BB93-1825-484C-9609-FF8580CAE77B": "E99FA658-A59A-4A2D-9F3B-58E7BDC71A9A",     // Hong Kong Victoria Harbour night
        "102C19D1-9D9F-48EC-B492-074C985C4D9F": "FE8E1F9D-59BA-4207-B626-28E34D810D0A",     // Hong Kong Victoria Harbour 1
        "786E674C-BB22-4AA9-9BD3-114D2020EC4D": "64EA30BD-C4B5-4CDD-86D7-DFE47E9CB9AA",     // Hong Kong Victoria Harbour 2
        "560E09E8-E89D-4ADB-8EEA-4754415383D4": "C8559883-6F3E-4AF2-8960-903710CD47B7",     // Hong Kong Victoria Peak
        "6E2FC8AC-832D-46CF-B306-BB2A05030C17": "001C94AE-2BA4-4E77-A202-F7DE60E8B1C8",     // Liwa oasis 1
        "88025454-6D58-48E8-A2DB-924988FAD7AC": "001C94AE-2BA4-4E77-A202-F7DE60E8B1C8",     // Liwa oasis 1
        "b6-3": "58754319-8709-4AB0-8674-B34F04E7FFE2",                                     // River Thames
        "b1-2": "F604AF56-EA77-4960-AEF7-82533CC1A8B3",                                     // River Thames near sunset
        "b3-1": "7F4C26C2-67C2-4C3A-8F07-8A7BF6148C97",                                     // River Times at Dusk
        "b5-2": "A5AAFF5D-8887-42BB-8AFD-867EF557ED85",                                     // Buckingham Palace
        "BEED64EC-2DB7-47E1-A67E-59C101E73C04": "CE279831-1CA7-4A83-A97B-FF1E20234396",     // LAX
        "829E69BA-BB53-4841-A138-4DF0C2A74236": "CE279831-1CA7-4A83-A97B-FF1E20234396",     // LAX
        "60CD8E2E-35CD-4192-A5A4-D5E10BFE158B": "92E48DE9-13A1-4172-B560-29B4668A87EE",     // Santa Monica Beach
        "B730433D-1B3B-4B99-9500-A286BF7A9940": "92E48DE9-13A1-4172-B560-29B4668A87EE",     // Santa Monica Beach
        "30A2A488-E708-42E7-9A90-B749A407AE1C": "35693AEA-F8C4-4A80-B77D-C94B20A68956",     // Harbor Freeway
        "A284F0BF-E690-4C13-92E2-4672D93E8DE5": "F5804DD6-5963-40DA-9FA0-39C0C6E6DEF9",     // Downtown
        "b3-2": "840FE8E4-D952-4680-B1A7-AC5BACA2C1F8",                                     // Upper East side
        "b4-2": "640DFB00-FBB9-45DA-9444-9F663859F4BC",                                     // Lower Manhattan (night)
        "b2-3": "44166C39-8566-4ECA-BD16-43159429B52F",                                     // Seventh Avenue
        "b7-2": "3BA0CFC7-E460-4B59-A817-B97F9EBB9B89",                                     // Central Park
        "b10-3": "EE533FBD-90AE-419A-AD13-D7A60E2015D6",                                    // Marin Headlands in Fog
        "b1-4": "3E94AE98-EAF2-4B09-96E3-452F46BC114E",                                     // Bay bridge night
        "b9-3": "DE851E6D-C2BE-4D9F-AB54-0F9CE994DC51",                                     // Bay and Golden Bridge
        "b7-3": "29BDF297-EB43-403A-8719-A78DA11A2948",                                     // Fisherman's Wharf
    ]

    // Extra info to be merged for a given ID, as of right now only one known video
    let mergeInfo = [
        "2F11E857-4F77-4476-8033-4A1E4610AFCC":
            ["url-1080-SDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_2K_SDR_HEVC.mov",
             "url-4K-SDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_4K_SDR_HEVC.mov", ],    // Dubai night 2
    ]

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
        // - reload from local variables (unused for now, maybe with previews+screensaver
        // in some weird edge case on some systems)
        // - reprocess the saved files in cache directory (full offline mode)
        // - download the manifests from servers
        //
        // Starting with 1.4.6, we also may now periodically recheck for changed files!

        debugLog("isManifestCached 10 \(isManifestCached(manifest: .tvOS10))")
        debugLog("isManifestCached 11 \(isManifestCached(manifest: .tvOS11))")
        debugLog("isManifestCached 12 \(isManifestCached(manifest: .tvOS12))")

        checkIfShouldRedownloadFiles()

        if areManifestsFilesLoaded() {
            debugLog("Files were already loaded in memory")
            loadManifestsFromLoadedFiles()
        } else {
            debugLog("Files were not already loaded in memory")
            // Manifests are not in our preferences plist, are they cached on disk ?
            if areManifestsCached() {
                debugLog("Manifests are cached on disk, loading")
                loadCachedManifests()
            } else {
                // Ok then, we fetch them...
                debugLog("Fetching missing manifests online")
                let dateFormatter = DateFormatter()
                let current = Date()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                preferences.lastVideoCheck = dateFormatter.string(from: current)

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

    func reloadFiles() {
        moveOldManifests()

        // Ok then, we fetch them...
        debugLog("Fetching missing manifests online")
        let dateFormatter = DateFormatter()
        let current = Date()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        preferences.lastVideoCheck = dateFormatter.string(from: current)

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

    func addCallback(_ callback:@escaping ManifestLoadCallback) {
        if !loadedManifest.isEmpty {
            callback(loadedManifest)
        } else {
            callbacks.append(callback)
        }
    }

    // MARK: - Periodically check for new videos
    func checkIfShouldRedownloadFiles() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale.init(identifier: "en_GB")
        let dateObj = dateFormatter.date(from: preferences.lastVideoCheck!)

        debugLog(preferences.lastVideoCheck!)
        var dayCheck = 7
        if preferences.newVideosMode == Preferences.NewVideosMode.monthly.rawValue {
            dayCheck = 30
        }

        let cacheDirectory = VideoCache.cacheDirectory!
        var cacheResourcesString = cacheDirectory
        cacheResourcesString.append(contentsOf: "/backups")
        let cacheUrl = URL(fileURLWithPath: cacheResourcesString)

        if #available(OSX 10.11, *) {
            if !cacheUrl.hasDirectoryPath {
                // If there's no backup directory, we force the first check
                moveOldManifests()
                return
            }
        } else {
            // Fallback on earlier versions
        }

        debugLog("Interval : \(String(describing: dateObj?.timeIntervalSinceNow))")
        if Int((dateObj?.timeIntervalSinceNow)!) < -dayCheck * 86400 {
            // We need to redownload then
            debugLog("Checking for new videos")
            moveOldManifests()
        } else {
            debugLog("No need to check for new videos")
        }
    }

    func moveOldManifests() {
        debugLog("move")
        let cacheDirectory = VideoCache.cacheDirectory!
        var cacheResourcesString = cacheDirectory

        let dateFormatter = DateFormatter()
        let current = Date()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: current)

        cacheResourcesString.append(contentsOf: "/backups/"+today)
        let previous = URL(fileURLWithPath: cacheDirectory.appending("/entries.json"))
        if FileManager.default.fileExists(atPath: cacheDirectory.appending("/entries.json")) {
            let new = URL(fileURLWithPath: cacheResourcesString.appending("/entries.json"))

            let cacheUrl = URL(fileURLWithPath: cacheResourcesString)
            if #available(OSX 10.11, *) {
                if !cacheUrl.hasDirectoryPath {
                    do {
                        try FileManager.default.createDirectory(atPath: cacheResourcesString, withIntermediateDirectories: true, attributes: nil)
                        debugLog("creating dir \(cacheResourcesString)")

                        try FileManager.default.moveItem(at: previous, to: new)
                        debugLog("moving entries.json")
                    } catch {
                        errorLog("\(error.localizedDescription)")
                    }
                }
            }
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

            // We also need to add the missing videos
            let bundlePath = Bundle(for: ManifestLoader.self).path(forResource: "missingvideos", ofType: "json")!
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: bundlePath), options: .mappedIfSafe)
                readJSONFromData(data, manifest: .tvOS12)
            } catch {
                errorLog("missingvideos.json was not found in the bundle")
            }
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

        debugLog("Total videos processed : \(processedVideos.count)")
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
                // Found dupe pair
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

    // MARK: - Old video management
    // Try to estimate how many old (unlinked) files we have
    // swiftlint:disable:next cyclomatic_complexity
    func getOldFilesEstimation() -> (String, Int) {
        // loadedManifests contains the full deduplicated list of videos
        debugLog("Looking for outdated files")

        if loadedManifest.isEmpty {
            warnLog("We have no videos in the manifest")
            return ("Can't estimate duplicates", 0)
        }
        guard let cacheDirectory = VideoCache.cacheDirectory else {
            warnLog("No cache directory")
            return ("Can't estimate duplicates", 0)
        }

        var foundOldFiles = 0

        let cacheDirectoryUrl = URL(fileURLWithPath: cacheDirectory as String)
        let fileManager = FileManager.default
        do {
            let directoryContent = try fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil)
            let videoFileURLs = directoryContent.filter { $0.pathExtension == "mov" }

            // We check the 3 fields
            for fileURL in videoFileURLs {
                var found = false
                for video in loadedManifest {
                    if video.url1080pH264 != "" {
                        if fileURL.lastPathComponent == URL(string: video.url1080pH264)?.lastPathComponent {
                            found = true
                            break
                        }
                    }
                    if video.url1080pHEVC != "" {
                        if fileURL.lastPathComponent == URL(string: video.url1080pHEVC)?.lastPathComponent {
                            found = true
                            break
                        }
                    }
                    if video.url4KHEVC != "" {
                        if fileURL.lastPathComponent == URL(string: video.url4KHEVC)?.lastPathComponent {
                            found = true
                            break
                        }
                    }
                }

                if !found {
                    debugLog("\(fileURL.lastPathComponent) NOT FOUND in manifest")
                    foundOldFiles += 1
                }
            }
        } catch {
            errorLog("Error while enumerating files \(cacheDirectoryUrl.path): \(error.localizedDescription)")
        }

        if foundOldFiles == 0 {
            debugLog("No old files found")
            return ("No old files found", 0)
        }
        debugLog("\(foundOldFiles) old files found")
        return ("\(foundOldFiles) old files found", foundOldFiles)
    }

    // swiftlint:disable:next cyclomatic_complexity
    func moveOldVideos() {
        debugLog("move old videos")
        let cacheDirectory = VideoCache.cacheDirectory!
        var cacheResourcesString = cacheDirectory

        let dateFormatter = DateFormatter()
        let current = Date()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: current)

        cacheResourcesString.append(contentsOf: "/oldvideos/"+today)

        let cacheUrl = URL(fileURLWithPath: cacheResourcesString)
        if #available(OSX 10.11, *) {
            if !cacheUrl.hasDirectoryPath {
                do {
                    try FileManager.default.createDirectory(atPath: cacheResourcesString, withIntermediateDirectories: true, attributes: nil)
                    debugLog("creating dir \(cacheResourcesString)")
                } catch {
                    errorLog("\(error.localizedDescription)")
                }
            }
        }

        if loadedManifest.isEmpty {
            warnLog("We have no videos in the manifest")
            return
        }

        let cacheDirectoryUrl = URL(fileURLWithPath: cacheDirectory as String)
        let fileManager = FileManager.default
        do {
            let directoryContent = try fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil)
            let videoFileURLs = directoryContent.filter { $0.pathExtension == "mov" }

            // We check the 3 fields
            for fileURL in videoFileURLs {
                var found = false
                for video in loadedManifest {
                    if video.url1080pH264 != "" {
                        if fileURL.lastPathComponent == URL(string: video.url1080pH264)?.lastPathComponent {
                            found = true
                            break
                        }
                    }
                    if video.url1080pHEVC != "" {
                        if fileURL.lastPathComponent == URL(string: video.url1080pHEVC)?.lastPathComponent {
                            found = true
                            break
                        }
                    }
                    if video.url4KHEVC != "" {
                        if fileURL.lastPathComponent == URL(string: video.url4KHEVC)?.lastPathComponent {
                            found = true
                            break
                        }
                    }
                }

                if !found {
                    do {
                        debugLog("moving \(fileURL.lastPathComponent)")
                        let new = URL(fileURLWithPath: cacheResourcesString.appending("/\(fileURL.lastPathComponent)"))
                        try FileManager.default.moveItem(at: fileURL, to: new)
                    } catch {
                        errorLog("\(error.localizedDescription)")
                    }
                }
            }
        } catch {
            errorLog("Error while enumerating files \(cacheDirectoryUrl.path): \(error.localizedDescription)")
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func trashOldVideos() {
        debugLog("trash old videos")
        let cacheDirectory = VideoCache.cacheDirectory!
        var cacheResourcesString = cacheDirectory

        let dateFormatter = DateFormatter()
        let current = Date()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: current)

        cacheResourcesString.append(contentsOf: "/oldvideos/"+today)

        let cacheUrl = URL(fileURLWithPath: cacheResourcesString)
        if #available(OSX 10.11, *) {
            if !cacheUrl.hasDirectoryPath {
                do {
                    try FileManager.default.createDirectory(atPath: cacheResourcesString, withIntermediateDirectories: true, attributes: nil)
                    debugLog("creating dir \(cacheResourcesString)")
                } catch {
                    errorLog("\(error.localizedDescription)")
                }
            }
        }

        if loadedManifest.isEmpty {
            warnLog("We have no videos in the manifest")
            return
        }

        let cacheDirectoryUrl = URL(fileURLWithPath: cacheDirectory as String)
        let fileManager = FileManager.default
        do {
            let directoryContent = try fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil)
            let videoFileURLs = directoryContent.filter { $0.pathExtension == "mov" }

            // We check the 3 fields
            for fileURL in videoFileURLs {
                var found = false
                for video in loadedManifest {
                    if video.url1080pH264 != "" {
                        if fileURL.lastPathComponent == URL(string: video.url1080pH264)?.lastPathComponent {
                            found = true
                            break
                        }
                    }
                    if video.url1080pHEVC != "" {
                        if fileURL.lastPathComponent == URL(string: video.url1080pHEVC)?.lastPathComponent {
                            found = true
                            break
                        }
                    }
                    if video.url4KHEVC != "" {
                        if fileURL.lastPathComponent == URL(string: video.url4KHEVC)?.lastPathComponent {
                            found = true
                            break
                        }
                    }
                }

                if !found {
                    debugLog("trashing \(fileURL.lastPathComponent)")

                    NSWorkspace.shared.recycle([fileURL]) { trashedFiles, error in
                        for file in [fileURL] where trashedFiles[file] == nil {
                            errorLog("\(file.relativePath) could not be moved to trash \(error!.localizedDescription)")
                        }
                    }
                }
            }
        } catch {
            errorLog("Error while enumerating files \(cacheDirectoryUrl.path): \(error.localizedDescription)")
        }
    }

} //swiftlint:disable:this file_length
