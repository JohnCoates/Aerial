//
//  VideoDownload.swift
//  Aerial
//
//  Created by John Coates on 10/31/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation

protocol VideoDownloadDelegate: NSObjectProtocol {
    func videoDownload(_ videoDownload: VideoDownload,
                       finished success: Bool, errorMessage: String?)
    // bytes received for bytes/second count
    func videoDownload(_ videoDownload: VideoDownload,
                       receivedBytes: Int, progress: Float)
}

class VideoDownloadStream {
    var connection: NSURLConnection
    var response: URLResponse?
    var contentInformationRequest: Bool = false
    var downloadOffset = 0
    
    init(connection: NSURLConnection) {
        self.connection = connection
    }
    deinit {
        connection.cancel()
    }
}

class VideoDownload: NSObject, NSURLConnectionDataDelegate {
    var streams: [VideoDownloadStream] = []
    weak var delegate: VideoDownloadDelegate!

    let queue = DispatchQueue.main
    
    let video: AerialVideo
    
    var data: NSMutableData?
    var downloadedData: Int = 0
    var contentLength: Int = 0
    
    init(video: AerialVideo, delegate: VideoDownloadDelegate) {
        self.video = video
        self.delegate = delegate
    }
    
    func startDownload() {
        // first start content information download
        startDownloadForContentInformation()
    }
    
    // download a couple bytes to get the content length
    func startDownloadForContentInformation() {
        startDownloadForChunk(nil)
    }
    
    func startDownloadForChunk(_ chunk: NSRange?) {
        let request = NSMutableURLRequest(url: video.url as URL)
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        if let requestedRange = chunk {
            // set Range: bytes=startOffset-endOffset
            let requestRangeField = "bytes=\(requestedRange.location)-\(requestedRange.location+requestedRange.length)"
            request.setValue(requestRangeField, forHTTPHeaderField: "Range")
            debugLog("Starting download for range \(requestRangeField)")
        }
        
        guard let connection = NSURLConnection(request: request as URLRequest,
                                               delegate: self, startImmediately: false) else {
            NSLog("Aerial: Error creating connection with request: \(request)")
            return
        }
        
        let stream = VideoDownloadStream(connection: connection)
        
        if chunk == nil {
            debugLog("Starting download for content information")
            stream.contentInformationRequest = true
        }
        
        connection.start()
        
        streams.append(stream)
        
    }
    
    func streamForConnection(_ connection: NSURLConnection) -> VideoDownloadStream? {
        for stream in streams {
            if stream.connection == connection {
                return stream
            }
        }
        
        return nil
    }
    
    func createStreamsBasedOnContentLength(_ contentLength: Int) {
        self.contentLength = contentLength
        // remove content length request stream
        streams.removeFirst()
        
        data = NSMutableData(length: contentLength)
        
        // start 4 streams for maximum throughput
        let streamCount = 4
        let pace = 0.2; // pace stream creation a little bit
        let streamPiece = Int(floor(Double(contentLength) / Double(streamCount)))
        debugLog("Starting \(streamCount) streams with \(streamPiece) each, for content length of \(contentLength)")
        var offset = 0
        
        var delayTime: Double = 0
        
//        let queue = DispatchQueue.main
        for i in 0 ..< streamCount {
            let isLastStream: Bool = i == (streamCount - 1)
            var range = NSRange(location: offset, length: streamPiece)
            
            if isLastStream {
                let bytesLeft = contentLength - offset
                range = NSRange(location: offset, length: bytesLeft)
                debugLog("last stream range: \(range)")
            }

            let delay = DispatchTime.now() + Double(Int64(delayTime * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            queue.asyncAfter(deadline: delay) {
                self.startDownloadForChunk(range)
            }
            
            // increase delay
            delayTime += pace
            
            // increase offset
            offset += range.length

        }
    }
    
    func receiveDataForStream(_ stream: VideoDownloadStream, receivedData: Data) {
        guard let videoData = self.data else {
            NSLog("Aerial error: video data missing!")
            return
        }
        
        let replaceRange = NSRange(location: stream.downloadOffset,
                                   length: receivedData.count)
        videoData.replaceBytes(in: replaceRange, withBytes: (receivedData as NSData).bytes)
        stream.downloadOffset += receivedData.count
    }
    
    func finishedDownload() {
        guard let videoCachePath = VideoCache.cachePath(forVideo: video) else {
            print("Aerial Error: Couldn't save video because couldn't get cache path\n")
            failedDownload("Couldn't get cache path")
            return
        }
        
        guard let videoData = self.data else {
            print("Aerial error: video data missing!\n")
            return
        }
        
        var success: Bool = true
        var errorMessage: String?
        do {
            try videoData.write(toFile: videoCachePath, options: .atomicWrite)
        } catch let error {
            NSLog("Aerial Error: Couldn't write cache file: \(error)")
            errorMessage = "Couldn't write to cache file!"
            success = false
        }
        
        // notify delegate
        delegate.videoDownload(self, finished: success, errorMessage: errorMessage)
        
    }
    
    func failedDownload(_ errorMessage: String) {
        
        delegate.videoDownload(self, finished: false, errorMessage: errorMessage)
    }
    
    // MARK: - NSURLConnection Delegate
    
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        guard let stream = streamForConnection(connection) else {
            NSLog("Aerial Error: No matching stream for connection: \(connection) with response: \(response)")
            return
        }
        
        stream.response = response as? HTTPURLResponse
        
        if stream.contentInformationRequest == true {
            connection.cancel()
            
            queue.async(execute: { () -> Void in
                let contentLength = Int(response.expectedContentLength)
                self.createStreamsBasedOnContentLength(contentLength)
            })
            
            return
        } else {
            // get real offset of receiving data
            
            queue.async(execute: { () -> Void in
                guard let offset = self.startOffsetFromResponse(response) else {
                    NSLog("Aerial Error: Couldn't get start offset from response: \(response)")
                    return
                }
                
                stream.downloadOffset = offset
            })
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        guard let delegate = self.delegate else {
            return
        }
        
        queue.async { () -> Void in
            self.downloadedData += data.count
            let progress: Float = Float(self.downloadedData) / Float(self.contentLength)
            delegate.videoDownload(self, receivedBytes: data.count, progress: progress)
            
            guard let stream = self.streamForConnection(connection) else {
                NSLog("Aerial Error: No matching stream for connection: \(connection)")
                return
            }
            
            self.receiveDataForStream(stream, receivedData: data)
        }
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        queue.async { () -> Void in
            debugLog("connectionDidFinishLoading")
            
            guard let stream = self.streamForConnection(connection) else {
                NSLog("Aerial Error: No matching stream for connection: \(connection)")
                return
            }
            
            guard let index = self.streams.index(where: { $0.connection == stream.connection }) else {
                NSLog("Aerial Error: Couldn't find index of stream for finished connection!")
                return
            }
            
            self.streams.remove(at: index)
            
            if self.streams.count == 0 {
                debugLog("Finished downloading!")
                self.finishedDownload()
            }
        }
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        NSLog("Aerial Error: Couldn't download video: \(error)")
        queue.async { () -> Void in
            self.failedDownload("Connection fail: \(error)")
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive challenge: URLAuthenticationChallenge) {
        NSLog("Aerial Error: Didn't expect authentication challenge while downloading videos!")
        queue.async { () -> Void in
            self.failedDownload("Connection fail: Received authentication request!")
        }
    }
    
    // MARK: - Range
    func startOffsetFromResponse(_ response: URLResponse) -> Int? {
        // get range response
        var regex: NSRegularExpression!
        do {
            // Check to see if the server returned a valid byte-range
            regex = try NSRegularExpression(pattern: "bytes (\\d+)-\\d+/\\d+",
                                            options: NSRegularExpression.Options.caseInsensitive)
        } catch let error as NSError {
            NSLog("Aerial: Error formatting regex: \(error)")
            return nil
        }
        
        let httpResponse = response as! HTTPURLResponse
        
        guard let contentRange = httpResponse.allHeaderFields["Content-Range"] as? NSString else {
            debugLog("Weird, no byte response: \(response)")
            return nil
        }
        
        guard let match = regex.firstMatch(in: contentRange as String,
                                           options: NSRegularExpression.MatchingOptions.anchored,
                                           range: NSRange(location:0, length: contentRange.length)) else {
            debugLog("Weird, couldn't make a regex match for byte offset: \(contentRange)")
            return nil
        }
        let offsetMatchRange = match.rangeAt(1)
        let offsetString = contentRange.substring(with: offsetMatchRange) as NSString
        
        let offset = offsetString.longLongValue
        
//        debugLog("content range: \(contentRange), start offset: \(offset)")
        
        return Int(offset)
    }
}
