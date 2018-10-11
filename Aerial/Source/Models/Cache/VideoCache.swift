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

class VideoCache {
    var videoData: Data
    var mutableVideoData: NSMutableData?
    
    var loading: Bool
    var loadedRanges: [NSRange] = []
    let URL: URL
    
    static var cacheDirectory: String? {
        get {
            var cacheDirectory: String?
            
            let preferences = Preferences.sharedInstance
            if let customCacheDirectory = preferences.customCacheDirectory {
                cacheDirectory = customCacheDirectory
            } else {
                let cachePaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                     .userDomainMask,
                                                                     true)
                if cachePaths.count == 0 {
                    NSLog("Aerial Error: Couldn't find cache paths!")
                    return nil
                }
                
                let userCacheDirectory = cachePaths[0] as NSString
                let defaultCacheDirectory = userCacheDirectory.appendingPathComponent("Aerial")
                
                cacheDirectory = defaultCacheDirectory
            }

            guard let appCacheDirectory = cacheDirectory else {
                return nil
            }
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: appCacheDirectory as String) == false {
                do {
                    try fileManager.createDirectory(atPath: appCacheDirectory as String,
                                                    withIntermediateDirectories: false, attributes: nil)
                } catch let error {
                    NSLog("Aerial Error: Couldn't create cache directory: \(error)")
                    return nil
                }
            }
            return appCacheDirectory
        }
    }
    
    static func isAvailableOffline(video: AerialVideo) -> Bool {
        guard let videoCachePath = cachePath(forVideo: video) else {
            NSLog("Aerial Error: Couldn't get video cache path!")
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
            NSLog("Aerial Error: Received data without having mutable video data")
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
        get {
            let filename = URL.lastPathComponent
            return VideoCache.cachePath(forFilename: filename)
        }
    }
    
    func saveCachedVideo() {
        let preferences = Preferences.sharedInstance
        
        guard preferences.cacheAerials else {
            debugLog("Cache disabled, not saving video")
            return
        }
        
        let fileManager = FileManager.default
        
        guard let videoCachePath = videoCachePath else {
            NSLog("Aerial Error: Couldn't save cache file")
            return
        }
        
        guard fileManager.fileExists(atPath: videoCachePath) == false else {
            NSLog("Aerial Error: Cache file \(videoCachePath) already exists.")
            return
        }
        
        loading = false
        guard let mutableVideoData = mutableVideoData else {
            NSLog("Aerial Error: Missing video data for save.")
            return
        }
        
        do {
            try mutableVideoData.write(toFile: videoCachePath, options: .atomicWrite)
        } catch let error {
            NSLog("Aerial Error: Couldn't write cache file: \(error)")
        }
    }
    
    func loadCachedVideoIfPossible() {
        let fileManager = FileManager.default
        
        guard let videoCachePath = self.videoCachePath else {
            NSLog("Aerial Error: Couldn't load cache file.")
            return
        }
        
        if fileManager.fileExists(atPath: videoCachePath) == false {
            return
        }
        
        guard let videoData = try? Data(contentsOf: Foundation.URL(fileURLWithPath: videoCachePath)) else {
            NSLog("Aerial Error: NSData failed to load cache file \(videoCachePath)")
            return
        }
        
        self.videoData = videoData
        loading = false
        debugLog("cached video file with length: \(self.videoData.count)")
    }
    
    // MARK: - Fulfilling cache
    
    func fulfillLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let dataRequest = loadingRequest.dataRequest else {
            NSLog("Aerial Error: Missing data request for \(loadingRequest)")
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
            NSLog("Aerial Error: Missing data request for \(loadingRequest)")
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
