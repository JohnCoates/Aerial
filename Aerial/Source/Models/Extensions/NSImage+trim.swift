//
//  NSImage+trim.swift
//  Aerial
//
//  Created by Guillaume Louel on 23/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

extension NSImage {
    func trim() -> NSImage? {
        var imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        let imageRef = self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)

        let trimTo = self.getTrimmedRect()
        // let cutRef = imageRef?.cropping(to: trimTo)

        guard let cutRef = imageRef?.cropping(to: trimTo) else {
            return nil
        }

        return NSImage(cgImage: cutRef, size: trimTo.size)
    }

    // There might be a better way to do this but that's all I found...
    // swiftlint:disable:next cyclomatic_complexity
    private func getTrimmedRect() -> CGRect {
        let bmp = self.representations[0] as! NSBitmapImageRep
        let data: UnsafeMutablePointer<UInt8> = bmp.bitmapData!
        var alpha: UInt8

        var topCrop = 0
        var bottomCrop = bmp.pixelsHigh
        var leftCrop = 0
        var rightCrop = bmp.pixelsWide

        // Top crop
        outerTop: for row in 0..<bmp.pixelsHigh {
            for col in 0..<bmp.pixelsWide {
                alpha = data[(bmp.pixelsWide * row + col) * 4 + 3]

                if alpha != 0 {
                    topCrop = row
                    break outerTop
                }
            }
        }

        // Bottom crop
        outerBottom: for row in (0..<bmp.pixelsHigh).reversed() {
            for col in 0..<bmp.pixelsWide {
                alpha = data[(bmp.pixelsWide * row + col) * 4 + 3]

                if alpha != 0 {
                    bottomCrop = row
                    break outerBottom
                }
            }
        }

        // Left crop
        outerLeft: for col in 0..<bmp.pixelsWide {
            for row in 0..<bmp.pixelsHigh {
                alpha = data[(bmp.pixelsWide * row + col) * 4 + 3]

                if alpha != 0 {
                    leftCrop = col
                    break outerLeft
                }
            }
        }

        // Right crop
        outerRight: for col in (0..<bmp.pixelsWide).reversed() {
            for row in 0..<bmp.pixelsHigh {
                alpha = data[(bmp.pixelsWide * row + col) * 4 + 3]

                if alpha != 0 {
                    rightCrop = col
                    break outerRight
                }
            }
        }

        return CGRect(x: leftCrop, y: topCrop, width: rightCrop-leftCrop, height: bottomCrop-topCrop)
    }

    func tinting(with tintColor: NSColor) -> NSImage {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return self }

        return NSImage(size: size, flipped: false) { bounds in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }

            tintColor.set()
            context.clip(to: bounds, mask: cgImage)
            context.fill(bounds)

            return true
        }
    }

}
