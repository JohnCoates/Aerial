//
//  VideoLoader.swift
//  Aerial
//
//  Created by John Coates on 10/29/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import AVFoundation

protocol VideoLoaderDelegate : NSObjectProtocol {
    func videoLoader(videoLoader:VideoLoader, receivedResponse response:NSURLResponse);
    func videoLoader(videoLoader:VideoLoader, receivedData data:NSData, forRange range:NSRange);
};

class VideoLoader : NSObject, NSURLConnectionDataDelegate {
    var connection:NSURLConnection?
    var response:NSHTTPURLResponse?
    weak var delegate:VideoLoaderDelegate?
    var loadingRequest:AVAssetResourceLoadingRequest
    
    // range params
    var loadedRange:NSRange
    var requestedRange:NSRange
    var loadRange:Bool
    
    let queue = dispatch_get_main_queue()
    
    init(url:NSURL, loadingRequest:AVAssetResourceLoadingRequest, delegate:VideoLoaderDelegate) {
        self.delegate = delegate
        self.loadingRequest = loadingRequest
        
        let request = NSMutableURLRequest(URL: url);
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData;
        
        loadRange = false;
        loadedRange = NSMakeRange(0,0);
        requestedRange = NSMakeRange(0,0);
        
        if let dataRequest = loadingRequest.dataRequest {
            if dataRequest.requestedOffset > 0 {
                loadRange = true;
                let startOffset = Int(dataRequest.requestedOffset)
                let requestedBytes = Int(dataRequest.requestedLength)
                loadedRange = NSMakeRange(startOffset, 0);
                requestedRange = NSMakeRange(startOffset, requestedBytes);
                
                // set Range: bytes=startOffset-endOffset
                let requestRange = "bytes=\(requestedRange.location)-\(requestedRange.location+requestedRange.length)";
                request.setValue(requestRange, forHTTPHeaderField: "Range");
            }
        }
        
        super.init()
        
        connection = NSURLConnection(request: request, delegate: self, startImmediately: false)
        
        guard let connection = connection else {
            NSLog("Aerial error: Couldn't instantiate connection.");
            return;
        }
        
        connection.setDelegateQueue(NSOperationQueue.mainQueue());
        loadedRange = NSMakeRange(requestedRange.location, 0);
        
        connection.start();
//        debugLog("Starting request: \(request)");
    }
    
    deinit {
        connection?.cancel()
    }
    
    // MARK: - NSURLConnection Delegate
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        
        if loadRange {
            if let startOffset = startOffsetFromResponse(response) {
                loadedRange.location = startOffset;
            }
        }

        self.response = response as? NSHTTPURLResponse;
        
        dispatch_async(queue) { () -> Void in
            self.delegate?.videoLoader(self, receivedResponse: response);
            self.fillInContentInformation(self.loadingRequest)
        };
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        
        dispatch_async(queue) { () -> Void in
            
            self.fillInContentInformation(self.loadingRequest)
            
            guard let dataRequest = self.loadingRequest.dataRequest else {
                NSLog("Aerial Error: Data request missing for \(self.loadingRequest)");
                return;
            }
            let requestedRange = self.requestedRange
            let loadedRange = self.loadedRange
            let loadedLocation = loadedRange.location + loadedRange.length;
            
            let dataRange = NSMakeRange(loadedRange.location + loadedRange.length, data.length)
            self.delegate?.videoLoader(self, receivedData: data, forRange: dataRange);
            
            // check if we've already been sending content, or we're at right byte offset
            if loadedLocation >= requestedRange.location {
                
                let requestedEndOffset = Int(dataRequest.requestedOffset + dataRequest.requestedLength);
                
                let pendingDataEndOffset = loadedLocation + data.length;
                
                if (pendingDataEndOffset > requestedEndOffset) {
                    let truncateDataLength = pendingDataEndOffset - requestedEndOffset;
                    let dataRange = NSMakeRange(0, data.length - truncateDataLength);
                    
                    let truncatedData = data.subdataWithRange(dataRange);
                    
                    dataRequest.respondWithData(truncatedData);
                    self.loadingRequest.finishLoading();
                    self.connection?.cancel();
                }else {
                    dataRequest.respondWithData(data);
                }
//                debugLog("Responding with data");
            }
                // check if we're at a point now where we can send content
            else if loadedLocation + data.length >= requestedRange.location {
                // calculate how far along we need to be into the data before it's part of what
                // was requested
                let inset = requestedRange.location - loadedRange.location
                
                if inset > 0 {
                    let dataRange = NSMakeRange(inset, data.length - inset);
                    
                    let responseData = data.subdataWithRange(dataRange);
                    dataRequest.respondWithData(responseData);
                    
                    if dataRequest.currentOffset >= dataRequest.requestedOffset + dataRequest.requestedLength {
                        self.loadingRequest.finishLoading();
                        self.connection?.cancel();
                    }
                }
                else if inset < 1 {
                    NSLog("Aerial Error: Inset is invalid value: \(inset)");
                }
                
            }
            
//            debugLog("Received data with length: \(data.length)");
            
            self.loadedRange.length += data.length;
            
        }
    }

    func connectionDidFinishLoading(connection: NSURLConnection) {

        dispatch_async(queue) { () -> Void in
            debugLog("connectionDidFinishLoading");
            self.loadingRequest.finishLoading()
        };
    }
    
    func fillInContentInformation(loadingRequest:AVAssetResourceLoadingRequest) {
        
        guard let contentInformationRequest = loadingRequest.contentInformationRequest else {
            return;
        }
        
        guard let response = self.response else {
            debugLog("No response");
            return;
        }
        
        guard let mimeType = response.MIMEType else {
            debugLog("no mimeType for \(response)");
            return;
        }
        
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, nil) else {
            debugLog("couldn't create prefered identifier for tag \(mimeType)");
            return;
        }
        
        //        debugLog("Processsing contentInformationRequest");
        
        let contentType:String = uti.takeRetainedValue() as String;
        
        contentInformationRequest.byteRangeAccessSupported = true;
        contentInformationRequest.contentType = contentType;
        contentInformationRequest.contentLength = response.expectedContentLength
        
        
//        debugLog("expected content length: \(response.expectedContentLength)");
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