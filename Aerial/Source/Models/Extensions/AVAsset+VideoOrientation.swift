//
//  AVAsset+VideoOrientation.swift
//  AVAsset+VideoOrientation
//
//  Created by Guillaume Louel on 26/08/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//
//  Created by Wesley Van der Klomp on 1/7/19.
//
// Translated from: https://gist.github.com/lukabernardi/5020724
//
// Modified to add some extra checks

import AVFoundation

extension AVAsset {

    enum VideoOrientation {
        case right, up, left, down

        static func fromVideoWithAngle(ofDegree degree: CGFloat) -> VideoOrientation? {
            switch Int(degree) {
            case 0: return .right
            case 90: return .up
            case 180: return .left
            case -90: return .down
            default: return nil
            }
        }
    }

    // This also checks for videos that may have their rotation baked in,
    // and not provided as a metadata (so 1080x1920 instead of 1920x1080 with 90° rotation)
    func isVertical() -> Bool {
        if self.videoOrientation() == .right || self.videoOrientation() == .left {
            // So at this point this is the natural(ish) orientation, we need to check the width/height
            let track = self.tracks(withMediaType: .video).first!

            return track.naturalSize.height > track.naturalSize.width
        } else {
            return true
        }
    }

    // This checks for a rotation metadata ONLY which is what works for iPhone videos.
    func videoOrientation() -> VideoOrientation? {
        func radiansToDegrees(_ radians: Float) -> CGFloat {
            return CGFloat(radians * 180.0 / Float.pi)
        }

        guard let firstVideoTrack = self.tracks(withMediaType: .video).first else {
            return nil
        }
        let transform = firstVideoTrack.preferredTransform
        let videoAngleInDegree = radiansToDegrees(atan2f(Float(transform.b), Float(transform.a)))
        return VideoOrientation.fromVideoWithAngle(ofDegree: videoAngleInDegree)
    }

}
import Foundation
