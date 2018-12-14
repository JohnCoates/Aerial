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
func cachedOrCachingAsset(_ URL: Foundation.URL) -> AVURLAsset {
    let assetLoader = AssetLoaderDelegate(URL: URL)
    let asset = AVURLAsset(url: assetLoader.URLWithCustomScheme)
    let queue = DispatchQueue.main
    asset.resourceLoader.setDelegate(assetLoader, queue: queue)
    objc_setAssociatedObject(asset, "assetLoader", assetLoader, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    //debugLog("\(asset)")
    return asset
}

final class AssetLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, VideoLoaderDelegate {

    let URL: Foundation.URL
    var videoLoaders: [VideoLoader] = []
    let videoCache: VideoCache

    var URLWithCustomScheme: Foundation.URL {
        var components = URLComponents(url: URL, resolvingAgainstBaseURL: false)!
        components.scheme = "streaming"
        return components.url!
    }

    init(URL: Foundation.URL) {
        self.URL = URL
        videoCache = VideoCache(URL: URL)
    }

    deinit {
        debugLog("AssetLoaderDelegate deinit")
    }

    // MARK: - Video Loader Delegate

    func videoLoader(_ videoLoader: VideoLoader, receivedResponse response: URLResponse) {
        videoCache.receivedContentLength(Int(response.expectedContentLength))
    }

    func videoLoader(_ videoLoader: VideoLoader, receivedData data: Data, forRange range: NSRange) {
        videoCache.receivedData(data, atRange: range)
    }

    // MARK: - Asset Resource Loader Delegate
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        didCancel loadingRequest: AVAssetResourceLoadingRequest) {
//        debugLog("cancelled load request: \(loadingRequest)")

        var remove: VideoLoader?
        for loader in videoLoaders {
            if loader.loadingRequest != loadingRequest {
                continue
            }

            if let connection = loader.connection {
                connection.cancel()
            }

            remove = loader
            break
        }

        if let removeLoader = remove {
            if let index = videoLoaders.index(of: removeLoader) {
                videoLoaders.remove(at: index)
            }
        }
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource
        loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        /*
        // check if cache can fulfill this without a request
        if videoCache.canFulfillLoadingRequest(loadingRequest) {
            if videoCache.fulfillLoadingRequest(loadingRequest) {
                debugLog("fullfilling loading request")
                return true
            }
        }*/

        // assign request to VideoLoader
        //debugLog("request to loader \(loadingRequest)")
        let videoLoader = VideoLoader(url: URL, loadingRequest: loadingRequest, delegate: self)
        videoLoaders.append(videoLoader)

        return true
    }
}
