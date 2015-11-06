//
//  VideoDownload.swift
//  Aerial
//
//  Created by John Coates on 10/31/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation


protocol VideoDownloadDelegate : NSObjectProtocol {
    func videoDownload(videoDownload:VideoDownload , finished success:Bool, errorMessage:String?);
    // bytes received for bytes/second count
    func videoDownload(videoDownload:VideoDownload, receivedBytes:Int, progress:Float)
};

class VideoDownloadStream {
    var connection:NSURLConnection
    var response:NSURLResponse?
    var contentInformationRequest:Bool = false
    var downloadOffset = 0
    
    init(connection:NSURLConnection) {
        self.connection = connection;
    }
    deinit {
        connection.cancel()
    }
}

class VideoDownload : NSObject, NSURLConnectionDataDelegate {
    var streams:[VideoDownloadStream] = []
    weak var delegate:VideoDownloadDelegate!

    let queue = dispatch_get_main_queue()
    
    let video:AerialVideo
    
    var data:NSMutableData?
    var downloadedData:Int = 0
    var contentLength:Int = 0
    
    init(video:AerialVideo, delegate:VideoDownloadDelegate) {
        self.video = video
        self.delegate = delegate
    }
    
    func startDownload() {
        // first start content information download
        startDownloadForContentInformation()
    }
    
    // download a couple bytes to get the content length
    func startDownloadForContentInformation() {
        startDownloadForChunk(nil);
    }
    
    func startDownloadForChunk(chunk:NSRange?) {
        let request = NSMutableURLRequest(URL: video.url);
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData;
        
        if let requestedRange = chunk {
            // set Range: bytes=startOffset-endOffset
            let requestRangeField = "bytes=\(requestedRange.location)-\(requestedRange.location+requestedRange.length)";
            request.setValue(requestRangeField, forHTTPHeaderField: "Range");
            debugLog("Starting download for range \(requestRangeField)")
        }
        
        
        guard let connection = NSURLConnection(request: request, delegate: self, startImmediately: false) else {
            NSLog("Aerial: Error creating connection with request: \(request)");
            return;
        }
        
        let stream = VideoDownloadStream(connection: connection)
        
        if chunk == nil {
            debugLog("Starting download for content information")
            stream.contentInformationRequest = true;
        }
        
        connection.start()
        
        streams.append(stream)
        
    }
    
    func streamForConnection(connection: NSURLConnection) -> VideoDownloadStream? {
        for stream in streams {
            if stream.connection == connection {
                return stream;
            }
        }
        
        return nil;
    }
    
    func createStreamsBasedOnContentLength(contentLength:Int) {
        self.contentLength = contentLength
        // remove content length request stream
        streams.removeFirst()
        
        data = NSMutableData(length: contentLength)
        
        // start 4 streams for maximum throughput
        let streamCount = 4;
        let pace = 0.2; // pace stream creation a little bit
        let streamPiece = Int(floor(Double(contentLength) / Double(streamCount)))
        debugLog("Starting \(streamCount) streams with \(streamPiece) each, for content length of \(contentLength)")
        var offset = 0
        
        var delayTime:Double = 0
        
        let queue = dispatch_get_main_queue()
        for (var i=0; i < streamCount; i++) {
            let isLastStream:Bool = i == (streamCount - 1)
            var range:NSRange = NSMakeRange(offset, streamPiece)
            
            if isLastStream {
                let bytesLeft = contentLength - offset;
                range = NSMakeRange(offset, bytesLeft)
                debugLog("last stream range: \(range)")
            }
            

            let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(delayTime * Double(NSEC_PER_SEC)))
            dispatch_after(delay, queue, { () -> Void in
                self.startDownloadForChunk(range)
            })
            
            // increase delay
            delayTime += pace
            
            // increase offset
            offset += range.length

        }
    }
    
    func receiveDataForStream(stream:VideoDownloadStream, receivedData:NSData) {
        guard let videoData = self.data else {
            NSLog("Aerial error: video data missing!");
            return;
        }
        
        let replaceRange = NSMakeRange(stream.downloadOffset, receivedData.length)
        videoData.replaceBytesInRange(replaceRange, withBytes: receivedData.bytes)
        stream.downloadOffset += receivedData.length
    }
    
    func finishedDownload() {
        guard let videoCachePath = VideoCache.cachePathForVideo(video) else {
            NSLog("Aerial Error: Couldn't save video because couldn't get cache path")
            failedDownload("Couldn't get cache path")
            return;
        }
        
        guard let videoData = self.data else {
            NSLog("Aerial error: video data missing!");
            return;
        }
        
        var success:Bool = true
        var errorMessage:String?
        do {
            try videoData.writeToFile(videoCachePath, options: .AtomicWrite)
        }
        catch let error {
            NSLog("Aerial Error: Couldn't write cache file: \(error)");
            errorMessage = "Couldn't write to cache file!"
            success = false
        }
        
        // notify delegate
        delegate.videoDownload(self, finished: success, errorMessage: errorMessage)
        
    }
    
    func failedDownload(errorMessage:String) {
        
        delegate.videoDownload(self, finished: false, errorMessage: errorMessage)
    }
    
    // MARK: - NSURLConnection Delegate
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        guard let stream = streamForConnection(connection) else {
            NSLog("Aerial Error: No matching stream for connection: \(connection) with response: \(response)")
            return;
        }
        
        stream.response = response as? NSHTTPURLResponse;
        
        if stream.contentInformationRequest == true {
            connection.cancel()
            
            dispatch_async(queue, { () -> Void in
                let contentLength = Int(response.expectedContentLength);
                self.createStreamsBasedOnContentLength(contentLength)
            })
            
            return;
        }
        else {
            // get real offset of receiving data
            
            dispatch_async(queue, { () -> Void in
                guard let offset = self.startOffsetFromResponse(response) else {
                    NSLog("Aerial Error: Couldn't get start offset from response: \(response)")
                    return
                }
                
                stream.downloadOffset = offset
            })
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        guard let delegate = self.delegate else {
            return;
        }
        
        dispatch_async(queue) { () -> Void in
            self.downloadedData += data.length
            let progress:Float = Float(self.downloadedData) / Float(self.contentLength)
            delegate.videoDownload(self, receivedBytes: data.length, progress: progress)
            
            guard let stream = self.streamForConnection(connection) else {
                NSLog("Aerial Error: No matching stream for connection: \(connection)")
                return;
            }
            
            self.receiveDataForStream(stream, receivedData: data)
        }
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        dispatch_async(queue) { () -> Void in
            debugLog("connectionDidFinishLoading");
            
            guard let stream = self.streamForConnection(connection) else {
                NSLog("Aerial Error: No matching stream for connection: \(connection)")
                return;
            }
            
            guard let index = self.streams.indexOf({ $0.connection == stream.connection }) else {
                NSLog("Aerial Error: Couldn't find index of stream for finished connection!")
                return
            }
            
            self.streams.removeAtIndex(index)
            
            if self.streams.count == 0 {
                debugLog("Finished downloading!");
                self.finishedDownload()
            }
        };
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        NSLog("Aerial Error: Couldn't download video: \(error)")
        dispatch_async(queue) { () -> Void in
            self.failedDownload("Connection fail: \(error)")
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
        NSLog("Aerial Error: Didn't expect authentication challenge while downloading videos!")
        dispatch_async(queue) { () -> Void in
            self.failedDownload("Connection fail: Received authentication request!")
        }
    }
    
    // MARK: - Range
    func startOffsetFromResponse(response: NSURLResponse) -> Int? {
        // get range response
        var regex : NSRegularExpression!
        do {
            // Check to see if the server returned a valid byte-range
            regex = try NSRegularExpression(pattern: "bytes (\\d+)-\\d+/\\d+", options: NSRegularExpressionOptions.CaseInsensitive)
        } catch let error as NSError {
            NSLog("Aerial: Error formatting regex: \(error)");
            return nil;
        }
        
        let httpResponse = response as! NSHTTPURLResponse
        
        guard let contentRange = httpResponse.allHeaderFields["Content-Range"] as? NSString else {
            debugLog("Weird, no byte response: \(response)");
            return nil;
        }
        
        guard let match : NSTextCheckingResult = regex.firstMatchInString(contentRange as String, options: NSMatchingOptions.Anchored, range: NSMakeRange(0, contentRange.length)) else {
            debugLog("Weird, couldn't make a regex match for byte offset: \(contentRange)");
            return nil;
        }
        let offsetMatchRange = match.rangeAtIndex(1);
        let offsetString = contentRange.substringWithRange(offsetMatchRange) as NSString;
        
        let offset = offsetString.longLongValue;
        
//        debugLog("content range: \(contentRange), start offset: \(offset)");
        
        return Int(offset);
    }
}