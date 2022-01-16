//
//  ConditionSymbolLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 24/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import Foundation

class ConditionSymbolLayer: CALayer {
    let mainSymbols = [200: "cloud.bolt.rain",
                       201: "cloud.bolt.rain",
                       202: "cloud.bolt.rain",
                       210: "cloud.sun.bolt",
                       211: "cloud.bolt",
                       212: "cloud.bolt",
                       221: "cloud.bolt",
                       230: "cloud.bolt.rain",
                       231: "cloud.bolt.rain",
                       232: "cloud.bolt.rain",

                       300: "cloud.drizzle",
                       301: "cloud.drizzle",
                       302: "cloud.drizzle",
                       310: "cloud.drizzle",
                       311: "cloud.drizzle",
                       312: "cloud.drizzle",
                       313: "cloud.drizzle",
                       314: "cloud.drizzle",
                       321: "cloud.drizzle",

                       500: "cloud.sun.rain",
                       501: "cloud.rain",
                       502: "cloud.heavyrain",
                       503: "cloud.heavyrain",
                       504: "cloud.heavyrain",

                       511: "cloud.sleet",

                       520: "cloud.rain",
                       521: "cloud.rain",
                       522: "cloud.heavyrain",
                       531: "cloud.rain",

                       600: "snow",
                       601: "snow",
                       602: "cloud.snow",

                       611: "cloud.sleet",
                       612: "cloud.sleet",
                       613: "cloud.sleet",
                       615: "cloud.sleet",
                       616: "cloud.sleet",

                       620: "snow",
                       621: "snow",
                       622: "cloud.snow",

                       701: "sun.haze",
                       711: "smoke",
                       721: "sun.haze",
                       731: "sun.dust",
                       741: "sun.haze",
                       751: "sun.dust",
                       761: "sun.dust",
                       762: "sun.dust",
                       781: "tornado",

                       800: "sun.max",
                       801: "sun.max",
                       802: "cloud.sun",
                       803: "cloud.sun",
                       804: "cloud" ]//

    let nightSymbols = [210: "cloud.moon.bolt",

                        500: "cloud.moon.rain",

                        800: "moon.stars",
                        801: "moon",
                        802: "cloud.moon",
                        803: "cloud.moon" ]

    init(weather: OWWeather, dt: Int, isNight: Bool, size: Int, square: Bool = false) {
        super.init()

        var img: NSImage?

        switch PrefsInfo.weather.icons {
        case .flat:
            img = makeSymbol(name: getSymbol(condition: weather.id,
                                                 isNight: isNight), size: size)
        case .colorflat:
            img = makeColorSymbol(name: getColorSymbol(condition: weather.id,
                                                  isNight: isNight), size: size)
        case .oweather:
            downloadImage(from: URL(string: "http://openweathermap.org/img/wn/\(weather.icon)@4x.png")!, size: size)
            img = nil
        }

        if let img = img {
            if !square {
                frame.size.height = CGFloat(size)
                frame.size.width = CGFloat(size) * img.size.width / img.size.height
            } else {
                if frame.size.height > frame.size.width {
                    frame.size.height = CGFloat(size)
                    frame.size.width = CGFloat(size) * img.size.width / img.size.height
                } else {
                    frame.size.width = CGFloat(size)
                    frame.size.height = CGFloat(size) * img.size.height / img.size.width
                }
            }

            contents = img
        }
    }

    init(weather: OWWeather, dt: Int, sunrise: Int, sunset: Int, size: Int, square: Bool = false) {
        super.init()

        // In case icons are updated, it's important to test them !
        // test()

        let isNight = isNight(dt: dt, sunrise: sunrise, sunset: sunset)
        var img: NSImage?

        switch PrefsInfo.weather.icons {
        case .flat:
            img = makeSymbol(name: getSymbol(condition: weather.id,
                                                 isNight: isNight), size: size)
        case .colorflat:
            img = makeColorSymbol(name: getColorSymbol(condition: weather.id,
                                                  isNight: isNight), size: size)
        case .oweather:
            downloadImage(from: URL(string: "http://openweathermap.org/img/wn/\(weather.icon)@4x.png")!, size: size)
            img = nil
        }

        if let img = img {
            if !square {
                frame.size.height = CGFloat(size)
                frame.size.width = CGFloat(size) * img.size.width / img.size.height
            } else {
                if frame.size.height > frame.size.width {
                    frame.size.height = CGFloat(size)
                    frame.size.width = CGFloat(size) * img.size.width / img.size.height
                } else {
                    frame.size.width = CGFloat(size)
                    frame.size.height = CGFloat(size) * img.size.height / img.size.width
                }
            }

            contents = img
        }
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeSymbol(name: String, size: Int) -> NSImage? {
        if #available(macOS 11.0, *) {
            if let image = NSImage(systemSymbolName: name, accessibilityDescription: name) {
                image.isTemplate = true

                // return image
                let config = NSImage.SymbolConfiguration(pointSize: CGFloat(size), weight: .regular)
                return image.withSymbolConfiguration(config)?.tinting(with: .white)
            }
        } else {
            // We fallback on the pdf icons
            let imagePath = Bundle(for: PanelWindowController.self).path(
                forResource: name, ofType: "pdf") ?? ""

            let img = NSImage(contentsOfFile: imagePath)

            return img
        }

        return nil
    }

    func makeColorSymbol(name: String, size: Int) -> NSImage? {
        if #available(macOS 11.0, *) {
            if let image = NSImage(systemSymbolName: name, accessibilityDescription: name) {
                image.isTemplate = false

                // return image
                let config = NSImage.SymbolConfiguration(pointSize: CGFloat(size), weight: .regular)
                return image.withSymbolConfiguration(config) // ?.tinting(with: .white)
            }
        }

        return nil
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    func downloadImage(from url: URL, size: Int) {
        frame.size.height = CGFloat(size)
        frame.size.width = CGFloat(size)

        getData(from: url) { data, _, error in
            guard let data = data, error == nil else { return }

            DispatchQueue.main.async() {
                let img = NSImage(data: data)
                self.contents = img

                /*
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
                    self.addFeelsLike(at: imglayer.frame.width + 15 + (tempWidth / 2))
                    self.addWind(at: (imglayer.frame.width + 15 + tempWidth) / 2)

                    // Set the final size
                    self.frame.size = CGSize(width: imglayer.frame.width + 15 + tempWidth, height: 75)
                }
                 */
            }
        }
    }

    func test() {
        nightSymbols.forEach { (key: Int, value: String) in
            let imagePath = Bundle(for: PanelWindowController.self).path(
            forResource: getSymbol(condition: key, isNight: true),
            ofType: "pdf")
            if imagePath == nil {
                debugLog("ERROR night \(key) \(value)")
            } else {
                debugLog("OK night \(key) \(value)")
            }
        }

        mainSymbols.forEach { (key: Int, value: String) in
            let imagePath = Bundle(for: PanelWindowController.self).path(
            forResource: getSymbol(condition: key, isNight: true),
            ofType: "pdf")
            if imagePath == nil {
                debugLog("ERROR day \(key) \(value)")
            } else {
                debugLog("OK day \(key) \(value)")
            }
        }

    }

    func getSymbol(condition: Int, isNight: Bool) -> String {
        if isNight && nightSymbols[condition] != nil {
            return nightSymbols[condition]!
        } else {
            if mainSymbols[condition] != nil {
                return mainSymbols[condition]!
            } else {
                return "wrench"
            }
        }
    }

    func getColorSymbol(condition: Int, isNight: Bool) -> String {
        let regular = getSymbol(condition: condition, isNight: isNight)

        if regular != "wrench" && regular != "snow" && regular != "tornado" {
            return regular + ".fill"
        } else {
            return regular
        }
    }

    func isNight(dt: Int, sunrise: Int, sunset: Int) -> Bool {
        if dt < sunrise || dt > sunset {
            return true
        } else {
            return false
        }
    }

}
