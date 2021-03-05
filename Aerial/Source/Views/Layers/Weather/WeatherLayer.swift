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

    var cscale: CGFloat?

    var cachedWeather: OWeather?

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
        if let todayCond = todayCond {
            todayCond.contentsScale = scale

            if todayCond.sublayers != nil {
                for layer in todayCond.sublayers! {
                    layer.contentsScale = scale
                }
            }
        }

        // In case we haven't called displayWeatherBlock yet (should be all the time but hmm)
        cscale = scale
    }

    // Called at each new video, we only setup once though !
    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        // Only run this once
        if !wasSetup {
            wasSetup = true
            frame.size = CGSize(width: 100, height: 1)
            update()

            if cachedWeather != nil {
                displayWeatherBlock()
            } else {
                OpenWeather.fetch { result in
                    switch result {
                    case .success(let openWeather):
                        print(openWeather)
                        self.cachedWeather = openWeather
                        self.displayWeatherBlock()
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }

    func displayWeatherBlock() {
        guard cachedWeather != nil else {
            errorLog("No weather info in dWB please report")
            return
        }

        todayCond = ConditionLayer(condition: cachedWeather!, scale: contentsScale)
        if cscale != nil {
            todayCond!.contentsScale = cscale!
        }
        todayCond!.anchorPoint = CGPoint(x: 0, y: 0)
        todayCond!.position = CGPoint(x: 0, y: 10)
        addSublayer(todayCond!)

        self.frame.size = CGSize(width: todayCond!.frame.width, height: 95)

        update(redraw: true)
        let fadeAnimation = self.createFadeInAnimation()
        add(fadeAnimation, forKey: "weatherfade")
    }
}
