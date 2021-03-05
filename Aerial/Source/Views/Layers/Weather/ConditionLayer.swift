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

        contentsScale = scale
        debugLog("Condition : \(condition)")

        if PrefsInfo.weather.icons == .flat {
            let imglayer = ConditionSymbolLayer(condition: condition)
            imglayer.anchorPoint = CGPoint(x: 0, y: 0.5)
            imglayer.position = CGPoint(x: 0, y: 50)
            self.addSublayer(imglayer)

            let tempWidth = addTemperature(at: imglayer.frame.width + 15)
            addFeelsLike(at: imglayer.frame.width + 15 + (tempWidth / 2))

            // Set the final size of that block
            frame.size = CGSize(width: imglayer.frame.width + 15 + tempWidth, height: 75)
        } else {
            // This is a temporary size
            frame.size = CGSize(width: 160, height: 75)

            // http://openweathermap.org/img/wn/10d@2x.png

            downloadImage(from: URL(string: "http://openweathermap.org/img/wn/\(condition.weather![0].icon)@4x.png")!)
        }
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    func addTemperature(at: CGFloat) -> CGFloat {
        // Make a vertically centered layer for t°
        let temp = CAVCTextLayer()
        temp.string = "\(condition!.main!.temp)°"

        // Get something large first
        temp.frame.size = CGSize(width: 100, height: 400)
        (temp.font, temp.fontSize) = temp.makeFont(name: PrefsInfo.weather.fontName, size: PrefsInfo.weather.fontSize)

        // ReRect the temperature
        let rect = temp.calculateRect(string: temp.string as! String, font: temp.font as! NSFont)
        temp.frame = rect

        print("tcs \(self.contentsScale)")

        temp.contentsScale = self.contentsScale
        self.addSublayer(temp)

        // We put the temperature at the right of the weather icon
        temp.anchorPoint = CGPoint(x: 0, y: 0.5)
        temp.position = CGPoint(x: at, y: 50)

        return rect.size.width
    }

    func addFeelsLike(at: CGFloat) {
        // Make a vertically centered layer for t°
        let feel = CAVCTextLayer()
        feel.string = "(\(condition!.main!.feelsLike)°)"

        // Get something large first
        feel.frame.size = CGSize(width: 100, height: 30)
        (feel.font, feel.fontSize) = feel.makeFont(name: PrefsInfo.weather.fontName, size: PrefsInfo.weather.fontSize/2.5)

        // ReRect the temperature
        let rect2 = feel.calculateRect(string: feel.string as! String, font: feel.font as! NSFont)
        feel.frame = rect2
        feel.contentsScale = self.contentsScale
        self.addSublayer(feel)

        // We put the temperature at the right of the weather icon
        feel.anchorPoint = CGPoint(x: 0.5, y: 0)
        feel.position = CGPoint(x: at, y: 0)
    }

    func downloadImage(from url: URL) {
        getData(from: url) { data, _, error in
            guard let data = data, error == nil else { return }

            DispatchQueue.main.async() {
                let imgs = NSImage(data: data)

                // If we have something, trim and put it up
                if let img = imgs {
                    // Get the trimmed image first, goes on the left
                    let trimmedimg = img.trim()!

                    let imglayer = CALayer()
                    imglayer.frame.size.height = trimmedimg.size.height / 2
                    imglayer.frame.size.width = trimmedimg.size.width / 2
                    imglayer.contents = trimmedimg

                    imglayer.anchorPoint = CGPoint(x: 0, y: 0.5)
                    imglayer.position = CGPoint(x: 0, y: 50)
                    self.addSublayer(imglayer)

                    let tempWidth = self.addTemperature(at: imglayer.frame.width + 15)

                    // Set the final size
                    self.frame.size = CGSize(width: imglayer.frame.width + 15 + tempWidth, height: 75)
                }
            }
        }
    }
}
