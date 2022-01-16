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
    // var sources: [Manifests]
    let poi: [String: String]
    let communityPoi: [String: String]
    var duration: Double

    var arrayPosition = 1
    var contentLength = 0
    var contentLengthChecked = false

    var isVertical: Bool

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
            return getURL(string: urls[wanted]!)
        } else {
            // Fallback
            if urls[.v4KHEVC] != "" {
                return getURL(string: urls[.v4KHEVC]!)
            } else if urls[.v1080pHEVC] != "" {
                return getURL(string: urls[.v1080pHEVC]!)
            } else if urls[.v1080pH264] != "" { // Last resort
                return getURL(string: urls[.v1080pH264]!)
            } else {
                return getURL(string: urls[.v4KHDR]!)
            }
        }
    }
    private func getURL(string: String) -> URL {
        if string.starts(with: "/") {
            return URL(fileURLWithPath: string)
        } else {
            return URL(string: string)!
        }
    }

    // swiftlint:disable cyclomatic_complexity
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
        case "countryside":
            self.scene = .countryside
        case "beach":
            self.scene = .beach
        default:
            self.scene = .nature
        }

        self.urls = urls
        self.source = source
        // self.sources = [manifest]
        self.poi = poi
        self.communityPoi = communityPoi

        // Default stuff, we double check those below
        self.duration = 0
        self.isVertical = false

        updateDuration()    // We need to have the video duration
    }

    func updateDuration() {
        // We need to retrieve video duration from the cached files.
        // This is a workaround as currently, the VideoCache infrastructure
        // relies on AVAsset with an external URL all the time, even when
        // working on a cached copy which makes the native duration retrieval fail
        //
        // And... we also check the orientation now too ;)

        let fileManager = FileManager.default

        if let duration = PrefsVideos.durationCache[self.id] {
            // debugLog("Using cache duration : \(duration)")
            self.duration = duration
            return
        }

        // With custom videos, we may already store the local path
        // If so, check it
        if self.url.absoluteString.starts(with: "file") {
            if fileManager.fileExists(atPath: self.url.path) {
                let asset = AVAsset(url: self.url)
                self.duration = CMTimeGetSeconds(asset.duration)
                self.isVertical = asset.isVertical()
            } else {
                errorLog("Custom video is missing : \(self.url.path)")
                self.duration = 0
            }
        } else {
            // If not, iterate through all possible versions to see if any is cached
            for format in VideoFormat.allCases {
                // swiftlint:disable:next for_where
                if urls[format] != "" {

                    let path = VideoList.instance.localPathFor(video: self)

                    if fileManager.fileExists(atPath: path) {
                        let asset = AVAsset(url: URL(fileURLWithPath: path))
                        self.duration = CMTimeGetSeconds(asset.duration)

                        // debugLog("Caching video duration")
                        PrefsVideos.durationCache[self.id] = self.duration

                        return
                    }
                }
            }
        }
    }

    /// Check if a video has HDR files or not
    func hasHDR() -> Bool {
        if urls[.v1080pHDR] != "" || urls[.v4KHDR] != "" {
            return true
        } else {
            return false
        }

    }

    /// Check if what we are playing is HDR or not
    func isHDR() -> Bool {
        if urls[.v1080pHDR] != "" {
            if url == URL(string: urls[.v1080pHDR]!) {
                return true
            }
        }

        if urls[.v4KHDR] != "" {
            if url == URL(string: urls[.v4KHDR]!) {
                return true
            }
        }

        return false
    }

    func getCurrentFormat() -> String {
        let wanted = PrefsVideos.videoFormat
        if urls[wanted] != "" {
            switch wanted {
            case .v4KHDR:
                return "4K HDR"
            case .v1080pH264:
                return "1080p"
            case .v1080pHEVC:
                return "1080p"
            case .v1080pHDR:
                return "1080p HDR"
            case .v4KHEVC:
                return "4K"
            }
        } else {
            return getBestFormat()
        }
    }

    private func getBestFormat() -> String {
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
}
