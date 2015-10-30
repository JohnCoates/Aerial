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
    let queue = dispatch_get_main_queue();
    asset.resourceLoader.setDelegate(assetLoader, queue: queue)
    objc_setAssociatedObject(asset, "assetLoader", assetLoader, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN);
    
    return asset
}


class AssetLoaderDelegate : NSObject, AVAssetResourceLoaderDelegate, VideoLoaderDelegate {
 
    let URL:NSURL
    var videoLoaders:[VideoLoader] = []
    let videoCache:VideoCache
    
    var URLWithCustomScheme:NSURL {
        let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)!;
        components.scheme = "streaming";
        return components.URL!;
    }

    init(URL:NSURL) {
        self.URL = URL;
//        self.URL = NSURL(string:"http://localhost/test.mov")!
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
    
    // MARK: - Asset Resource Loader Delegate
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
        
        // check if cache can fullfill this without a request
        if videoCache.canFulfillLoadingRequest(loadingRequest) {
            if videoCache.fulfillLoadingRequest(loadingRequest) {
                return true;
            }
        }
        
        // assign request to VideoLoader
        
        let videoLoader = VideoLoader(url: URL, loadingRequest: loadingRequest, delegate: self);
        videoLoaders.append(videoLoader);
        
        return true;
    }
    
}