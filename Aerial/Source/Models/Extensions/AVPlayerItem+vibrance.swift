//
//  AVPlayerItem+vibrance.swift
//  Aerial
//
//  Created by Guillaume Louel on 02/08/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import AVKit

extension AVPlayerItem {
    func setVibrance(_ value: Double) {
        var useValue = PrefsVideos.globalVibrance
        
        if value != 0 {
            useValue = value
        }
        
        guard useValue != 0 else {
            return
        }
        
        if #available(OSX 10.14, *) {
            debugLog("Applying vibrance of \(useValue)")
            let filter = CIFilter(name: "CIVibrance")!
            self.videoComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                let source = request.sourceImage.clampedToExtent()
                filter.setValue(source, forKey: kCIInputImageKey)
                filter.setValue(useValue, forKey: kCIInputAmountKey)
                let output = filter.outputImage
                
                request.finish(with: output!, context: nil)
            })
        }
    }
    
    func setColorInvert() {
        if #available(OSX 10.14, *) {
                debugLog("Applying color invert with brightness adjustment")

                if let invertFilter = CIFilter(name: "CIColorInvert"),
                   let brightnessFilter = CIFilter(name: "CIColorControls") {
                    
                    self.videoComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                        let source = request.sourceImage.clampedToExtent()
                        
                        // First apply invert
                        invertFilter.setValue(source, forKey: kCIInputImageKey)
                        
                        // Then apply brightness
                        brightnessFilter.setValue(invertFilter.outputImage, forKey: kCIInputImageKey)
                        brightnessFilter.setValue(-0.25, forKey: kCIInputBrightnessKey) // 25% decrease
                        
                        let output = brightnessFilter.outputImage
                        
                        request.finish(with: output!, context: nil)
                    })
                }
            }
    }
    
}
