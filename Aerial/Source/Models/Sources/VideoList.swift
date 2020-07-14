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
        case location
    }

    static let instance: VideoList = VideoList()
    var callbacks = [VideoListRefreshCallback]()

    var videos: [AerialVideo] = []

    // Playlist management
    var playlistIsRestricted = false
    var playlistRestrictedTo = ""
    var playlist = [AerialVideo]()
    var lastPluckedFromPlaylist: AerialVideo?

    init() {
        downloadManifestsIfNeeded()
    }

    func getSectionsCount(mode: FilterMode) -> Int {
        switch mode {
        case .location:
            return videos.map { $0.name }.unique(for: \.self).count
        }
    }

    func getSectionName(_ section: Int, mode: FilterMode) -> String {
        switch mode {
        case .location:
            return videos.map { $0.name }.unique(for: \.self)[section]
        }
    }

    func getVideosCountForSection(_ section: Int, mode: FilterMode) -> Int {
        switch mode {
        case .location:
            let sectionKey = videos.map { $0.name }.unique(for: \.self)[section]
            return videos.filter { $0.name == sectionKey }.count
        }
    }

    func getVideoForSection(_ section: Int, item: Int, mode: FilterMode) -> AerialVideo {
        switch mode {
        case .location:
            let sectionKey = videos.map { $0.name }.unique(for: \.self)[section]
            return videos.filter { $0.name == sectionKey }[item]
        }
    }

    func addCallback(_ callback:@escaping VideoListRefreshCallback) {
        callbacks.append(callback)
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

        // Let everyone who wants to know that our list is updated
        for callback in callbacks {
            callback()
        }
    }

    // MARK: - Playlist management
    func generatePlaylist(isRestricted: Bool, restrictedTo: String) {
        // Start fresh
        playlist = [AerialVideo]()
        playlistIsRestricted = isRestricted
        playlistRestrictedTo = restrictedTo

        // Start with a shuffled list, we may have synchronized seed shuffle
        var shuffled: [AerialVideo]
        let preferences = Preferences.sharedInstance
        /*if preferences.synchronizedMode {
            if #available(OSX 10.11, *) {
                let date = Date()
                let calendar = NSCalendar.current
                let minutes = calendar.component(.minute, from: date)
                debugLog("seed : \(minutes)")

                var generator = SeededGenerator(seed: UInt64(minutes))
                shuffled = loadedManifest.shuffled(using: &generator)
            } else {
                // Fallback on earlier versions
                shuffled = loadedManifest.shuffled()
            }
        } else {
            shuffled = loadedManifest.shuffled()
        }*/
        // Somehow code above doesn't work anymore, force disabling it for everyone for now
        shuffled = videos.shuffled()

        for video in shuffled {
            // We exclude videos not in rotation
            let inRotation = preferences.videoIsInRotation(videoID: video.id)

            if !inRotation {
                continue
            }

            // Do we restrict video types by day/night ?
            if isRestricted {
                if video.timeOfDay != restrictedTo {
                    continue
                }
            }

            // Are we in full manual mode ?? This replace the old never stream setting
            if !video.isAvailableOffline && !PrefsCache.enableManagement {
                continue
            }

            // Is the video cached, and if not, are we full ?
            if !video.isAvailableOffline && Cache.isFull() {
                continue
            }

            // If the video isn't cached, can we network ?
            if !video.isAvailableOffline && !Cache.canNetwork() {
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
                // We exclude videos not in rotation
                let preferences = Preferences.sharedInstance

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

}
