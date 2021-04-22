//
//  ConditionLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

// Vertically centered CATextLayer
class CAVCTextLayer: CATextLayer {

    // REF: http://lists.apple.com/archives/quartz-dev/2008/Aug/msg00016.html
    // CREDIT: David Hoerl - https://github.com/dhoerl
    // USAGE: To fix the vertical alignment issue that currently exists within the CATextLayer class. Change made to the yDiff calculation.

    override func draw(in context: CGContext) {
        let height = self.bounds.size.height
        let fontSize = self.fontSize
        let yDiff = (height-fontSize)/2 - fontSize/10

        context.saveGState()
        context.translateBy(x: 0, y: -yDiff)
        super.draw(in: context)
        context.restoreGState()
    }
}

class ConditionLayer: CALayer {
    var condition: OWeather?

    init(condition: OWeather, scale: CGFloat) {
        self.condition = condition
        super.init()

        // backgroundColor = .init(gray: 0.2, alpha: 0.2)

        contentsScale = scale

        // First we make the temperatures block (accurate and feels like)
        let tempBlock = makeTemperatureBlock()
        let feelsBlock = makeFeelsLikeBlock()

        // We make the symbol a square of the combined height of both blocks
        let combinedHeight = tempBlock.frame.height + feelsBlock.frame.height

        // Create a symbol that fits the size
        //let imglayer = ConditionSymbolLayer(condition: condition, size: Int(combinedHeight))
        let imglayer = ConditionSymbolLayer(weather: condition.weather![0],
                                            dt: condition.dt!,
                                            sunrise: condition.sys!.sunrise,
                                            sunset: condition.sys!.sunset,
                                            size: Int(combinedHeight))

        // Add the Wind layer
        let windHeight = addWind(at: (imglayer.frame.width + combinedHeight/10 + tempBlock.frame.width) / 2)

        imglayer.anchorPoint = CGPoint(x: 0, y: 0)
        imglayer.position = CGPoint(x: 0, y: windHeight)
        self.addSublayer(imglayer)

        frame.size = CGSize(width: imglayer.frame.width + combinedHeight/10 + tempBlock.frame.width,
                            height: tempBlock.frame.height + feelsBlock.frame.height + windHeight)

        addSublayer(tempBlock)
        tempBlock.anchorPoint = CGPoint(x: 1, y: 1)
        tempBlock.position = CGPoint(x: frame.size.width, y: tempBlock.frame.height + feelsBlock.frame.height + windHeight)

        addSublayer(feelsBlock)
        feelsBlock.anchorPoint = CGPoint(x: 0.5, y: 0)
        feelsBlock.position = CGPoint(x: imglayer.frame.width + combinedHeight/10 + tempBlock.frame.width/2, y: windHeight)

        /*
        if PrefsInfo.weather.icons == .flat {
            let imglayer = ConditionSymbolLayer(condition: condition)
            imglayer.anchorPoint = CGPoint(x: 0, y: 0.5)
            imglayer.position = CGPoint(x: 0, y: 50)
            self.addSublayer(imglayer)

            let tempWidth = addTemperature(at: imglayer.frame.width + 15)
            addFeelsLike(at: imglayer.frame.width + 15 + (tempWidth / 2))
            addWind(at: (imglayer.frame.width + 15 + tempWidth) / 2)

            // Set the final size of that block
            frame.size = CGSize(width: imglayer.frame.width + 15 + tempWidth, height: 75)
        } else {
            // This is a temporary size
            frame.size = CGSize(width: 160, height: 75)

            // http://openweathermap.org/img/wn/10d@2x.png

            downloadImage(from: URL(string: "http://openweathermap.org/img/wn/\(condition.weather![0].icon)@4x.png")!)
        }*/
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeTemperatureBlock() -> CATextLayer {
        let temp = CAVCTextLayer()

        // First we start with the real temperature
        // We keep the decimal for now on celcius, this may become optional
        if PrefsInfo.weather.degree == .celsius {
            temp.string = "\(condition!.main!.temp)°"
        } else {
            temp.string = "\(Int(condition!.main!.temp))°"
        }

        (temp.font, temp.fontSize) = temp.makeFont(name: PrefsInfo.weather.fontName, size: PrefsInfo.weather.fontSize)

        // ReRect the temperature
        let rect = temp.calculateRect(string: temp.string as! String, font: temp.font as! NSFont)
        temp.frame = rect
        temp.contentsScale = self.contentsScale

        return temp
    }

    func makeFeelsLikeBlock() -> CATextLayer {
        // Make a vertically centered layer for t°
        let feel = CAVCTextLayer()
        if PrefsInfo.weather.degree == .celsius {
            feel.string = "(\(condition!.main!.feelsLike)°)"
        } else {
            feel.string = "(\(Int(condition!.main!.feelsLike))°)"
        }

        feel.contentsScale = self.contentsScale
        (feel.font, feel.fontSize) = feel.makeFont(name: PrefsInfo.weather.fontName, size: PrefsInfo.weather.fontSize/2.2)

        // ReRect the temperature
        let rect2 = feel.calculateRect(string: feel.string as! String, font: feel.font as! NSFont)
        feel.frame = rect2

        return feel
    }

    func addWind(at: CGFloat) -> CGFloat {
        guard let owind = condition?.wind else {
            return 0
        }

        // Make a vertically centered layer for t°
        let wind = CAVCTextLayer()
        if PrefsInfo.weather.degree == .celsius {
            wind.string = "\(Int(owind.speed * 3.6)) km/h"
        } else {
            wind.string = "\(Int(owind.speed)) mph"
        }

        // Get something large first
        (wind.font, wind.fontSize) = wind.makeFont(name: PrefsInfo.weather.fontName, size: PrefsInfo.weather.fontSize/2.2)

        wind.contentsScale = self.contentsScale

        // ReRect the temperature
        let rect2 = wind.calculateRect(string: wind.string as! String, font: wind.font as! NSFont)
        wind.frame = rect2
        wind.contentsScale = self.contentsScale
        self.addSublayer(wind)

        // Create the wind indicator
        let imglayer = WindDirectionLayer(direction: 225, size: CGFloat(PrefsInfo.weather.fontSize/2.8))

        // We put the temperature at the right of the weather icon
        wind.anchorPoint = CGPoint(x: 0.5, y: 0)
        wind.position = CGPoint(x: at + imglayer.frame.height/2, y: 0)

        imglayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imglayer.position = CGPoint(x: at - (rect2.width/2) - imglayer.frame.height/2,
                                    y: wind.frame.height/2)

        imglayer.contentsScale = self.contentsScale
        imglayer.transform = CATransform3DMakeRotation(CGFloat((180 + owind.deg)) / 180.0 * .pi, 0.0, 0.0, -1.0)

        self.addSublayer(imglayer)

        return wind.frame.height
    }

}
