//
//  WeatherLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class WeatherLayer: AnimationLayer {
    var config: PrefsInfo.Weather?
    var wasSetup = false
    var todayCond: ConditionLayer?
    var logo: YahooLayer?

    var cscale: CGFloat?

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our inits
    override init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        super.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)

        // Always on layers should start with full opacity
        self.opacity = 1
    }

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Weather) {
        self.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
        self.config = config

/*        // Set our layer's font & corner now
        (self.font, self.fontSize) = getFont(name: config.fontName,
                                             size: config.fontSize)*/
        self.corner = config.corner
    }

    override func setContentScale(scale: CGFloat) {
        print("sCS wov : \(scale)")
        if todayCond != nil {
            debugLog("SCS WL todayCond")
            todayCond?.contentsScale = scale
        }
        if logo != nil {
            debugLog("SCS WL logo")
            logo?.contentsScale = scale
        }

        // In case we haven't called displayWeatherBlock yet (should be all the time but hmm)
        cscale = scale
    }

    // Called at each new video, we only setup once though !
    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        // Only run this once
        if !wasSetup {
            wasSetup = true

            if Weather.info != nil {
                displayWeatherBlock()
            } else {
                Weather.fetch(failure: { (error) in
                    print(error.localizedDescription)
                }, success: { (_) in
                    self.displayWeatherBlock()
                })
            }
        }
    }

    func displayWeatherBlock() {
        if Weather.info == nil {
            errorLog("No weather info in dWB please report")
            return
        }
        let todayCond = ConditionLayer(condition: Weather.info!.currentObservation.condition)
        if cscale != nil {
            todayCond.contentsScale = cscale!
        }
        addSublayer(todayCond)
        self.frame.size = CGSize(width: todayCond.frame.width, height: 85)

        let logo = YahooLayer()
        logo.anchorPoint = CGPoint(x: 1, y: 0)
        logo.position = CGPoint(x: frame.size.width-10, y: 0)
        if cscale != nil {
            logo.contentsScale = cscale!
        }
        addSublayer(logo)

        update()
        let fadeAnimation = self.createFadeInAnimation()
        add(fadeAnimation, forKey: "weatherfade")
    }
}
