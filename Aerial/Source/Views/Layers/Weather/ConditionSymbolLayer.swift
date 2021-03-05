//
//  ConditionSymbolLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 24/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

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
                       801: "sun.min",
                       802: "cloud.sun",
                       803: "cloud.sun",
                       804: "cloud", ]//

    let nightSymbols = [210: "cloud.moon.bolt",

                        500: "cloud.moon.rain",

                        800: "moon.stars",
                        801: "moon",
                        802: "cloud.moon",
                        803: "cloud.moon", ]

    init(condition: OWeather) {
        super.init()

        // In case icons are updated, it's important to test them !
        //test()

        let isNight = isNight(dt: condition.dt!, sys: condition.sys!)

        let imagePath = Bundle(for: PanelWindowController.self).path(
            forResource: getSymbol(condition: condition.weather![0].id, isNight: isNight ),
            ofType: "pdf")

        if imagePath != nil {
            let img = NSImage(contentsOfFile: imagePath!)
            /*img = img!.tinting(with: .white)*/
            frame.size.height = img!.size.height*0.5
            frame.size.width = img!.size.width*0.5
            contents = img
        } else {
            frame.size.height = 50
            frame.size.width = 50
            backgroundColor = .init(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    func isNight(dt: Int, sys: OWSys) -> Bool {
        if dt < sys.sunrise || dt > sys.sunset {
            return true
        } else {
            return false
        }
    }

}
