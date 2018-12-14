//
//  VideoCache.swift
//  Aerial
//
//  Created by John Coates on 10/29/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import AVFoundation
import ScreenSaver

final class VideoCache {
    var videoData: Data
    var mutableVideoData: NSMutableData?
    var loading: Bool
    var loadedRanges: [NSRange] = []
    let URL: URL

    static var computedCacheDirectory: String?

    static var cacheDirectory: String? {
        // We only process this once if successful
        if computedCacheDirectory != nil {
            return computedCacheDirectory
        }

        var cacheDirectory: String?
        let preferences = Preferences.sharedInstance

        if let customCacheDirectory = preferences.customCacheDirectory {
            // We may have overriden the cache directory
            cacheDirectory = customCacheDirectory
        } else {
            let localCachePaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                 .localDomainMask,
                                                                 true)
            let userCachePaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                 .userDomainMask,
                                                                 true)

            if localCachePaths.isEmpty || userCachePaths.isEmpty {
                errorLog("Couldn't find cache paths!")
                return nil
            }

            let localCacheDirectory = localCachePaths[0] as NSString
            let userCacheDirectory = userCachePaths[0] as NSString

            if aerialCacheExists(at: localCacheDirectory) {
                debugLog("local cache exists")
                cacheDirectory = localCacheDirectory.appendingPathComponent("Aerial")
            } else if aerialCacheExists(at: userCacheDirectory) {
                debugLog("user cache exists")
                cacheDirectory = userCacheDirectory.appendingPathComponent("Aerial")
            } else {
                debugLog("create local cache")
                // We create in local cache directory (/Library/Caches)
                cacheDirectory = localCacheDirectory.appendingPathComponent("Aerial")

                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: cacheDirectory!) == false {
                    do {
                        try fileManager.createDirectory(atPath: cacheDirectory!,
                                                        withIntermediateDirectories: false, attributes: nil)
                    } catch let error {
                        errorLog("Couldn't create cache directory: \(error)")
                        return nil
                    }
                }
            }
        }

        // Cache the computed value
        computedCacheDirectory = cacheDirectory
        debugLog("cache to be used : \(String(describing: cacheDirectory))")
        return cacheDirectory
    }

    static func aerialCacheExists(at: NSString) -> Bool {
        let aerialCache = at.appendingPathComponent("Aerial")
        if FileManager.default.fileExists(atPath: aerialCache as String) {
            return true
        } else {
            return false
        }
    }

    static func isAvailableOffline(video: AerialVideo) -> Bool {
        guard let videoCachePath = cachePath(forVideo: video) else {
            errorLog("Couldn't get video cache path!")
            return false
        }

        let fileManager = FileManager.default

        return fileManager.fileExists(atPath: videoCachePath)
    }

    static func cachePath(forVideo video: AerialVideo) -> String? {
        let vurl = video.url
        let filename = vurl.lastPathComponent
        return cachePath(forFilename: filename)
    }

    static func cachePath(forFilename filename: String) -> String? {
        guard let cacheDirectory = VideoCache.cacheDirectory else {
            return nil
        }

        let cacheDirectoryPath = cacheDirectory as NSString
        let videoCachePath = cacheDirectoryPath.appendingPathComponent(filename)
        return videoCachePath
    }

    init(URL: Foundation.URL) {
        debugLog("initvideocache")
        videoData = Data()
        loading = true
        self.URL = URL
        loadCachedVideoIfPossible()
    }

    // MARK: - Data Adding

    func receivedContentLength(_ contentLength: Int) {
        if loading == false {
            return
        }

        if mutableVideoData != nil {
            return
        }

        mutableVideoData = NSMutableData(length: contentLength)
        videoData = mutableVideoData! as Data
    }

    func receivedData(_ data: Data, atRange range: NSRange) {
        guard let mutableVideoData = mutableVideoData else {
            errorLog("Received data without having mutable video data")
            return
        }

        mutableVideoData.replaceBytes(in: range, withBytes: (data as NSData).bytes)
        loadedRanges.append(range)

        consolidateLoadedRanges()

//        debugLog("loaded ranges: \(loadedRanges)")
        if loadedRanges.count == 1 {
            let range = loadedRanges[0]
//            debugLog("checking if range \(range) matches length \(mutableVideoData.length)")
            if range.location == 0 && range.length == mutableVideoData.length {
                // done loading, save
                saveCachedVideo()
            }
        }
    }

    // MARK: - Save / Load Cache

    var videoCachePath: String? {
        let filename = URL.lastPathComponent
        return VideoCache.cachePath(forFilename: filename)
    }

    func saveCachedVideo() {
        let preferences = Preferences.sharedInstance

        guard preferences.cacheAerials else {
            debugLog("Cache disabled, not saving video")
            return
        }

        let fileManager = FileManager.default

        guard let videoCachePath = videoCachePath else {
            errorLog("Couldn't save cache file")
            return
        }

        guard fileManager.fileExists(atPath: videoCachePath) == false else {
            errorLog("Cache file \(videoCachePath) already exists.")
            return
        }

        loading = false
        if mutableVideoData == nil {
            errorLog("Missing video data for save.")
            return
        }
        /* guard var mutableVideoData = mutableVideoData else {
            errorLog("Missing video data for save.")
            return
        }*/

        do {
            try mutableVideoData!.write(toFile: videoCachePath, options: .atomicWrite)

            mutableVideoData = nil
            videoData.removeAll()
        } catch let error {
            errorLog("Couldn't write cache file: \(error)")
        }
    }

    func loadCachedVideoIfPossible() {
        let fileManager = FileManager.default

        guard let videoCachePath = self.videoCachePath else {
            errorLog("Couldn't load cache file.")
            return
        }

        if fileManager.fileExists(atPath: videoCachePath) == false {
            return
        }

        guard let videoData = try? Data(contentsOf: Foundation.URL(fileURLWithPath: videoCachePath)) else {
            errorLog("NSData failed to load cache file \(videoCachePath)")
            return
        }

        self.videoData = videoData
        loading = false
        debugLog("cached video file with length: \(self.videoData.count)")
    }

    // MARK: - Fulfilling cache

    func fulfillLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let dataRequest = loadingRequest.dataRequest else {
            errorLog("Missing data request for \(loadingRequest)")
            return false
        }

        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = Int(dataRequest.requestedLength)

        let data = videoData.subdata(in: requestedOffset..<requestedOffset + requestedLength)

        DispatchQueue.main.async { () -> Void in
            self.fillInContentInformation(loadingRequest)

            dataRequest.respond(with: data)
            loadingRequest.finishLoading()
        }

        return true
    }

    func fillInContentInformation(_ loadingRequest: AVAssetResourceLoadingRequest) {

        guard let contentInformationRequest = loadingRequest.contentInformationRequest else {
            return
        }

        let contentType: String = kUTTypeQuickTimeMovie as String

        contentInformationRequest.isByteRangeAccessSupported = true
        contentInformationRequest.contentType = contentType
        contentInformationRequest.contentLength = Int64(videoData.count)
    }

    // MARK: - Cache Checking

    // Whether the video cache can fulfill this request
    func canFulfillLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {

        if !loading {
            return true
        }

        guard let dataRequest = loadingRequest.dataRequest else {
            errorLog("Missing data request for \(loadingRequest)")
            return false
        }

        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = Int(dataRequest.requestedLength)
        let requestedEnd = requestedOffset + requestedLength

        for range in loadedRanges {
            let rangeStart = range.location
            let rangeEnd = range.location + range.length

            if requestedOffset >= rangeStart && requestedEnd <= rangeEnd {
                return true
            }
        }

        return false
    }

    // MARK: - Consolidating

    func consolidateLoadedRanges() {
        var consolidatedRanges: [NSRange] = []

        let sortedRanges = loadedRanges.sorted { $0.location < $1.location }

        var previousRange: NSRange?
        var lastIndex: Int?
        for range in sortedRanges {
            if let lastRange: NSRange = previousRange {
                let lastRangeEndOffset = lastRange.location + lastRange.length

                // check if range can be consumed by lastRange
                // or if they're at each other's edges if it can be merged

                if lastRangeEndOffset >= range.location {
                    let endOffset = range.location + range.length

                    // check if this range's end offset is larger than lastRange's
                    if endOffset > lastRangeEndOffset {
                        previousRange!.length = endOffset - lastRange.location

                        // replace lastRange in array with new value
                        consolidatedRanges.remove(at: lastIndex!)
                        consolidatedRanges.append(previousRange!)
                        continue
                    } else {
                        // skip adding this to the array, previous range is already bigger
//                        debugLog("skipping add of \(range), previous: \(previousRange)")
                        continue
                    }
                }
            }

            lastIndex = consolidatedRanges.count
            previousRange = range
            consolidatedRanges.append(range)
        }
        loadedRanges = consolidatedRanges
    }
}
