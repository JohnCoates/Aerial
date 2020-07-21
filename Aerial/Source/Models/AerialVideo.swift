//
//  AerialVideo.swift
//  Aerial
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Cocoa
import AVFoundation

enum Manifests: String {
    // swiftlint:disable:next line_length
    case tvOS10 = "tvos10.json", tvOS11 = "tvos11.json", tvOS12 = "tvos12.json", tvOS13 = "tvos13.json", tvOS13Strings = "TVIdleScreenStrings13.bundle", customVideos = "customvideos.json"
}

final class AerialVideo: CustomStringConvertible, Equatable {
    static func ==(lhs: AerialVideo, rhs: AerialVideo) -> Bool {
        return lhs.id == rhs.id // TODO && lhs.url1080pHEVC == rhs.url1080pHEVC
    }

    let id: String
    let name: String
    let secondaryName: String
    let type: String
    let timeOfDay: String
    let scene: SourceScene

    var urls: [VideoFormat: String]

    let source: Source
    //var sources: [Manifests]
    let poi: [String: String]
    let communityPoi: [String: String]
    var duration: Double

    var arrayPosition = 1
    var contentLength = 0
    var contentLengthChecked = false

    var isAvailableOffline: Bool {
        return VideoCache.isAvailableOffline(video: self)
    }

    // MARK: - Public getter
    var url: URL {
        return getClosestAvailable(wanted: PrefsVideos.videoFormat)
    }

    // Returns the closest video we have in the manifests
    private func getClosestAvailable(wanted: VideoFormat) -> URL {
        if urls[wanted] != "" {
            return URL(string: urls[wanted]!)!
        } else {
            // Fallback
            if urls[.v4KHEVC] != "" {
                return URL(string: urls[.v4KHEVC]!)!

            } else if urls[.v1080pHEVC] != "" {
                return URL(string: urls[.v1080pHEVC]!)!
            } else { // Last resort
                return URL(string: urls[.v1080pH264]!)!
            }
        }
    }

    // MARK: - Init
    init(id: String,
         name: String,
         secondaryName: String,
         type: String,
         timeOfDay: String,
         scene: String,
         urls: [VideoFormat: String],
         source: Source,
         poi: [String: String],
         communityPoi: [String: String]
    ) {
        self.id = id

        // We override names for known space videos
        if SourceInfo.seaVideos.contains(id) {
            self.name = "Sea"
            if secondaryName != "" {
                self.secondaryName = secondaryName
            } else {
                self.secondaryName = name
            }
        } else if SourceInfo.spaceVideos.contains(id) {
            self.name = "Space"
            if secondaryName != "" {
                self.secondaryName = secondaryName
            } else {
                self.secondaryName = name
            }
        } else {
            // We align to the new jsons...
            if name == "New York City" {
                self.name = "New York"
            } else {
                self.name = name
            }
            self.secondaryName = secondaryName      // We may have a secondary name from our merges too now !
        }

        self.type = type

        // We override timeOfDay based on our own list
        if let val = SourceInfo.timeInformation[id] {
            self.timeOfDay = val
        } else {
            self.timeOfDay = timeOfDay
        }

        switch scene {
        case "sea":
            self.scene = .sea
        case "space":
            self.scene = .space
        case "city":
            self.scene = .city
        default:
            self.scene = .landscape
        }

        self.urls = urls
        self.source = source
        //self.sources = [manifest]
        self.poi = poi
        self.communityPoi = communityPoi
        self.duration = 0

        updateDuration()    // We need to have the video duration
    }

    func updateDuration() {
        // We need to retrieve video duration from the cached files.
        // This is a workaround as currently, the VideoCache infrastructure
        // relies on AVAsset with an external URL all the time, even when
        // working on a cached copy which makes the native duration retrieval fail

        let fileManager = FileManager.default

        // With custom videos, we may already store the local path
        // If so, check it
        if self.url.absoluteString.starts(with: "file") {
            if fileManager.fileExists(atPath: self.url.path) {
                let asset = AVAsset(url: self.url)
                self.duration = CMTimeGetSeconds(asset.duration)
            } else {
                errorLog("Custom video is missing : \(self.url.path)")
                self.duration = 0
            }
        } else {
            // If not, iterate through all possible versions to see if any is cached
            for format in VideoFormat.allCases {
                // swiftlint:disable:next for_where
                if urls[format] != "" {
                    let path = VideoCache.cachePath(forFilename: (URL(string: urls[format]!)!.lastPathComponent))!

                    if fileManager.fileExists(atPath: path) {
                        let asset = AVAsset(url: URL(fileURLWithPath: path))
                        self.duration = CMTimeGetSeconds(asset.duration)
                        //print("duration found \(self.duration)")
                        return
                    }
                }
            }

            // print("no duration for \(self)")
        }
    }

    func has4KVersion() -> Bool {
        return urls[.v4KHEVC] != ""
    }

    func getBestFormat() -> String {
        if urls[.v4KHDR] != "" {
            return "4K HDR"
        } else if urls[.v4KHEVC] != "" {
            return "4K"
        } else {
            return "1080p"
        }
    }

    var description: String {
        return """
        id=\(id),
        name=\(name),
        type=\(type),
        timeofDay=\(timeOfDay),
        urls=\(urls)
        """
    }

    func generateThumbnail() -> NSImage? {
        do {
            let path = VideoCache.cachePath(forVideo: self)!
            let asset = AVURLAsset(url: URL(fileURLWithPath: path))
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            // Select the right one based on which version you are using
            // Swift 4.2
            let cgImage = try imageGenerator.copyCGImage(at: .zero,
                                                         actualTime: nil)

            return NSImage(cgImage: cgImage, size: .init(width: 192, height: 108))
        } catch {
            print(error.localizedDescription)

            return nil
        }
    }

    func getThumbnail(_ completion: @escaping ((_ image: NSImage?) -> Void)) {

    }

    // Get Thumbnail
    func gdetThumbnail(_ completion: @escaping ((_ image: NSImage?) -> Void)) {
        if url.absoluteString.starts(with: "file://") {
            DispatchQueue.main.async {
                let asset = AVAsset(url: self.url)
                let assetImgGenerate = AVAssetImageGenerator(asset: asset)
                assetImgGenerate.appliesPreferredTrackTransform = true

                let time = CMTimeMake(value: 2, timescale: 1)
                do {
                    let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                    let thumbnail = NSImage(cgImage: img, size: .init(width: 192, height: 108))
                    completion(thumbnail)
                } catch {
                    print("Error :: ", error.localizedDescription)
                    completion(nil)
                }
            }
        } else {
            if isAvailableOffline {
                let path = VideoCache.cachePath(forVideo: self)!

                DispatchQueue.main.async {
                    let asset = AVAsset(url: URL(fileURLWithPath: path))
                    let assetImgGenerate = AVAssetImageGenerator(asset: asset)
                    assetImgGenerate.appliesPreferredTrackTransform = true

                    let time = CMTimeMake(value: 2, timescale: 1)
                    do {
                        let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                        let thumbnail = NSImage(cgImage: img, size: .init(width: 192, height: 108))
                        completion(thumbnail)
                    } catch {
                        print("Error :: ", error.localizedDescription)
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
            }
        }

    }

}
