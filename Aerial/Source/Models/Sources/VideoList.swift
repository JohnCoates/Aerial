//
//  VideoList.swift
//  Aerial
//
//  Created by Guillaume Louel on 08/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

typealias VideoListRefreshCallback = () -> Void
extension RangeReplaceableCollection {
    /// Returns a collection containing, in order, the first instances of
    /// elements of the sequence that compare equally for the keyPath.
    func unique<T: Hashable>(for keyPath: KeyPath<Element, T>) -> Self {
        var unique = Set<T>()
        return filter { unique.insert($0[keyPath: keyPath]).inserted }
    }
}

// swiftlint:disable:next type_body_length
class VideoList {
    enum FilterMode {
        case location, cache, time, scene, source, rotation, favorite, hidden
    }

    static let instance: VideoList = VideoList()
    var callbacks = [VideoListRefreshCallback]()

    var videos: [AerialVideo] = []

    // OLD Playlist management
    var playlistIsRestricted = false
    var playlistRestrictedTo = ""
    var playlistHasVerticalVideos = false
    var playlist = [AerialVideo]()
    var lastPluckedFromPlaylist: AerialVideo?

    let cacheDownloaded = "Downloaded"
    let cacheOnline = "Online"
    init() {
        downloadManifestsIfNeeded()
    }

    func videoForFilename(_ name: String) -> AerialVideo? {
        for video in videos where video.url.lastPathComponent == name {
            return video
        }

        errorLog("vFF unknown video filename")
        return nil
    }

    // This is used to grab the correct path depending on whether a source is cacheable or not
    func localPathFor(video: AerialVideo) -> String {
        if video.source.isCachable {
            return VideoCache.cachePath(forVideo: video) ?? ""
        } else {
            return VideoCache.sourcePathFor(video)
        }
    }

    // MARK: - Helpers for the various filterings
    private func cacheSources() -> [String] {
        var cache: [String] = []

        if !videos.filter({ $0.isAvailableOffline && !PrefsVideos.hidden.contains($0.id) }).isEmpty {
            cache.append(cacheDownloaded)
        }
        if !videos.filter({ !$0.isAvailableOffline && !PrefsVideos.hidden.contains($0.id) }).isEmpty {
            cache.append(cacheOnline)
        }

        return cache
    }

    private func sourcesFor(_ mode: FilterMode) -> [String] {
        switch mode {
        case .location:
            return videos.filter { !PrefsVideos.hidden.contains($0.id) }.map { $0.name }.unique(for: \.self)
        case .time:
            return videos.filter { !PrefsVideos.hidden.contains($0.id) }.map { $0.timeOfDay.capitalizeFirstLetter() }.unique(for: \.self)
        case .scene:
            return videos.filter { !PrefsVideos.hidden.contains($0.id) }.map { $0.scene.rawValue.capitalizeFirstLetter() }.unique(for: \.self)
        case .source:
            return videos.filter { !PrefsVideos.hidden.contains($0.id) }.map { $0.source.name }.unique(for: \.self)
        case .cache:
            return cacheSources()
        case .rotation:
            return ["On Rotation"]
        case .favorite:
            return ["Favorites"]
        case .hidden:
            return ["Hidden"]
        }
    }

    private func filteredVideosFor(_ mode: FilterMode, section: Int) -> [AerialVideo] {
        switch mode {
        case .location:
            let filter = sourcesFor(mode)[section].lowercased()
            return videos
                .filter { $0.name.lowercased() == filter && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .time:
            let filter = sourcesFor(mode)[section].lowercased()
            return videos
                .filter { $0.timeOfDay.lowercased() == filter && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .scene:
            let filter = sourcesFor(mode)[section].lowercased()
            return videos
                .filter { $0.scene.rawValue.lowercased() == filter && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .source:
            let filter = sourcesFor(mode)[section].lowercased()
            return videos
                .filter { $0.source.name.lowercased() == filter && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .cache:
            // TODO FIX THIS IT CRASHES WHEN YOU FAV FROM ONLINE
            // if let cacheSources().
            if cacheSources()[section] == cacheDownloaded {
                return videos
                    .filter({ $0.isAvailableOffline && !PrefsVideos.hidden.contains($0.id) })
                    .sorted { $0.secondaryName < $1.secondaryName }
            } else {
                return videos
                    .filter({ !$0.isAvailableOffline && !PrefsVideos.hidden.contains($0.id) })
                    .sorted { $0.secondaryName < $1.secondaryName }
            }
        case .rotation:
            return currentRotation()    // Result is already sorted there
        case .favorite:
            return videos
                .filter { PrefsVideos.favorites.contains($0.id) && !PrefsVideos.hidden.contains($0.id)}
                .sorted { $0.secondaryName < $1.secondaryName }
        case .hidden:
            return videos
                .filter { PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        }

    }

    // swiftlint:disable:next cyclomatic_complexity
    private func filteredVideosFor(_ mode: FilterMode, filter: [String]) -> [AerialVideo] {
        // Our preference filters contains ALL sorts of filters (location, time) that are
        // saved for better user experience. So we need to filter the filters first !
        var filters: [String] = []

        for afilter in filter {
            switch mode {
            case .location:
                if afilter.starts(with: "location") {
                    filters.append(afilter.split(separator: ":")[1].lowercased())
                }
            case .cache:
                filters.append(afilter.lowercased())
            case .time:
                if afilter.starts(with: "time") {
                    filters.append(afilter.split(separator: ":")[1].lowercased())
                }
            case .scene:
                if afilter.starts(with: "scene") {
                    filters.append(afilter.split(separator: ":")[1].lowercased())
                }
            case .source:
                if afilter.starts(with: "source") {
                    filters.append(afilter.split(separator: ":")[1].lowercased())
                }
            case .rotation:
                filters.append(afilter.lowercased())
            case .favorite:
                filters.append(afilter.lowercased())
            case .hidden:
                filters.append(afilter.lowercased())
            }
        }
        print("Filters :")
        for filter in filters {
            print(filter)
        }

        /*print("Videos : ")
        for video in videos {
            print(video.name.lowercased())
        }*/

        switch mode {
        case .location:
            let vids = videos
                .filter { filters.contains($0.name.lowercased()) && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
            return vids
        case .time:
            return videos
                .filter { filters.contains($0.timeOfDay.lowercased()) && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .scene:
            return videos
                .filter { filters.contains($0.scene.rawValue.lowercased()) && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .source:
            return videos
                .filter { filters.contains($0.source.name.lowercased()) && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .favorite:
            return videos
                .filter { PrefsVideos.favorites.contains($0.id) && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .hidden:
            return videos
                .filter { PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        default:
            return videos
                .filter({ $0.isAvailableOffline })
                .sorted { $0.secondaryName < $1.secondaryName }
        }
    }

    // MARK: - Public getters to filter the list
    func getSources(mode: FilterMode) -> [String] {
        return sourcesFor(mode)
    }

    func getSourcesCount(mode: FilterMode) -> Int {
        return sourcesFor(mode).count
    }

    func getSourceName(_ section: Int, mode: FilterMode) -> String {
        return sourcesFor(mode)[section]
    }

    func getVideosCountForSource(_ section: Int, mode: FilterMode) -> Int {
        return filteredVideosFor(mode, section: section).count
    }

    func getVideoForSource(_ section: Int, item: Int, mode: FilterMode) -> AerialVideo {
        return filteredVideosFor(mode, section: section)[item]
    }

    func getVideosForSource(_ section: Int, mode: FilterMode) -> [AerialVideo] {
        return filteredVideosFor(mode, section: section)
    }

    // MARK: - Public getter for a video list from paths
    func getVideosForPath(_ path: String) -> [AerialVideo] {
        if let mode = VideoList.instance.modeFromPath(path) {
            let index = Int(path.split(separator: ":")[1])!
            return VideoList.instance.getVideosForSource(index, mode: mode)
        } else {
            // all
            return VideoList.instance.videos.filter({ !PrefsVideos.hidden.contains($0.id) }).sorted { $0.secondaryName < $1.secondaryName }
        }
    }

    func modeFromPath(_ path: String) -> FilterMode? {
        if path.starts(with: "location") {
            return .location
        } else if path.starts(with: "cache") {
            return .cache
        } else if path.starts(with: "time") {
            return .time
        } else if path.starts(with: "scene") {
            return .scene
        } else if path.starts(with: "rotation") {
            return .rotation
        } else if path.starts(with: "source") {
            return .source
        } else if path.starts(with: "favorites") {
            return .favorite
        } else if path.starts(with: "hidden") {
            return .hidden
        } else {
            return nil
        }
    }

    // MARK: - Callbacks
    func addCallback(_ callback:@escaping VideoListRefreshCallback) {
        callbacks.append(callback)

        // We may need to insta callback if we were already inited
        if !videos.isEmpty {
            callback()
        }
    }

    // This is how we force a source refresh, it will trigger various callbacks when done
    // (e.g. to refresh video list in the ui)
    func reloadSources() {
        videos = []
        downloadManifestsIfNeeded()
    }

    func downloadSource(source: Source) {
        let downloadManager = DownloadManager()

        let completion = BlockOperation {
            self.refreshVideoList()
            if !PrefsCache.enableManagement {
                Aerial.showInfoAlert(title: "Automatic downloads are disabled", text: "In order to watch the new videos, you will need to manually download them (for example by pressing the down arrow button on the right).")
            }
        }

        for src in SourceList.list where source.name == src.name {
            debugLog("Marking \(source.name) for redownload")
            // Then queue the download
            let operation = downloadManager.queueDownload(URL(string: source.manifestUrl)!, folder: source.name)
            completion.addDependency(operation)

            OperationQueue.main.addOperation(completion)
        }
    }

    private func downloadManifestsIfNeeded() {
        let downloadManager = DownloadManager()

        var sourceQueue: [Source] = []

        let completion = BlockOperation {
            self.refreshVideoList()
        }

        // Let's check our sources first
        for source in SourceList.list {
            // But only the enabled ones
            if source.isEnabled() {
                // We may need to download it
                if !source.isCached() {
                    debugLog("\(source.name) is not cached, downloading...")
                    sourceQueue.append(source)
                } else if PrefsVideos.shouldCheckForNewVideos() && Cache.canNetwork() {
                    debugLog("\(source.name) looking for updated manifest...")
                    sourceQueue.append(source)
                } else {
                    debugLog("\(source.name) is enabled, cached and up to date")
                }
            }
        }

        if !sourceQueue.isEmpty {
            // Now queue and download
            for source in sourceQueue {
                // Then queue the download
                let operation = downloadManager.queueDownload(URL(string: source.manifestUrl)!, folder: source.name)
                completion.addDependency(operation)

                // Mark that we updated our sources
                PrefsVideos.saveLastVideoCheck()
            }

            OperationQueue.main.addOperation(completion)
        } else {
            DispatchQueue.main.async {
                self.refreshVideoList()
            }
        }
    }

    // This is called when all our files are downloaded
    private func refreshVideoList() {
        debugLog("Refreshing video list")

        videos = []

        for source in SourceList.list {
            if source.isEnabled() {
                // We may need to download it
                if source.isCached() {
                    let vids = source.getVideos()
                    videos.append(contentsOf: vids)
                    debugLog("source : \(source.name) contains \(vids.count) new videos (total \(videos.count))")
                }
            }
        }

        videos = videos.sorted { $0.name < $1.name }

        // Let everyone who wants to know that our list is updated
        for callback in callbacks {
            callback()
        }
    }

    // MARK: - New rotation management
    func currentRotation() -> [AerialVideo] {
        var mode: FilterMode
        switch PrefsVideos.newShouldPlay {
        case .location:
            mode = .location
        case .time:
            mode = .time
        case .scene:
            mode = .scene
        case .source:
            mode = .source
        default:
            mode = .cache
        }

        switch PrefsVideos.newShouldPlay {
/*        case .everything:
            return videos
                .filter({ !PrefsVideos.hidden.contains($0.id) })
                .sorted { $0.secondaryName < $1.secondaryName }*/
        case .favorites:
            return videos
                .filter({ PrefsVideos.favorites.contains($0.id) && !PrefsVideos.hidden.contains($0.id) })
                .sorted { $0.secondaryName < $1.secondaryName }
        default:
            return filteredVideosFor(mode, filter: PrefsVideos.newShouldPlayString)
        }
    }

    // MARK: - Playlist management
    func generatePlaylist(isRestricted: Bool, restrictedTo: String, isVertical: Bool) {
        debugLog("generate playlist (isVertical: \(isVertical)")
        // Start fresh
        playlist = [AerialVideo]()
        playlistIsRestricted = isRestricted
        playlistRestrictedTo = restrictedTo
        playlistHasVerticalVideos = false

        let shuffled = currentRotation().shuffled()
        let cachedShuffled = shuffled.filter({ $0.isAvailableOffline })

        debugLog("Playlist raw count: \(shuffled.count) raw cached count \(cachedShuffled.count) isRestricted: \(isRestricted) restrictedTo: \(restrictedTo)")

        if PrefsDisplays.viewingMode == .independent && PrefsAdvanced.favorOrientation {
            // We check cached videos only as those are the only ones for which we know the orientation
            for video in cachedShuffled {
                // swiftlint:disable:next for_where
                if video.isVertical {
                    playlistHasVerticalVideos = true
                    debugLog(">>> Playlist contains vertical videos (favoring ON)")
                }
            }
        }

        for video in shuffled {
            /*
            // Do we restrict videos by screen orientation ?
            if restrictOrientation {
                print(video.url)
                print(video.isVertical)
                if !video.isVertical && isVertical {
                    // Block landscape videos on vertical screens
                    continue
                } else if video.isVertical && !isVertical {
                    // Block portrait videos on horizontal screens
                    continue
                }
            }*/

            // Do we restrict video types by day/night ?
            if isRestricted {
                if video.timeOfDay != restrictedTo {
                    continue
                }
            }

            if !video.isAvailableOffline {
                continue
            }

            // All good ? Add to playlist
            playlist.append(video)
        }

        debugLog("Final count : \(playlist.count)")
        // On regenerating a new playlist, we try to avoid repeating the last thing we played!
        while playlist.count > 1 && lastPluckedFromPlaylist == playlist.first {
            playlist.shuffle()
        }
    }

    func randomVideo(excluding: [AerialVideo], isVertical: Bool) -> (AerialVideo?, Bool) {
        var shouldLoop = false
        let timeManagement = TimeManagement.sharedInstance

        let (shouldRestrictByDayNight, restrictTo) = timeManagement.shouldRestrictPlaybackToDayNightVideo()

        // Do we still have a video in the correct format in the playlist?
        var needOrientedVideo = false
        if playlistHasVerticalVideos && !playlist.isEmpty {
            needOrientedVideo = true
            for video in playlist {
                if isVertical && video.isVertical {
                    needOrientedVideo = false
                } else if !isVertical && !video.isVertical {
                    needOrientedVideo = false
                }
            }
        }

        debugLog("remaining in playlist : \(playlist.count) needOrientedVideo : \(needOrientedVideo)")

        // We may need to regenerate a playlist!
        if playlist.isEmpty || restrictTo != playlistRestrictedTo || shouldRestrictByDayNight != playlistIsRestricted || needOrientedVideo {
            generatePlaylist(isRestricted: shouldRestrictByDayNight, restrictedTo: restrictTo, isVertical: isVertical)
            if playlist.count == 1 {
                debugLog("playlist only has one element, looping!")
                shouldLoop = true
            }
        }

        // If not pluck one from current playlist and return that
        if !playlist.isEmpty {
            if playlistHasVerticalVideos {
                lastPluckedFromPlaylist = pluckOrientedVideo(isVertical: isVertical)
            } else {
                lastPluckedFromPlaylist = playlist.removeFirst()
            }

            return (lastPluckedFromPlaylist, shouldLoop)
        } else {
            // If we don't have any playlist, something's got awfully wrong so deal with that!
            return (findBestEffortVideo(), shouldLoop)
        }
    }

    func pluckOrientedVideo(isVertical: Bool) -> AerialVideo? {
        // Grab first one corresponding to orientation
        lastPluckedFromPlaylist = playlist.first(where: { $0.isVertical == isVertical })!
        debugLog("lastplucked")

        // And actually remove it
        debugLog("pre pluck \(playlist.count)")
        playlist = playlist.filter { $0 != lastPluckedFromPlaylist }
        debugLog("post pluck \(playlist.count)")

        return lastPluckedFromPlaylist
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
            warnLog("Repeating last played video, after condition change not met !")
            return lastPluckedFromPlaylist!
        } else {
            // Start with a shuffled list
            let shuffled = videos.shuffled()

            if shuffled.isEmpty {
                // This is super bad, no manifest at all
                errorLog("No manifest, nothing to play !")
                return nil
            }

            for video in shuffled {
                // If we find anything cached and in rotation, we send that back
                if video.isAvailableOffline && currentRotation().contains(video) {
                    warnLog("returning random cached in rotation video after condition change not met !")
                    return video
                }
            }

            // We try to return something that's at least in the rotation, if there is one
            if !currentRotation().isEmpty {
                warnLog("returning random non cached BUT in rotation video after condition change not met !")
                return currentRotation().shuffled().first
            }

            // Really nothing ? I can't even !
            warnLog("returning truly random video after condition change not met !")
            return shuffled.first!
        }
    }

}
