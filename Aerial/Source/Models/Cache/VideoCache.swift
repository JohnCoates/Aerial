//
//  VideoCache.swift
//  Aerial
//
//  Created by John Coates on 10/29/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import AVFoundation


class VideoCache {
    var videoData:NSData
    var mutableVideoData:NSMutableData?
    
    var loading:Bool
    var loadedRanges:[NSRange] = []
    
    
    init(URL:NSURL) {
        videoData = NSData()
        loading = true
            }
    
    // MARK: - Data Adding
    
    func receivedContentLength(contentLength:Int) {
        if loading == false {
            return;
        }
        
        if mutableVideoData != nil {
            return;
        }
        
        mutableVideoData = NSMutableData(length: contentLength)
    }
    
    func receivedData(data:NSData, atRange range:NSRange) {
        guard let mutableVideoData = mutableVideoData else {
            NSLog("Aerial Error: Received data without having mutable video data");
            return;
        }
        
        mutableVideoData.replaceBytesInRange(range, withBytes: data.bytes);
        loadedRanges.append(range);
        
        consolidateLoadedRanges();
        debugLog("loaded ranges: \(self.loadedRanges)");
    }
    
    
    // MARK: - Cache Checking
    
    // Whether the video cache can fulfill this request
    func canFullfillLoadingRequest(loadingRequest:AVAssetResourceLoadingRequest) -> Bool {
        
        guard let dataRequest = loadingRequest.dataRequest else {
            NSLog("Aerial Error: Missing data request for \(loadingRequest)");
            return false;
        }
        
        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = Int(dataRequest.requestedLength)
        let requestedEnd = requestedOffset + requestedLength
        
        consolidateLoadedRanges()
        
        for range in loadedRanges {
            let rangeStart = range.location
            let rangeEnd = range.location + range.length
            
            if requestedOffset >= rangeStart && requestedEnd <= rangeEnd {
                return true;
            }
        }
        
        return false;
    }
    
    // MARK: - Consolidating
    
    func consolidateLoadedRanges() {
        var consolidatedRanges:[NSRange] = []
        
        let sortedRanges = loadedRanges.sort { $0.location < $1.location }
        
        var previousRange:NSRange?
        var lastIndex:Int?
        for range in sortedRanges {
            if let lastRange:NSRange = previousRange {
                let lastRangeEndOffset = lastRange.location + lastRange.length
                
                // check if range can be consumed by lastRange
                // or if they're at each other's edges if it can be merged
                
                if lastRangeEndOffset >= range.location {
                    let endOffset = range.location + range.length;
                    
                    // check if this range's end offset is larger than lastRange's
                    if endOffset > lastRangeEndOffset {
                        previousRange!.length = endOffset - lastRange.location;
                        
                        // replace lastRange in array with new value
                        consolidatedRanges.removeAtIndex(lastIndex!);
                        consolidatedRanges.append(lastRange);
                        continue;
                    }
                    else {
                        // skip adding this to the array, previous range is already bigger
                        debugLog("skipping add of \(range)");
                        continue;
                    }
                }
            }
            
            lastIndex = consolidatedRanges.count
            previousRange = range
            consolidatedRanges.append(range);
        }
        loadedRanges = consolidatedRanges;
    }
}