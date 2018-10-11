//
//  VideoLoader.swift
//  Aerial
//
//  Created by John Coates on 10/29/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import AVFoundation

protocol VideoLoaderDelegate: NSObjectProtocol {
    func videoLoader(_ videoLoader: VideoLoader, receivedResponse response: URLResponse)
    func videoLoader(_ videoLoader: VideoLoader, receivedData data: Data, forRange range: NSRange)
}

class VideoLoader: NSObject, NSURLConnectionDataDelegate {
    var connection: NSURLConnection?
    var response: HTTPURLResponse?
    weak var delegate: VideoLoaderDelegate?
    var loadingRequest: AVAssetResourceLoadingRequest
    
    // range params
    var loadedRange: NSRange
    var requestedRange: NSRange
    var loadRange: Bool
    
    let queue = DispatchQueue.main
    
    init(url: URL, loadingRequest: AVAssetResourceLoadingRequest, delegate: VideoLoaderDelegate) {
        self.delegate = delegate
        self.loadingRequest = loadingRequest
        
        let request = NSMutableURLRequest(url: url)
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        loadRange = false
        loadedRange = NSRange(location: 0, length: 0)
        requestedRange = NSRange(location: 0, length: 0)
        
        if let dataRequest = loadingRequest.dataRequest {
            if dataRequest.requestedOffset > 0 {
                loadRange = true
                let startOffset = Int(dataRequest.requestedOffset)
                let requestedBytes = Int(dataRequest.requestedLength)
                loadedRange = NSRange(location: startOffset, length: 0)
                requestedRange = NSRange(location: startOffset, length: requestedBytes)
                
                // set Range: bytes=startOffset-endOffset
                let requestRange = "bytes=\(requestedRange.location)-\(requestedRange.location+requestedRange.length)"
                request.setValue(requestRange, forHTTPHeaderField: "Range")
            }
        }
        
        super.init()
        
        connection = NSURLConnection(request: request as URLRequest, delegate: self, startImmediately: false)
        
        guard let connection = connection else {
            NSLog("Aerial error: Couldn't instantiate connection.")
            return
        }
        
        connection.setDelegateQueue(OperationQueue.main)
        loadedRange = NSRange(location: requestedRange.location, length: 0)
        
        connection.start()
//        debugLog("Starting request: \(request)")
    }
    
    deinit {
        connection?.cancel()
    }
    
    // MARK: - NSURLConnection Delegate
    
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        
        if loadRange {
            if let startOffset = startOffsetFromResponse(response) {
                loadedRange.location = startOffset
            }
        }

        self.response = response as? HTTPURLResponse
        
        queue.async { () -> Void in
            self.delegate?.videoLoader(self, receivedResponse: response)
            self.fillInContentInformation(self.loadingRequest)
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        
        queue.async { () -> Void in
            
            self.fillInContentInformation(self.loadingRequest)
            
            guard let dataRequest = self.loadingRequest.dataRequest else {
                NSLog("Aerial Error: Data request missing for \(self.loadingRequest)")
                return
            }
            let requestedRange = self.requestedRange
            let loadedRange = self.loadedRange
            let loadedLocation = loadedRange.location + loadedRange.length
            
            let dataRange = NSRange(location: loadedRange.location + loadedRange.length,
                                    length: data.count)
            self.delegate?.videoLoader(self, receivedData: data, forRange: dataRange)
            
            // check if we've already been sending content, or we're at right byte offset
            if loadedLocation >= requestedRange.location {
                
                let requestedEndOffset = Int(dataRequest.requestedOffset + Int64(dataRequest.requestedLength))
                
                let pendingDataEndOffset = loadedLocation + data.count
                
                if pendingDataEndOffset > requestedEndOffset {
                    let truncateDataLength = pendingDataEndOffset - requestedEndOffset
                    let truncatedData = data.subdata(in: 0..<data.count - truncateDataLength)
                    
                    dataRequest.respond(with: truncatedData)
                    self.loadingRequest.finishLoading()
                    self.connection?.cancel()
                } else {
                    dataRequest.respond(with: data)
                }
//                debugLog("Responding with data")
            }
                // check if we're at a point now where we can send content
            else if loadedLocation + data.count >= requestedRange.location {
                // calculate how far along we need to be into the data before it's part of what
                // was requested
                let inset = requestedRange.location - loadedRange.location
                
                if inset > 0 {
                    let start = inset
                    let length = data.count - inset
                    let end = start + length
                    let responseData = data.subdata(in: inset..<end)
                    dataRequest.respond(with: responseData)
                    
                    if dataRequest.currentOffset >= dataRequest.requestedOffset + Int64(dataRequest.requestedLength) {
                        self.loadingRequest.finishLoading()
                        self.connection?.cancel()
                    }
                } else if inset < 1 {
                    NSLog("Aerial Error: Inset is invalid value: \(inset)")
                }
                
            }
            
//            debugLog("Received data with length: \(data.count)")
            
            self.loadedRange.length += data.count
            
        }
    }

    func connectionDidFinishLoading(_ connection: NSURLConnection) {

        queue.async { () -> Void in
            debugLog("connectionDidFinishLoading")
            self.loadingRequest.finishLoading()
        }
    }
    
    func fillInContentInformation(_ loadingRequest: AVAssetResourceLoadingRequest) {
        
        guard let contentInformationRequest = loadingRequest.contentInformationRequest else {
            return
        }
        
        guard let response = self.response else {
            debugLog("No response")
            return
        }
        
        guard let mimeType = response.mimeType else {
            debugLog("no mimeType for \(response)")
            return
        }
        
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil) else {
            debugLog("couldn't create prefered identifier for tag \(mimeType)")
            return
        }
        
        //        debugLog("Processsing contentInformationRequest")
        
        let contentType: String = uti.takeRetainedValue() as String
        
        contentInformationRequest.isByteRangeAccessSupported = true
        contentInformationRequest.contentType = contentType
        contentInformationRequest.contentLength = response.expectedContentLength
        
        //debugLog("expected content length: \(response.expectedContentLength)")
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
        let offsetMatchRange = match.range(at: 1)
        let offsetString = contentRange.substring(with: offsetMatchRange) as NSString
        
        let offset = offsetString.longLongValue
        
//        debugLog("content range: \(contentRange), start offset: \(offset)")
        
        return Int(offset)
    }

}
