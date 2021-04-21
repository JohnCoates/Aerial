//
//  ForecastLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 23/03/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

// swiftlint:disable:next type_body_length
class ForecastLayer: CALayer {
    var condition: OCOneCall?

    init(condition: OCOneCall, scale: CGFloat) {
        self.condition = condition
        super.init()

        // backgroundColor = .init(gray: 0.2, alpha: 0.2)

        contentsScale = scale
        let size = PrefsInfo.weather.fontSize

        // We have daily forecasts, and hourly forecasts available (woo)
        if PrefsInfo.weather.mode == .forecast3days || PrefsInfo.weather.mode == .forecast7days {
            // How many days to display, currently we do 3 and 7
            var days = 7
            if PrefsInfo.weather.mode == .forecast3days {
                days = 3
            }

            if let daily = condition.daily {
                if daily.count >= 3 {

                    var height: CGFloat = 0
                    for dayidx in 0 ..< days {
                        let day = makeDayBlock(day: daily[dayidx], size: size*2)
                        day.anchorPoint = CGPoint(x: 0, y: 0)
                        day.position = CGPoint(x: Int(size * 2) * dayidx, y: 0)
                        self.addSublayer(day)
                        print(day.frame.height)
                        if day.frame.height > height {
                            height = day.frame.height
                        }
                    }

                    let legend = makeLegendBlock(size: size*2)
                    legend.anchorPoint = CGPoint(x: 0, y: 0)
                    legend.position = CGPoint(x: Int(size*2) * days, y: 0)
                    self.addSublayer(legend)

                    self.frame = CGRect(x: 0, y: 0, width:
                                            CGFloat(Double((days + 1)) * (size * 2)), height: height)
                }
            }
        } else {
            // Hourly forecast, we do 6 hours
            if let hourly = condition.hourly {
                // Just in case
                if hourly.count > 5 {
                    var height: CGFloat = 0

                    for houridx in 0 ..< 6 {
                        let day = makeHourBlock(hour: hourly[houridx],
                                                size: size*2,
                                                sunset: condition.current!.sunset!,
                                                sunrise: condition.current!.sunrise!)
                        day.anchorPoint = CGPoint(x: 0, y: 0)
                        day.position = CGPoint(x: Int(size * 2) * houridx, y: 0)
                        self.addSublayer(day)
                        print(day.frame.height)
                        if day.frame.height > height {
                            height = day.frame.height
                        }
                    }

                    let legend = makeLegendBlock(size: size*2)
                    legend.anchorPoint = CGPoint(x: 0, y: 0)
                    legend.position = CGPoint(x: Int(size*2) * 6, y: 0)
                    self.addSublayer(legend)

                    self.frame = CGRect(x: 0, y: 0, width:
                                            CGFloat(7 * (size * 2)), height: height)
                }
            }
        }

    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeDayBlock(day: OCDaily, size: Double) -> CALayer {
        let mainLayer = CALayer()

        // First create the symbol
        let imglayer = ConditionSymbolLayer(weather: day.weather![0],
                                            dt: day.dt!,
                                            sunrise: day.sunrise!,
                                            sunset: day.sunset!,
                                            size: Int(size),
                                            square: true)

        let windLayer = makeWindBlock(speed: day.windSpeed!, degree: day.windDeg!, size: size/4)

        let max = CAVCTextLayer()
        max.string = "\(String(format: "%.0f", day.temp!.max!))°"

        (max.font, max.fontSize) = max.makeFont(name: PrefsInfo.weather.fontName, size: size/4)

        // ReRect the temperature
        let rect = max.calculateRect(string: max.string as! String, font: max.font as! NSFont)
        max.frame = rect
        max.contentsScale = self.contentsScale
        max.alignmentMode = .center

        let min = CAVCTextLayer()
        min.string = "\(String(format: "%.0f", day.temp!.min!))°"

        (min.font, min.fontSize) = min.makeFont(name: PrefsInfo.weather.fontName, size: size/4)

        // ReRect the temperature
        let rect2 = min.calculateRect(string: min.string as! String, font: min.font as! NSFont)
        min.frame = rect2
        min.contentsScale = self.contentsScale
        min.alignmentMode = .center

        let dayi = CAVCTextLayer()
        dayi.string = dayStringFromTimeStamp(timeStamp: Double(day.dt!))

        (dayi.font, dayi.fontSize) = dayi.makeFont(name: PrefsInfo.weather.fontName, size: size/4)

        // ReRect the temperature
        let rect4 = dayi.calculateRect(string: dayi.string as! String, font: dayi.font as! NSFont)
        dayi.frame = rect4
        dayi.contentsScale = self.contentsScale
        dayi.alignmentMode = .center

        // Then we draw bottom to top
        dayi.anchorPoint = CGPoint(x: 0.5, y: 0)
        dayi.position = CGPoint(x: size/2, y: 0)
        mainLayer.addSublayer(dayi)
        var offset = dayi.frame.height

        windLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
        windLayer.position = CGPoint(x: CGFloat(size)/2, y: offset)
        mainLayer.addSublayer(windLayer)
        offset += windLayer.frame.height

        min.anchorPoint = CGPoint(x: 0.5, y: 0)
        min.position = CGPoint(x: CGFloat(size)/2, y: offset)
        mainLayer.addSublayer(min)
        offset += min.frame.height

        max.anchorPoint = CGPoint(x: 0.5, y: 0)
        max.position = CGPoint(x: CGFloat(size) / 2, y: offset)
        mainLayer.addSublayer(max)
        offset += max.frame.height

        imglayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imglayer.position = CGPoint(x: Double(size) / 2,
                                    y: Double(offset) + size/2)
        mainLayer.addSublayer(imglayer)

        mainLayer.frame = CGRect(x: 0, y: 0,
                                 width: CGFloat(size),
                                 height: offset + imglayer.frame.height)
        return mainLayer
    }

    func makeHourBlock(hour: OCCurrent, size: Double, sunset: Int, sunrise: Int) -> CALayer {
        let mainLayer = CALayer()

        // First create the symbol
        let imglayer = ConditionSymbolLayer(weather: hour.weather![0],
                                            dt: hour.dt!,
                                            sunrise: sunrise,
                                            sunset: sunset,
                                            size: Int(size),
                                            square: true)

        let windLayer = makeWindBlock(speed: hour.windSpeed!, degree: hour.windDeg!, size: size/4)

        let temp = CAVCTextLayer()
        temp.string = "\(String(format: "%.0f", hour.temp!))°"

        (temp.font, temp.fontSize) = temp.makeFont(name: PrefsInfo.weather.fontName, size: size/4)

        // ReRect the temperature
        let rect = temp.calculateRect(string: temp.string as! String, font: temp.font as! NSFont)
        temp.frame = rect
        temp.contentsScale = self.contentsScale
        temp.alignmentMode = .center

        let feelsLike = CAVCTextLayer()
        feelsLike.string = "\(String(format: "%.0f", hour.feelsLike!))°"

        (feelsLike.font, feelsLike.fontSize) = feelsLike.makeFont(name: PrefsInfo.weather.fontName, size: size/4)

        // ReRect the temperature
        let rect2 = feelsLike.calculateRect(string: feelsLike.string as! String, font: feelsLike.font as! NSFont)
        feelsLike.frame = rect2
        feelsLike.contentsScale = self.contentsScale
        feelsLike.alignmentMode = .center

        let dayi = CAVCTextLayer()
        dayi.string = hourStringFromTimeStamp(timeStamp: Double(hour.dt!))

        (dayi.font, dayi.fontSize) = dayi.makeFont(name: PrefsInfo.weather.fontName, size: size/4)

        // ReRect the temperature
        let rect4 = dayi.calculateRect(string: dayi.string as! String, font: dayi.font as! NSFont)
        dayi.frame = rect4
        dayi.contentsScale = self.contentsScale
        dayi.alignmentMode = .center

        // Then we draw bottom to top
        dayi.anchorPoint = CGPoint(x: 0.5, y: 0)
        dayi.position = CGPoint(x: size/2, y: 0)
        mainLayer.addSublayer(dayi)
        var offset = dayi.frame.height

        windLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
        windLayer.position = CGPoint(x: CGFloat(size)/2, y: offset)
        mainLayer.addSublayer(windLayer)
        offset += windLayer.frame.height

        feelsLike.anchorPoint = CGPoint(x: 0.5, y: 0)
        feelsLike.position = CGPoint(x: CGFloat(size)/2, y: offset)
        mainLayer.addSublayer(feelsLike)
        offset += feelsLike.frame.height

        temp.anchorPoint = CGPoint(x: 0.5, y: 0)
        temp.position = CGPoint(x: CGFloat(size) / 2, y: offset)
        mainLayer.addSublayer(temp)
        offset += temp.frame.height

        imglayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imglayer.position = CGPoint(x: Double(size) / 2,
                                    y: Double(offset) + size/2)
        mainLayer.addSublayer(imglayer)

        mainLayer.frame = CGRect(x: 0, y: 0,
                                 width: CGFloat(size),
                                 height: offset + imglayer.frame.height)
        return mainLayer
    }

    func makeLegendBlock(size: Double) -> CALayer {
        let mainLayer = CALayer()

        // Make a vertically centered layer for t°
        let windLayer = CAVCTextLayer()

        if PrefsInfo.weather.degree == .celsius {
            windLayer.string = "km/h"
        } else {
            windLayer.string = "mph"
        }

        // Get something large first
        (windLayer.font, windLayer.fontSize) = windLayer.makeFont(name: PrefsInfo.weather.fontName, size: size/4)

        // ReRect the temperature
        let rect2 = windLayer.calculateRect(string: windLayer.string as! String, font: windLayer.font as! NSFont)
        windLayer.frame = rect2
        windLayer.contentsScale = self.contentsScale
        windLayer.alignmentMode = .center

        let max = CAVCTextLayer()
        if PrefsInfo.weather.mode == .forecast6hours {
            max.string = "Temperature"
        } else {
            max.string = "Max"
        }

        (max.font, max.fontSize) = max.makeFont(name: PrefsInfo.weather.fontName, size: size/4)

        // ReRect the temperature
        let rect = max.calculateRect(string: max.string as! String, font: max.font as! NSFont)
        max.frame = rect
        max.contentsScale = self.contentsScale
        max.alignmentMode = .center

        let min = CAVCTextLayer()
        min.string = "Min"
        if PrefsInfo.weather.mode == .forecast6hours {
            min.string = "Feels Like"
        } else {
            min.string = "Min"
        }

        (min.font, min.fontSize) = min.makeFont(name: PrefsInfo.weather.fontName, size: size/4)

        // ReRect the temperature
        let rect3 = min.calculateRect(string: min.string as! String, font: min.font as! NSFont)
        min.frame = rect3
        min.contentsScale = self.contentsScale
        min.alignmentMode = .center

        // Then we draw bottom to top
        windLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
        windLayer.position = CGPoint(x: CGFloat(size)/2, y: windLayer.frame.height)
        mainLayer.addSublayer(windLayer)
        var offset = windLayer.frame.height*2

        min.anchorPoint = CGPoint(x: 0.5, y: 0)
        min.position = CGPoint(x: CGFloat(size)/2, y: offset)
        mainLayer.addSublayer(min)
        offset += min.frame.height

        max.anchorPoint = CGPoint(x: 0.5, y: 0)
        max.position = CGPoint(x: CGFloat(size) / 2, y: offset)
        mainLayer.addSublayer(max)
        //offset += max.frame.height

        return mainLayer
    }

    func makeWindBlock(speed: Double, degree: Int, size: Double) -> CALayer {
        let windLayer = CALayer()

        // Make a vertically centered layer for t°
        let wind = CAVCTextLayer()

        wind.string = String(format: "%.0f", speed * 3.6)

        // Get something large first
        (wind.font, wind.fontSize) = wind.makeFont(name: PrefsInfo.weather.fontName, size: size)

        // ReRect the temperature
        let rect2 = wind.calculateRect(string: wind.string as! String, font: wind.font as! NSFont)
        wind.frame = rect2
        wind.contentsScale = self.contentsScale

        // Create the wind indicator
        let imglayer = WindDirectionLayer(direction: 225, size: CGFloat(size/1.27))

        imglayer.contentsScale = self.contentsScale
        imglayer.transform = CATransform3DMakeRotation(CGFloat((180 + degree)) / 180.0 * .pi, 0.0, 0.0, -1.0)

        imglayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imglayer.position = CGPoint(x: imglayer.frame.width/2,
                                    y: wind.frame.height/2)

        windLayer.addSublayer(imglayer)

        // We put the temperature at the right of the weather icon
        wind.anchorPoint = CGPoint(x: 0, y: 0)
        wind.position = CGPoint(x: imglayer.frame.width + 3, y: 0)
        windLayer.addSublayer(wind)

        // Reset the container frame
        windLayer.frame = CGRect(x: 0, y: 0, width: imglayer.frame.width + wind.frame.width + 3, height: wind.frame.height)
        return windLayer
    }

    func dayStringFromTimeStamp(timeStamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timeStamp)
        let dateFormatter = DateFormatter()

        var locale = Locale(identifier: Locale.preferredLanguages[0])
        let preferences = Preferences.sharedInstance
        if preferences.ciOverrideLanguage != "" {
            locale = Locale(identifier: preferences.ciOverrideLanguage!)
        }

        dateFormatter.locale = locale
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: date)
    }

    func hourStringFromTimeStamp(timeStamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timeStamp)
        let dateFormatter = DateFormatter()

        var locale = Locale(identifier: Locale.preferredLanguages[0])
        let preferences = Preferences.sharedInstance
        if preferences.ciOverrideLanguage != "" {
            locale = Locale(identifier: preferences.ciOverrideLanguage!)
        }

        dateFormatter.locale = locale
        dateFormatter.dateFormat = "HH"
        return dateFormatter.string(from: date) + "h"
    }
}

extension Double {
    func roundTemp() -> Double {
        if PrefsInfo.weather.degree == .celsius {
            return self.rounded(toPlaces: 0) // rounded(toPlaces: 1)
        } else {
            return self.rounded()
        }
    }
}
