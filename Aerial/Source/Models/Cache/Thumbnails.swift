//
//  Thumbnails.swift
//  Aerial
//
//  Created by Guillaume Louel on 20/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import AVKit

struct Thumbnails {
    static let thumbSize = CGSize.init(width: 192, height: 108)
    /**
     Generate a thumbnail for the video
     
     When a video is not available offline, it will also save a larger version
     of the first frame of the video, to be used later in the UI as a placeholder
     */
    static func generate(forVideo video: AerialVideo) {
        do {
            var asset: AVURLAsset
            if video.isAvailableOffline {
                let path = VideoCache.cachePath(forVideo: video)!
                asset = AVURLAsset(url: URL(fileURLWithPath: path))
            } else {
                asset = AVURLAsset(url: video.url)
            }

            // maybe that doesn't work great with HDR, or a Big Sur thing ?
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true

            let cgImage = try imageGenerator.copyCGImage(at: .zero,
                                                         actualTime: nil)

            let saveURL = URL(fileURLWithPath: getPath(forVideo: video))

            try writeImage(image: NSImage(cgImage: cgImage, size: thumbSize),
                           usingType: .png,
                           withSizeInPixels: thumbSize,
                           to: saveURL)

            if !video.isAvailableOffline {
                let largeURL = URL(fileURLWithPath: getLargePath(forVideo: video))
                let fullSize = CGSize.init(width: cgImage.width, height: cgImage.height)

                try writeImage(image: NSImage(cgImage: cgImage, size: fullSize),
                               usingType: .jpeg,
                               withSizeInPixels: fullSize,
                               to: largeURL)
            }
        } catch {
            errorLog(error.localizedDescription)
        }
    }

    static private func unscaledBitmapImageRep(forImage image: NSImage) -> NSBitmapImageRep {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(image.size.width),
            pixelsHigh: Int(image.size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
            ) else {
                preconditionFailure()
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        return rep
    }

    static private func writeImage(
        image: NSImage,
        usingType type: NSBitmapImageRep.FileType,
        withSizeInPixels size: NSSize?,
        to url: URL) throws {
        if let size = size {
            image.size = size
        }
        let rep = unscaledBitmapImageRep(forImage: image)

        guard let data = rep.representation(using: type, properties: [.compressionFactor: 1.0]) else {
            preconditionFailure()
        }

        try data.write(to: url)
    }

    /**
     
     */
    static func cached(forVideo video: AerialVideo) -> NSImage? {
        let candidateThumb = getPath(forVideo: video)
        if FileManager.default.fileExists(atPath: candidateThumb) {
            return NSImage(contentsOfFile: candidateThumb)
        } else {
            return nil
        }
    }

    static private func getPath(forVideo video: AerialVideo) -> String {
        return Cache.thumbnailsPath.appending("/"+video.id+".png")
    }

    static private func getLargePath(forVideo video: AerialVideo) -> String {
        return Cache.thumbnailsPath.appending("/"+video.id+"-large.jpg")
    }

    static func get(forVideo video: AerialVideo, _ completion: @escaping ((_ image: NSImage?) -> Void)) {
        if let thumb = cached(forVideo: video) {
            completion(thumb)
        } else if video.isAvailableOffline {
            DispatchQueue.main.async {
                generate(forVideo: video)
                completion(cached(forVideo: video))
            }
        } else {
            if Cache.canNetwork() {
                DispatchQueue.main.async {
                    generate(forVideo: video)
                    completion(cached(forVideo: video))
                }
            } else {
                completion(nil)
            }
        }
    }

    static func getLarge(forVideo video: AerialVideo, _ completion: @escaping ((_ image: NSImage?) -> Void)) {
        let candidateLarge = getLargePath(forVideo: video)
        if FileManager.default.fileExists(atPath: candidateLarge) {
            return completion(NSImage(contentsOfFile: candidateLarge))
        } else {
            // This may happen in a race...
            return completion(nil)
        }
    }
}
