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

        var cityNameBlock: CALayer
        if PrefsInfo.weather.showCity {
            cityNameBlock = makeCityNameBlock()
        } else {
            cityNameBlock = CALayer()
        }

        // We make the symbol a square of the combined height of both blocks
        let combinedHeight = tempBlock.frame.height + feelsBlock.frame.height

        // Create a symbol that fits the size
        let imglayer = ConditionSymbolLayer(weather: condition.weather![0],
                                            dt: condition.dt!,
                                            sunrise: condition.sys!.sunrise,
                                            sunset: condition.sys!.sunset,
                                            size: Int(combinedHeight))

        // Add the Wind layer
        var windHeight: CGFloat = 0
        if PrefsInfo.weather.showWind || PrefsInfo.weather.showHumidity {
            windHeight = addWindAndHumidity(x: (imglayer.frame.width + combinedHeight/10 + tempBlock.frame.width) / 2, y: cityNameBlock.frame.height)
        }

        imglayer.anchorPoint = CGPoint(x: 0, y: 0)
        imglayer.position = CGPoint(x: 0, y: windHeight + cityNameBlock.frame.height)
        self.addSublayer(imglayer)

        frame.size = CGSize(width: imglayer.frame.width + combinedHeight/10 + tempBlock.frame.width,
                            height: tempBlock.frame.height + feelsBlock.frame.height + windHeight + cityNameBlock.frame.height)

        addSublayer(cityNameBlock)
        cityNameBlock.anchorPoint = CGPoint(x: 0.5, y: 0)
        cityNameBlock.position = CGPoint(x: frame.size.width/2, y: 0)

        addSublayer(tempBlock)
        tempBlock.anchorPoint = CGPoint(x: 1, y: 1)
        tempBlock.position = CGPoint(x: frame.size.width,
                                     y: tempBlock.frame.height + feelsBlock.frame.height + windHeight + cityNameBlock.frame.height)

        addSublayer(feelsBlock)
        feelsBlock.anchorPoint = CGPoint(x: 0.5, y: 0)
        feelsBlock.position = CGPoint(x: imglayer.frame.width + combinedHeight/10 + tempBlock.frame.width/2,
                                      y: windHeight + cityNameBlock.frame.height)

    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeCityNameBlock() -> CATextLayer {
        let temp = CATextLayer()
        temp.isWrapped = true
        temp.string = condition!.name
        (temp.font, temp.fontSize) = temp.makeFont(name: PrefsInfo.weather.fontName, size: PrefsInfo.weather.fontSize/1.5)
        temp.alignmentMode = .center
        // ReRect the temperature
        let rect = temp.calculateRect(string: temp.string as! String, font: temp.font as! NSFont, maxWidth: 220)
        temp.frame = rect

        temp.contentsScale = self.contentsScale

        return temp
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

    // swiftlint:disable:next identifier_name
    func addWindAndHumidity(x: CGFloat, y: CGFloat) -> CGFloat {
        // We need to make sure we have the data, and the options are selected
        var addWind = false, addHumidity = false

        let wind = condition?.wind
        let humidity = condition?.main?.humidity

        if PrefsInfo.weather.showWind && wind != nil {
            addWind = true
        }
        if PrefsInfo.weather.showHumidity && humidity != nil {
            addHumidity = true
        }

        // If we shouldn't display/should and don't have data
        if !addWind && !addHumidity {
            return 0
        }

        // Ughhhhh, this code is so ugly
        var windBlock: CALayer?
        var humidityBlock: CALayer?

        if addWind {
            windBlock = makeWindBlock(wind: wind!)
            // windBlock!.anchorPoint = CGPoint(x: 0, y: 0)
        }
        if addHumidity {
            humidityBlock = makeHumidityBlock(humidity: humidity!)
            // humidityBlock!.anchorPoint = CGPoint(x: 0, y: 0)
        }

        // Haaaaaaaa I hate this
        if addWind && addHumidity {
            let halfTotalWidth = (windBlock!.frame.size.width
                            + humidityBlock!.frame.size.width)/2

            windBlock!.position = CGPoint(x: x - halfTotalWidth + windBlock!.frame.size.width/2, y: y)
            humidityBlock!.position = CGPoint(x: x + halfTotalWidth - humidityBlock!.frame.size.width/2, y: y)

            self.addSublayer(windBlock!)
            self.addSublayer(humidityBlock!)

            return windBlock!.frame.height
        } else if addWind {
            windBlock!.position = CGPoint(x: x, y: y)

            self.addSublayer(windBlock!)

            return windBlock!.frame.height
        } else if addHumidity {
            humidityBlock!.position = CGPoint(x: x, y: y)

            self.addSublayer(humidityBlock!)

            return humidityBlock!.frame.height
        }

        // tmp
        return 0
    }

    func makeHumidityBlock(humidity: Double) -> CALayer {
        let humidityBlock = CALayer()

        // Make a vertically centered layer for t°
        let textHumidity = CAVCTextLayer()
        textHumidity.string = " \(Int(humidity))%"

        // Get something large first
        (textHumidity.font, textHumidity.fontSize) = textHumidity.makeFont(name: PrefsInfo.weather.fontName, size: PrefsInfo.weather.fontSize/2.2)

        textHumidity.contentsScale = self.contentsScale

        // ReRect the temperature
        let rect2 = textHumidity.calculateRect(string: textHumidity.string as! String, font: textHumidity.font as! NSFont)
        textHumidity.frame = rect2
        textHumidity.contentsScale = self.contentsScale

        humidityBlock.addSublayer(textHumidity)

        let imglayer = Aerial.getSymbolLayer("humidity", size: CGFloat(PrefsInfo.weather.fontSize/2.8))

        // We put the temperature at the right of the wind icon
        textHumidity.anchorPoint = CGPoint(x: 0, y: 0)
        textHumidity.position = CGPoint(x: imglayer.frame.height, y: 0)

        imglayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imglayer.position = CGPoint(x: imglayer.frame.height/2,
                                    y: textHumidity.frame.height/2)

        imglayer.contentsScale = self.contentsScale
        humidityBlock.frame.size = CGSize(width: textHumidity.frame.width+imglayer.frame.width,
                                          height: max(textHumidity.frame.height, imglayer.frame.height))

        humidityBlock.anchorPoint = CGPoint(x: 0.5, y: 0)
        humidityBlock.addSublayer(imglayer)
        return humidityBlock
    }

    func makeWindBlock(wind: OWWind) -> CALayer {
        let windBlock = CALayer()

        // Make a vertically centered layer for t°
        let textWind = CAVCTextLayer()
        if PrefsInfo.weather.degree == .celsius {
            if PrefsInfo.weatherWindMode == .kph {
                textWind.string = "\(Int(wind.speed * 3.6)) km/h"
            } else {
                textWind.string = "\(Int(wind.speed)) m/s"
            }
        } else {
            textWind.string = "\(Int(wind.speed)) mph"
        }

        // Get something large first
        (textWind.font, textWind.fontSize) = textWind.makeFont(name: PrefsInfo.weather.fontName, size: PrefsInfo.weather.fontSize/2.2)

        textWind.contentsScale = self.contentsScale

        // ReRect the temperature
        let rect2 = textWind.calculateRect(string: textWind.string as! String, font: textWind.font as! NSFont)
        textWind.frame = rect2
        textWind.contentsScale = self.contentsScale

        windBlock.addSublayer(textWind)

        // Create the wind indicator
        let imglayer = WindDirectionLayer(direction: 225, size: CGFloat(PrefsInfo.weather.fontSize/2.8))

        textWind.anchorPoint = CGPoint(x: 0, y: 0)
        textWind.position = CGPoint(x: imglayer.frame.height, y: 0)

        // Rotation is relative to anchorpoint, so it has to be middle
        imglayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imglayer.position = CGPoint(x: imglayer.frame.height/2, y: textWind.frame.height/2)

        // Rotation is done here
        imglayer.transform = CATransform3DMakeRotation(CGFloat((180 + wind.deg)) / 180.0 * .pi, 0.0, 0.0, -1.0)

        imglayer.contentsScale = self.contentsScale

        windBlock.frame.size = CGSize(width: textWind.frame.width+imglayer.frame.width,
                                      height: max(textWind.frame.height, imglayer.frame.height))
        windBlock.addSublayer(imglayer)
        windBlock.anchorPoint = CGPoint(x: 0.5, y: 0)

        return windBlock
    }

}
