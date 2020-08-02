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
    var playlist = [AerialVideo]()
    var lastPluckedFromPlaylist: AerialVideo?

    let cacheDownloaded = "Downloaded"
    let cacheOnline = "Online"
    init() {
        downloadManifestsIfNeeded()
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

    private func filteredVideosFor(_ mode: FilterMode, filter: String) -> [AerialVideo] {
        let lfilter = filter.lowercased()
        switch mode {
        case .location:
            return videos
                .filter { $0.name.lowercased() == lfilter && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .time:
            return videos
                .filter { $0.timeOfDay.lowercased() == lfilter && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .scene:
            return videos
                .filter { $0.scene.rawValue.lowercased() == lfilter && !PrefsVideos.hidden.contains($0.id) }
                .sorted { $0.secondaryName < $1.secondaryName }
        case .source:
            return videos
                .filter { $0.source.name.lowercased() == lfilter && !PrefsVideos.hidden.contains($0.id) }
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
            return VideoList.instance.videos.sorted { $0.secondaryName < $1.secondaryName }
        }
    }

    func modeFromPath(_ path: String) -> FilterMode? {
        if path.starts(with: "location:") {
            return .location
        } else if path.starts(with: "cache:") {
            return .cache
        } else if path.starts(with: "time:") {
            return .time
        } else if path.starts(with: "scene:") {
            return .scene
        } else if path.starts(with: "rotation:") {
            return .rotation
        } else if path.starts(with: "source:") {
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
                debugLog("\(source.name) is enabled")

                // We may need to download it
                if !source.isCached() {
                    debugLog("\(source.name) is not cached, downloading...")
                    sourceQueue.append(source)
                }
            }
        }

        // Now queue and download
        for source in sourceQueue {
            // Then queue the download
            let operation = downloadManager.queueDownload(URL(string: source.manifestUrl)!, folder: source.name)
            completion.addDependency(operation)
        }

        OperationQueue.main.addOperation(completion)
    }

    // This is called when all our files are downloaded
    private func refreshVideoList() {
        debugLog("Refreshing video list")

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

        //Thumbnails.generateAllThumbnails(forVideos: videos)
        // Let everyone who wants to know that our list is updated
        for callback in callbacks {
            callback()
        }
    }

    // MARK: - New rotation management
    func currentRotation() -> [AerialVideo] {
        var mode: FilterMode
        switch PrefsVideos.shouldPlay {
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

        switch PrefsVideos.shouldPlay {
        case .everything:
            return videos
                .filter({ !PrefsVideos.hidden.contains($0.id) })
                .sorted { $0.secondaryName < $1.secondaryName }
        case .favorites:
            return videos
                .filter({ PrefsVideos.favorites.contains($0.id) && !PrefsVideos.hidden.contains($0.id) })
                .sorted { $0.secondaryName < $1.secondaryName }
        default:
            return filteredVideosFor(mode, filter: PrefsVideos.shouldPlayString)
        }
    }

    // MARK: - Playlist management
    func generatePlaylist(isRestricted: Bool, restrictedTo: String) {
        // Start fresh
        playlist = [AerialVideo]()
        playlistIsRestricted = isRestricted
        playlistRestrictedTo = restrictedTo

        let shuffled = currentRotation().shuffled()

        for video in shuffled {
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

        // On regenerating a new playlist, we try to avoid repeating the last thing we played!
        while playlist.count > 1 && lastPluckedFromPlaylist == playlist.first {
            playlist.shuffle()
        }
    }

    func randomVideo(excluding: [AerialVideo]) -> (AerialVideo?, Bool) {
        var shouldLoop = false
        let timeManagement = TimeManagement.sharedInstance
        let (shouldRestrictByDayNight, restrictTo) = timeManagement.shouldRestrictPlaybackToDayNightVideo()

        // We may need to regenerate a playlist!
        if playlist.isEmpty || restrictTo != playlistRestrictedTo || shouldRestrictByDayNight != playlistIsRestricted {
            generatePlaylist(isRestricted: shouldRestrictByDayNight, restrictedTo: restrictTo)
            if playlist.count == 1 {
                debugLog("playlist only has one element, looping!")
                shouldLoop = true
            }
        }

        // If not pluck one from current playlist and return that
        if !playlist.isEmpty {
            lastPluckedFromPlaylist = playlist.removeFirst()
            return (lastPluckedFromPlaylist, shouldLoop)
        } else {
            // If we don't have any playlist, something's got awfully wrong so deal with that!
            return (findBestEffortVideo(), shouldLoop)
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

            // Nothing ? Sorry but you'll get a non cached file
            warnLog("returning random video after condition change not met !")
            return shuffled.first!
        }
    }

}
