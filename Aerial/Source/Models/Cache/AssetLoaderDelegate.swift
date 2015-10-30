//
//  AssetLoaderDelegate.swift
//  Aerial
//

// This class adapted from https://github.com/renjithn/AVAssetResourceLoader-Video-Example

import Foundation
import AVKit
import AVFoundation

/// Returns an AVURLAsset that is automatically cached. If already cached
/// then returns the cached asset.
func CachedOrCachingAsset(URL:NSURL) -> AVURLAsset {
    let assetLoader = AssetLoaderDelegate(URL: URL);
    
    let asset = AVURLAsset(URL: assetLoader.URLWithCustomScheme);
//    let queue = dispatch_get_main_queue()
    let queue = dispatch_get_main_queue();
    asset.resourceLoader.setDelegate(assetLoader, queue: queue)
    objc_setAssociatedObject(asset, "assetLoader", assetLoader, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN);
    
    return asset
}

enum LoadRangeConnectionError: ErrorType {
    case InvalidDataRequest
}
class LoadRangeConnection {
    var requestedRange:NSRange
    var loadedRange:NSRange
    let connection:NSURLConnection
    var dataRequest:AVAssetResourceLoadingDataRequest
    var response:NSURLResponse?
    var finished:Bool = false
    
    init(parent:AssetLoaderDelegate, dataRequest: AVAssetResourceLoadingDataRequest) {
        self.dataRequest = dataRequest
        requestedRange = NSMakeRange(Int(dataRequest.requestedOffset), Int(dataRequest.requestedLength));
        
        let request = NSMutableURLRequest(URL: parent.URL);
        // set Range: bytes=startOffset-endOffset
        let requestRange = "bytes=\(requestedRange.location)-\(requestedRange.location+requestedRange.length)";
        debugLog("requestRange: \(requestRange)");
        request.setValue(requestRange, forHTTPHeaderField: "Range");
        
        debugLog("New request with range \(requestedRange)")
        
        connection = NSURLConnection(request: request, delegate: parent, startImmediately: false)!
        connection.setDelegateQueue(NSOperationQueue.mainQueue());
        loadedRange = NSMakeRange(requestedRange.location, 0);
        
        connection.start();
        
    }
}


class AssetLoaderDelegate : NSObject, AVAssetResourceLoaderDelegate, NSURLConnectionDataDelegate, VideoLoaderDelegate {
 
    let URL:NSURL
    var connection:NSURLConnection?
    var pendingRequests:[AVAssetResourceLoadingRequest] = []
    var response:NSHTTPURLResponse?
    var movieData:NSMutableData?
    var finishedLoading:Bool = false
    var rangeLoads:[LoadRangeConnection] = []
    var videoLoaders:[VideoLoader] = []
    let videoCache:VideoCache
    
    // byte offset of data loaded on main connection
    var mainConnectionOffset:Int = 0;
    
    var URLWithCustomScheme:NSURL {
        let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)!;
        components.scheme = "streaming";
        return components.URL!;
    }

    init(URL:NSURL) {
//        self.URL = URL;
        self.URL = NSURL(string:"http://localhost/test.mov")!
        videoCache = VideoCache(URL: URL)
    }
    
    deinit {
        debugLog("AssetLoaderDelegate deinit");
    }
    
    // MARK: - Video Loader Delegate
    func videoLoader(videoLoader:VideoLoader, receivedResponse response:NSURLResponse) {
        videoCache.receivedContentLength(Int(response.expectedContentLength))
    }
    func videoLoader(videoLoader:VideoLoader, receivedData data:NSData, forRange range:NSRange) {
        videoCache.receivedData(data, atRange: range)
    }
    
    // MARK: - NSURLConnection Delegate
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        debugLog("response: \(response)");
        
        if connection != self.connection {
            if let rangeLoad = rangeLoadForConnection(connection) {
                rangeLoad.response = response;

                // get range response
                
                 var regex : NSRegularExpression!
                do {
                    // Check to see if the server returned a valid byte-range
                    regex = try NSRegularExpression(pattern: "bytes (\\d+)-\\d+/\\d+", options: NSRegularExpressionOptions.CaseInsensitive)
                } catch let error as NSError {
                    NSLog("Aerial: Error formatting regex: \(error)");
                    return;
                }
                
                let httpResponse = response as! NSHTTPURLResponse
                
                guard let contentRange = httpResponse.allHeaderFields["Content-Range"] as? NSString else {
                    return;
                }
                
                guard let match : NSTextCheckingResult = regex.firstMatchInString(contentRange as String, options: NSMatchingOptions.Anchored, range: NSMakeRange(0, contentRange.length)) else {
                    return;
                }
                let offsetMatchRange = match.rangeAtIndex(1);
                let offsetString = contentRange.substringWithRange(offsetMatchRange) as NSString;
                
                let offset = offsetString.longLongValue;
                
                rangeLoad.requestedRange.location = Int(offset);
                rangeLoad.loadedRange.location = Int(offset);
                
                debugLog("content range: \(contentRange), start offset: \(offset)");
             
                return;
            }
        }
        
        movieData = NSMutableData(length: Int(response.expectedContentLength));
        self.response = response as? NSHTTPURLResponse;
        
        guard self.response != nil else {
            NSLog("Aerial error: \(response) is not NSHTTPURLResponse");
            return;
        }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.processPendingRequests()
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        guard let movieData = self.movieData else {
            NSLog("Aerial error: received data, but no movieData to put it in.");
            return;
        }
        
        // mutate data always on the same thread!
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if (self.connection == connection) {
                let replacementRange = NSMakeRange(self.mainConnectionOffset, data.length);
                movieData.replaceBytesInRange(replacementRange, withBytes: data.bytes, length: data.length);
                self.mainConnectionOffset += data.length;
            }
            else {
                guard let rangeLoad = self.rangeLoadForConnection(connection) else {
                    NSLog("Aerial Error: Couldn't find rangeLoad to match connection: \(connection)");
                    return;
                }
                let currentOffset = rangeLoad.requestedRange.location + rangeLoad.loadedRange.length;
                let replacementRange = NSMakeRange(currentOffset, data.length);
                
//                debugLog("received \(data.length) from offset \(currentOffset). start: \(rangeLoad.requestedRange.location)");
                movieData.replaceBytesInRange(replacementRange, withBytes: data.bytes, length: data.length);
                rangeLoad.loadedRange.length += data.length;
                
            }
        
            self.processPendingRequests()
        }
    }
    
    func rangeLoadForConnection(connection:NSURLConnection) -> LoadRangeConnection? {
        var rangeLoadFound:LoadRangeConnection?
        var found = 0
        for rangeLoad in rangeLoads {
            
            if rangeLoad.finished {
                continue;
            }
            
            if rangeLoad.connection == connection {
                rangeLoadFound = rangeLoad;
                found++
                if (found > 1) {
                    NSLog("found two range loads with same connection??!?! \(rangeLoad.connection) vs \(connection)");
                }
            }
        }
        
        
        
        return rangeLoadFound;
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        
        if (connection != self.connection) {
            if let rangeLoad = rangeLoadForConnection(connection) {
                rangeLoad.finished = true;
            }
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.processPendingRequests()
            }
            return;
        }
        
        finishedLoading = true;
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.processPendingRequests()
        }
        
        debugLog("Download Complete!");
        guard let filename = URL.lastPathComponent else {
            NSLog("Couldn't get filename from \(URL)");
            return;
        }
        
        debugLog("caching filename: \(filename)");
    }
    
    // MARK: - AVURLAsset Resource Loading
    
    func processPendingRequests() {
//        debugLog("processPendingRequests: \(pendingRequests.count)");
        var requestsCompleted:[AVAssetResourceLoadingRequest] = []
        
        
        for loadingRequest in pendingRequests {
            guard let dataRequest = loadingRequest.dataRequest else {
                debugLog("couldn't get dataRequest");
                continue;
            }
            
            fillInContentInformation(loadingRequest);
            
            let didRespondCompletely = respondWithDataForRequest(dataRequest);
            
            if didRespondCompletely {
                requestsCompleted.append(loadingRequest)
                debugLog("marking request as finished loading");
                loadingRequest.finishLoading()
            }
        }
        
        
        // remove completed requests
        for request in requestsCompleted {
            if pendingRequests.contains(request) == false {
                continue;
            }
            
            guard let index = pendingRequests.indexOf(request) else {
                continue;
            }
            
            pendingRequests.removeAtIndex(index);
        }
    }
    
    func fillInContentInformation(loadingRequest:AVAssetResourceLoadingRequest) {
        
        guard let contentInformationRequest = loadingRequest.contentInformationRequest else {
            return;
        }
        
        guard let dataRequest = loadingRequest.dataRequest else {
            return;
        }
        
        var responseOptional:NSURLResponse? = self.response
        
        for rangeLoad in rangeLoads {
            if (rangeLoad.dataRequest == dataRequest) {
                responseOptional = rangeLoad.response
            }
        }
        
        guard let response = responseOptional else {
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
        
        
//        debugLog("content type: \(contentType)");
        debugLog("expected content length: \(response.expectedContentLength)");
//        debugLog("response: \(response)");
    }
    
    func respondWithDataForRequest(dataRequest:AVAssetResourceLoadingDataRequest) -> Bool {
        var startOffset = Int(dataRequest.requestedOffset);
        
        if dataRequest.currentOffset != 0 {
            startOffset = Int(dataRequest.currentOffset);
        }
        
        guard let movieData = self.movieData else {
            NSLog("Aerial error: No movieData!");
            return false;
        }
        
        var loadedLength = 0;
        
        if (mainConnectionOffset >= startOffset) {
            loadedLength = mainConnectionOffset - startOffset;
        }
        else {
            for rangeLoad in rangeLoads {
                let loadedRange = rangeLoad.loadedRange
                debugLog("checking if \(loadedRange) >= \(startOffset)");
                if loadedRange.location + loadedRange.length >= startOffset {
                    loadedLength = (loadedRange.location + loadedRange.length) - startOffset;
                    break;
                }
            }
        }
        
        // Don't have any data at all for this request
        if loadedLength <= 0 && dataRequest.requestedOffset > 0 {
//            debugLog("startOffset requested: \(startOffset), only \(movieData.length) has been downloaded");
            
            // check if a rangeLoad exists already
            for rangeLoad in rangeLoads {
                if (rangeLoad.dataRequest == dataRequest) {
                    return false;
                }
            }
            
            // create new range load
            let rangeLoad = LoadRangeConnection(parent: self, dataRequest: dataRequest );
            rangeLoads.append(rangeLoad);
            return false;
        }

        if loadedLength <= 0 {
            return false;
        }
        // Respond with whatever is available if we can't satisfy the request fully yet
        let numberOfBytesToRespondWith = min(dataRequest.requestedLength, loadedLength);
        
        debugLog("data: \(movieData.length), startOffset:\(startOffset), toRespondWith:\(numberOfBytesToRespondWith) requested: \(dataRequest.requestedLength)");
        let dataRange = NSMakeRange(Int(startOffset), Int(numberOfBytesToRespondWith))
        
        guard let responseData = self.movieData?.subdataWithRange(dataRange) else {
            NSLog("Aerial Error: Couldn't get subdata");
            return false;
        }
        
        dataRequest.respondWithData(responseData);
//        debugLog("responding with data w/ length: \(responseData.length)");
        
        let endOffset = startOffset + dataRequest.requestedLength;
        let didRespondfully = startOffset + numberOfBytesToRespondWith >= endOffset;
        
//        debugLog("endOffset: \(endOffset)");
        return didRespondfully;
        
//        return didRespondfully;
    }
    
    // MARK: - Delegate Methods
    func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
        debugLog("cancelled load request: \(loadingRequest)");
        
        var remove:VideoLoader?
        for loader in videoLoaders {
            if loader.loadingRequest != loadingRequest {
                continue;
            }
            
            if let connection = loader.connection {
                connection.cancel();
            }
            
            remove = loader;
            break;
        }
        
        if let removeLoader = remove {
            if let index = videoLoaders.indexOf(removeLoader) {
                videoLoaders.removeAtIndex(index);
            }
        }
    }
    
    func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
//        pendingRequests.append(loadingRequest);
//        debugLog("new request, now \(pendingRequests.count) pending requests")
        
        if videoCache.canFulfillLoadingRequest(loadingRequest) {
            if videoCache.fulfillLoadingRequest(loadingRequest) {
                return true;
            }
        }
        
        let videoLoader = VideoLoader(url: URL, loadingRequest: loadingRequest, delegate: self);
        
        videoLoaders.append(videoLoader);
        
//        if self.connection == nil {
//            finishedLoading = false;
//            let interceptedURL = loadingRequest.request.URL!;
//            let actualURLComponents = NSURLComponents(URL: interceptedURL, resolvingAgainstBaseURL: false)!;
//            actualURLComponents.scheme = "http";
//            let request = NSURLRequest(URL: actualURLComponents.URL!);
//            debugLog("loading request for \(request)");
//            connection = NSURLConnection(request: request, delegate: self, startImmediately: false)
//            connection?.setDelegateQueue(NSOperationQueue.mainQueue());
//            connection?.start();
//        }
//        else {
//            processPendingRequests();
//        }
        
        return true;
    }
    
}