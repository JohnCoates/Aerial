//
//  Cache.swift
//  Aerial
//
//  Created by Guillaume Louel on 06/06/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import CoreWLAN
import AVKit

/**
 Aerial's new Cache management
 
 Everything Cache related is moved here.
 
 - Note: Where is our cache ?
 
 Starting with 2.0, Aerial is putting its files in two locations :
 - `~/Library/Application Support/Aerial/` : Contains manifests files and strings bundles for each source, in their own directory
 - `~/Library/Application Support/Aerial/Cache/` : Contains (only) the cached videos
 
 Users of version 1.x.x will automatically see their video files migrated to the correct location.
 
 In Catalina, those paths live inside a user's container :
 `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application Support/`
 
 - Attention: Shared by multiple users writable locations are no longer possible, because sandboxing is awesome !
 */

// swiftlint:disable:next type_body_length
struct Cache {
    /**
     Returns the SSID of the Wi-Fi network the user is currently connected to.
     - Note: Returns an empty string if not connected to Wi-Fi
     */
    static var ssid: String {
        return CWWiFiClient.shared().interface(withName: nil)?.ssid() ?? ""
    }

    static var processedSupportPath = ""

    /**
     Returns Aerial's Application Support path.
     
     + On macOS 10.14 and earlier : `~/Library/Application Support/Aerial/`
     + Starting with 10.15 : `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application Support/Aerial/`
     
     - Note: Returns `/` on failure.
     
     In some rare instances those system folders may not exist in the container, in this case Aerial can't work.
     */
    static var supportPath: String {
        // Dont' redo the thing all the time
        if processedSupportPath != "" {
            return processedSupportPath
        }

        var appPath = ""

        if PrefsCache.overrideCache {
            debugLog("Cache Override")
            if #available(macOS 12, *) {
                if let bookmarkData = PrefsCache.supportBookmarkData {
                    do {
                        var isStale = false
                        let bookmarkUrl = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)

                        debugLog("Bookmark is stale : \(isStale)")
                        debugLog("\(bookmarkUrl)")
                        appPath = bookmarkUrl.path
                        debugLog("\(appPath)")
                    } catch {
                        errorLog("Can't process bookmark")
                    }
                } else {
                    errorLog("Can't find supportBookmarkData on macOS 12")
                }
            } else {
                if let customPath = PrefsCache.supportPath {
                    debugLog("Trying \(customPath)")
                    if FileManager.default.fileExists(atPath: customPath) {
                        appPath = customPath
                    } else {
                        errorLog("Could not find your custom Caches path, reverting to default settings")
                    }
                } else {
                    errorLog("Empty path, reverting to default settings")
                }
            }
        }

        // This is the normal path
        if appPath == "" {
            // Grab an array of Application Support paths
            let appSupportPaths = NSSearchPathForDirectoriesInDomains(
                .applicationSupportDirectory,
                .userDomainMask,
                true)

            if appSupportPaths.isEmpty {
                errorLog("FATAL : app support does not exist!")
                return "/"
            }

            appPath = appSupportPaths[0]
        }

        let appSupportDirectory = appPath as NSString

        if aerialFolderExists(at: appSupportDirectory) {
            processedSupportPath = appSupportDirectory.appendingPathComponent("Aerial")
            return processedSupportPath
        } else {
            debugLog("Creating app support directory...")
            let asPath = appSupportDirectory.appendingPathComponent("Aerial")

            let fileManager = FileManager.default
            do {
                try fileManager.createDirectory(atPath: asPath,
                                                withIntermediateDirectories: true, attributes: nil)

                processedSupportPath = asPath
                return asPath
            } catch let error {
                errorLog("FATAL : Couldn't create app support directory in User directory: \(error)")
                return "/"
            }
        }
    }

    /**
     Returns Aerial's Caches path.
     
     + On macOS 10.14 and earlier : `~/Library/Application Support/Aerial/Cache/`
     + Starting with 10.15 : `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application Support/Aerial/Cache/`
     
     - Note: Returns `/` on failure.
     
     In some rare instances those system folders may not exist in the container, in this case Aerial can't work.
     
     Also note that the shared `Caches` folder, `/Library/Caches/Aerial/`, is no longer user writable in Catalina and will be ignored.
     */
    static var path: String = {
        var path = ""
        /*if PrefsCache.overrideCache {
            if #available(macOS 12, *) {
                if let bookmarkData = PrefsCache.cacheBookmarkData {
                    do {
                        var isStale = false
                        let bookmarkUrl = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)

                        debugLog("Bookmark is stale : \(isStale)")
                        debugLog("\(bookmarkUrl)")
                        path = bookmarkUrl.path
                        debugLog("\(path)")
                    } catch {
                        errorLog("Can't process bookmark")
                    }
                } else {
                    errorLog("Can't find cacheBookmarkData on macOS 12")
                }
            } else {
                if let customPath = Preferences.sharedInstance.customCacheDirectory {
                    debugLog("Trying \(customPath)")
                    if FileManager.default.fileExists(atPath: customPath) {
                        path = customPath
                    } else {
                        errorLog("Could not find your custom Caches path, reverting to default settings")
                    }
                } else {
                    errorLog("Empty path, reverting to default settings")

                }
            }

            if path == "" {
                PrefsCache.overrideCache = false
                path = Cache.supportPath.appending("/Cache")
            }
        } else {*/

        path = Cache.supportPath.appending("/Cache")
        // }

        if FileManager.default.fileExists(atPath: path as String) {
            return path
        } else {
            do {
                try FileManager.default.createDirectory(atPath: path,
                                                withIntermediateDirectories: true, attributes: nil)
                return path
            } catch let error {
                errorLog("FATAL : Couldn't create Cache directory in Aerial's AppSupport directory: \(error)")
                return "/"
            }
        }
    }()

    static var pathUrl: URL = {
        if #available(macOS 12, *) {
            if PrefsCache.overrideCache {
                if let bookmarkData = PrefsCache.cacheBookmarkData {
                    do {
                        var isStale = false
                        let bookmarkUrl = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                        debugLog("Bookmark is stale : \(isStale)")
                        debugLog("\(bookmarkUrl)")
                        return bookmarkUrl
                    } catch {
                        errorLog("Can't process bookmark")
                    }
                }
            }
        }

        return URL(fileURLWithPath: path)
    }()
    /**
     Returns Aerial's thumbnail cache path, creating it if needed.
     + On macOS 10.14 and earlier : `~/Library/Application Support/Aerial/Thumbnails/`
     + Starting with 10.15 : `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application Support/Aerial/Thumbnails/`

     - Note: Returns `/` on failure.

     */
    static var thumbnailsPath: String = {
        let path = Cache.supportPath.appending("/Thumbnails")

        if FileManager.default.fileExists(atPath: path as String) {
            return path
        } else {
            do {
                try FileManager.default.createDirectory(atPath: path,
                                                withIntermediateDirectories: true, attributes: nil)
                return path
            } catch let error {
                errorLog("FATAL : Couldn't create Thumbnails directory in Aerial's AppSupport directory: \(error)")
                return "/"
            }
        }
    }()

    /**
     Returns Aerial's former cache path, if it exists.
     
     + On macOS 10.14 and earlier : `~/Library/Caches/Aerial/`
     + Starting with 10.15 : `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Caches/Aerial/`
     
     - Note: Returns `nil` on failure.
    */
    static private var formerCachePath: String? = {
        // Grab an array of Cache paths
        let cacheSupportPaths = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory,
            .userDomainMask,
            true)

        if cacheSupportPaths.isEmpty {
            errorLog("Couldn't find Caches paths!")
            return nil
        }

        let cacheSupportDirectory = cacheSupportPaths[0] as NSString
        if aerialFolderExists(at: cacheSupportDirectory) {
            return cacheSupportDirectory.appendingPathComponent("Aerial")
        } else {
            do {
                debugLog("trying to create \(cacheSupportDirectory.appendingPathComponent("Aerial"))")
                try FileManager.default.createDirectory(atPath: cacheSupportDirectory.appendingPathComponent("Aerial"),
                                                withIntermediateDirectories: false, attributes: nil)
                return path
            } catch {
                errorLog("Could not create Aerial's Caches path")
            }
            return nil
        }
    }()

    // MARK: - Migration from Aerial 1.x.x to 2.x.x
    /**
     Migrate files from previous versions of Aerial to the 2.x.x structure.
     
     - Moves the video files from Application Support to the `Application Support/Aerial/Cache` sub directory.
     - Moves the video files from Caches to the `Application Support/Aerial/Cache` sub directory
     */
    static func migrate() {
        if !PrefsCache.overrideCache {
            migrateAppSupport()
            migrateOldCache()
        }
    }

    /**
     Migrate video that may be at the root of /Application Support/Aerial/
     */
    static private func migrateAppSupport() {
        let supportURL = URL(fileURLWithPath: supportPath as String)
        do {
            let directoryContent = try FileManager.default.contentsOfDirectory(at: supportURL, includingPropertiesForKeys: nil)
            let videoURLs = directoryContent.filter { $0.pathExtension == "mov" }

            if !videoURLs.isEmpty {
                debugLog("Starting migration of your video files from Application Support to the /Cache subfolder")
                for videoURL in videoURLs {
                    debugLog("moving \(videoURL.lastPathComponent)")
                    let newURL = URL(fileURLWithPath: path.appending("/\(videoURL.lastPathComponent)"))
                    try FileManager.default.moveItem(at: videoURL, to: newURL)
                }
                debugLog("Migration done.")
            }
        } catch {
            errorLog("Error during migration, please report")
            errorLog(error.localizedDescription)
        }
    }

    /**
     Migrate video that may be at the root of a user's /Caches/Aerial/
     */
    static private func migrateOldCache() {
        if let formerCachePath = formerCachePath {
            do {
                let formerCacheURL = URL(fileURLWithPath: formerCachePath as String)

                let directoryContent = try FileManager.default.contentsOfDirectory(at: formerCacheURL, includingPropertiesForKeys: nil)
                let videoURLs = directoryContent.filter { $0.pathExtension == "mov" }

                if !videoURLs.isEmpty {
                    debugLog("Starting migration of your video files from Caches to the /Cache subfolder of Application Support")
                    for videoURL in videoURLs {
                        debugLog("moving \(videoURL.lastPathComponent)")
                        let newURL = URL(fileURLWithPath: path.appending("/\(videoURL.lastPathComponent)"))
                        try FileManager.default.moveItem(at: videoURL, to: newURL)
                    }
                    debugLog("Migration done.")
                }
            } catch {
                errorLog("Error during migration, please report")
                errorLog(error.localizedDescription)
            }
        }
    }

    // Remove files in bad format or outdated
    static func removeCruft() {
        // TODO: kind of a temporary safety
        if VideoList.instance.videos.count > 90 {
            // First let's look at the cache

            // let pathURL = URL(fileURLWithPath: path)
            do {
                pathUrl.startAccessingSecurityScopedResource()

                let directoryContent = try FileManager.default.contentsOfDirectory(at: pathUrl, includingPropertiesForKeys: nil)
                debugLog("count : \(directoryContent.count)")
                let videoURLs = directoryContent.filter { $0.pathExtension == "mov" }

                for video in videoURLs {
                    let filename = video.lastPathComponent
                    debugLog("\(filename)")
                    var found = false

                    // swiftlint:disable for_where
                    for candidate in VideoList.instance.videos {
                        if candidate.url.lastPathComponent == filename {
                            found = true
                        }
                    }

                    if !found {
                        debugLog("This file is not in the correct format or outdated, removing : \(video)")
                        try? FileManager.default.removeItem(at: video)
                    }
                }

                pathUrl.stopAccessingSecurityScopedResource()
            } catch {
                errorLog("Error during removing of videos in wrong format, please report")
                errorLog(error.localizedDescription)
            }

            // Also remove uncached cruft
            removeUncachedCruft()
        }
    }

    static func removeUncachedCruft() {
        for source in SourceList.foundSources where !source.isCachable && source.type != .local {
            debugLog("Checking cruft in \(source.name)")

            let pathURL = URL(fileURLWithPath: supportPath.appending("/" + source.name))

            let unprocessed = source.getUnprocessedVideos()
            debugLog(pathURL.absoluteString)

            do {
                let directoryContent = try FileManager.default.contentsOfDirectory(at: pathURL, includingPropertiesForKeys: nil)
                let videoURLs = directoryContent.filter { $0.pathExtension == "mov" }

                for video in videoURLs {
                    let filename = video.lastPathComponent
                    var found = false

                    // swiftlint:disable for_where

                    for candidate in unprocessed {
                        if candidate.url.lastPathComponent == filename {
                            found = true
                        }
                    }

                    if !found {
                        debugLog("This file is not in the correct format or outdated, removing : \(video)")
                        try? FileManager.default.removeItem(at: video)
                    }
                }
            } catch {
                errorLog("Error during removal of videos in wrong format, please report")
                errorLog(error.localizedDescription)
            }
        }
    }

    /// This clears the whole cache. User beware !
    static func clearCache() {
        let pathURL = URL(fileURLWithPath: path)
        do {
            let directoryContent = try FileManager.default.contentsOfDirectory(at: pathURL, includingPropertiesForKeys: nil)
            let videoURLs = directoryContent.filter { $0.pathExtension == "mov" }

            for video in videoURLs {
                try? FileManager.default.removeItem(at: video)
            }
        } catch {
            errorLog("Error during removal of videos in wrong format, please report")
            errorLog(error.localizedDescription)
        }
    }

    static func clearNonCacheableSources() {
        // Then we need to look at individual online sources
        // let onlineVideos = VideoList.instance.videos.filter({ !$0.source.isCachable })

        for source in SourceList.foundSources.filter({!$0.isCachable}) {
            let pathSource = URL(fileURLWithPath: supportPath).appendingPathComponent(source.name)
            if FileManager.default.fileExists(atPath: pathSource.path) {
                do {
                    let directoryContent = try FileManager.default.contentsOfDirectory(at: pathSource, includingPropertiesForKeys: nil)

                    let videoURLs = directoryContent.filter { $0.pathExtension == "mov" }

                    for video in videoURLs {
                        debugLog("Removing file : \(video)")
                        try? FileManager.default.removeItem(at: video)
                    }

                } catch {
                    errorLog("Error during removing of videos in wrong format, please report")
                    errorLog(error.localizedDescription)
                }
            }
        }

    }

    // MARK: - About the cache
    /**
     Is our cache full ?
     */
    static func isFull() -> Bool {
        return size() > PrefsCache.cacheLimit
    }

    /**
     Do we still have a bit of free space (0.5 GB)
     */
    static func hasSomeFreeSpace() -> Bool {
        return size() < PrefsCache.cacheLimit - 0.5
    }

    /**
     Returns the cache size in GB as a string (eg. 5.1 GB)
     */
    static func sizeString() -> String {
        let pathURL = Foundation.URL(fileURLWithPath: path)

        // check if the url is a directory
        if (try? pathURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            var folderSize = 0
            (FileManager.default.enumerator(at: pathURL, includingPropertiesForKeys: nil)?.allObjects as? [URL])?.lazy.forEach {
                folderSize += (try? $0.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0
            }
            let byteCountFormatter =  ByteCountFormatter()
            byteCountFormatter.allowedUnits = .useGB
            byteCountFormatter.countStyle = .file
            let sizeToDisplay = byteCountFormatter.string(for: folderSize) ?? ""
            return sizeToDisplay
        }

        // In case it fails somehow
        return "No cache found"
    }

    // MARK: - Helpers
    /**
     Does an `/Aerial/` subfolder exist inside the given path
     - parameter at: Source path
     - returns: Path existance as a Bool.
     */
    private static func aerialFolderExists(at: NSString) -> Bool {
        let aerialFolder = at.appendingPathComponent("Aerial")
        return FileManager.default.fileExists(atPath: aerialFolder as String)
    }

    /**
     Returns cache size in GB
     */
    static func size() -> Double {
        let pathURL = URL(fileURLWithPath: path)

        // check if the url is a directory
        if (try? pathURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            var folderSize = 0
            (FileManager.default.enumerator(at: pathURL, includingPropertiesForKeys: nil)?.allObjects as? [URL])?.lazy.forEach {
                folderSize += (try? $0.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0
            }

            return Double(folderSize) / 1000000000
        }

        return 0
    }

    static func getDirectorySize(directory: String) -> Double {
        if FileManager.default.fileExists(atPath: directory) {
            let pathURL = URL(fileURLWithPath: directory)

            // check if the url is a directory
            if (try? pathURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                var folderSize = 0
                (FileManager.default.enumerator(at: pathURL, includingPropertiesForKeys: nil)?.allObjects as? [URL])?.lazy.forEach {
                    folderSize += (try? $0.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0
                }

                return Double(folderSize) / 1000000000
            }

            return 0
        } else {
            return 0
        }
    }

    static func packsSize() -> Double {
        var totalSize: Double = 0
        for source in SourceList.foundSources where !source.isCachable {
            let sourcePath = supportPath.appending("/" + source.name)
            totalSize += getDirectorySize(directory: sourcePath)
        }

        return totalSize
    }

    // swiftlint:disable line_length
    // MARK: Networking restrictions for cache
    /**
     Can we download a file ?
     
     Depending on user's settings, the cache may be full or the user may not be on a trusted network.
     - Note: If a user disabled cache management (full manual mode), this will always be true.
     - parameter action: A closure with the action to be accomplished should the conditions be met.
     */
    static func ensureDownload(action: @escaping () -> Void) {
        // Do we manage the cache or not ?
        if PrefsCache.enableManagement {
            // Check network first
            if !canNetwork() {
                if !Aerial.showAlert(question: "You are on a restricted WiFi network",
                             text: "Your current settings restrict downloads when not connected to a trusted network. Do you wish to proceed?\n\nReminder: You can change this setting in the Cache tab.",
                             button1: "Download Anyway",
                             button2: "Cancel") {
                    return
                }
            }

            // Then cache status
            if isFull() {
                if !Aerial.showAlert(question: "Your cache is full",
                                     text: "Your cache limit is currently set to \(PrefsCache.cacheLimit.rounded(toPlaces: 1)) GB, and currently contains \(Cache.sizeString()) of files.\n\n Do you want to proceed with the download anyway?\n\nYou can manually increase or decrease your cache size in Settings > Cache.",
                             button1: "Download Anyway",
                             button2: "Cancel") {
                    return
                }
            }
        }

        // If all is fine then proceed
        action()
    }

    /**
    Can we safely use network ?
    
    Depending on user's settings, they may not be on a trusted network.
    - Note: If a user disabled cache management (full manual mode), this will always be true.
    */
    static func canNetwork() -> Bool {
        if !PrefsCache.enableManagement {
            return true
        }

        if PrefsCache.restrictOnWiFi {
            // If we are not connected to WiFi we allow
            if Cache.ssid == "" || PrefsCache.allowedNetworks.contains(ssid) {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }

    static func outdatedVideos() -> [AerialVideo] {
        guard PrefsCache.enableManagement else {
            return []
        }

        var cutoffDate = Date()
        switch PrefsCache.cachePeriodicity {
        case .daily:
            cutoffDate = Calendar.current.date(byAdding: .day, value: -1, to: cutoffDate)!
        case .weekly:
            cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: cutoffDate)!
        case .monthly:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: cutoffDate)!
        case .never:
            return []
        }

        // Get a list of cached videos that are not favorites, and are from a cacheable source (not a pack)
        // Yes this is getting a bit complicated
        var evictable: [Date: AerialVideo] = [:]
        let currentlyCached = VideoList.instance.videos.filter({ $0.isAvailableOffline && $0.source.isCachable && !PrefsVideos.favorites.contains($0.id)})

        for video in currentlyCached {
            let path = VideoCache.cachePath(forVideo: video)!

            // swiftlint:disable:next force_try
            let attributes = try! FileManager.default.attributesOfItem(atPath: path)
            let creationDate = attributes[.creationDate] as! Date

            if creationDate < cutoffDate {
                evictable[creationDate] = video
            }
        }

        return  evictable.sorted { $0.key < $1.key }.map({ $0.value })
    }

    // swiftlint:disable:next cyclomatic_complexity
    static func freeCache() {
        guard PrefsCache.enableManagement else {
            return
        }

        debugLog("Looking for hidden videos to delete...")
        // Step 1 : Delete hidden videos
        for video in VideoList.instance.videos.filter({ PrefsVideos.hidden.contains($0.id) && $0.isAvailableOffline }) {
            debugLog("Deleting hidden video \(video.secondaryName)")
            do {
                let path = VideoList.instance.localPathFor(video: video)
                try FileManager.default.removeItem(atPath: path)
                // try FileManager.default.removeItem(atPath: VideoCache.cachePath(forVideo: video)!)
            } catch {
                errorLog("Could not delete video : \(video.secondaryName)")
            }
        }

        // We may be good ?
        if hasSomeFreeSpace() {
            return
        }

        // Step 2 : Delete videos that are out of rotation
        let evictables = outdatedVideos()

        if evictables.isEmpty {
            debugLog("No outdated videos, we won't delete anything")
            return
        }

        debugLog("Looking for outdated videos that aren't in rotation (candidates : \(evictables.count)")

        outerLoop: for video in evictables {
            if VideoList.instance.currentRotation().contains(video) {
                // Outdated but in rotation, so keep it !
                // debugLog("outdated but in rotation \(video.secondaryName)")
            } else {
                debugLog("Removing outdated video not in rotation \(video.secondaryName)")
                do {
                    try FileManager.default.removeItem(atPath: VideoCache.cachePath(forVideo: video)!)
                } catch {
                    errorLog("Could not delete video : \(video.secondaryName)")
                }

                if hasSomeFreeSpace() {
                    // Removed enough
                    break outerLoop
                }
            }
        }

        // Are we there yeeeet ?
        if hasSomeFreeSpace() {
            return
        }

        debugLog("Looking for outdated videos that may still be in rotation (candidates : \(evictables.count)")

        var currentVideos = [AerialVideo]()

        for view in AerialView.instanciatedViews {
            if let video = view.currentVideo {
                currentVideos.append(video)
            }
        }

        outerLoop2: for video in evictables {
            if currentVideos.contains(video) {
                debugLog("\(video.secondaryName) is currently playing, trying another")
            } else {
                debugLog("Removing outdated video that was in rotation \(video.secondaryName)")
                do {
                    try FileManager.default.removeItem(atPath: VideoCache.cachePath(forVideo: video)!)
                } catch {
                    errorLog("Could not delete video : \(video.secondaryName)")
                }

                if hasSomeFreeSpace() {
                    // Removed enough
                    break outerLoop2
                }
            }
        }

        // At this point we can't do more 
    }

    static func fillOrRollCache() {
        guard PrefsCache.enableManagement && canNetwork() else {
            return
        }

        // Grab a *shuffled* list of uncached in rotation videos
        let rotation = VideoList.instance.currentRotation().filter { !$0.isAvailableOffline }.shuffled()

        if rotation.isEmpty {
            debugLog("> Current playlist is already fully cached, no download/rotation needed")
            return
        }

        debugLog("> Fill or roll cache")
        // Do we have some space to download at least a video (by default .5 GB) ?
        if !hasSomeFreeSpace() {
            freeCache()

            if !hasSomeFreeSpace() {
                debugLog("No free space to reclaim currently.")
                return
            }
        }

        debugLog("Uncached videos in rotation : \(rotation.count)")

        // We may be satisfied already
        if rotation.isEmpty {
            return
        }

        // Queue the first video on the list
        debugLog("Queuing video : \(rotation.first!.secondaryName)")
        VideoManager.sharedInstance.queueDownload(rotation.first!)
    }
}
