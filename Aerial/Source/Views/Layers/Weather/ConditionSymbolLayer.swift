//
//  ConditionSymbolLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 24/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class ConditionSymbolLayer: CALayer {
    let mainSymbols = [0: "tornado",
                       1: "tropicalstorm",
                       2: "hurricane",
                       3: "cloud.bolt.rain",
                       4: "cloud.bolt",
                       5: "cloud.sleet",
                       6: "cloud.sleet",
                       7: "cloud.sleet",
                       8: "cloud.drizzle",
                       9: "cloud.drizzle",
                       10: "cloud.heavyrain",
                       11: "cloud.rain",
                       12: "cloud.heavyrain",
                       13: "snow",
                       14: "snow",
                       15: "wind.snow",
                       16: "snow",
                       17: "cloud.hail",
                       18: "cloud.sleet",
                       19: "sun.dust", //
                       20: "cloud.fog",
                       21: "sun.haze", //
                       22: "smoke",
                       23: "wind",
                       24: "wind",
                       25: "thermometer.snowflake",
                       26: "cloud",
                       27: "cloud.sun", //
                       28: "cloud.sun", //
                       29: "cloud.sun",
                       30: "cloud.sun",
                       31: "sun.max", //
                       32: "sun.max", //
                       33: "sun.min", //
                       34: "sun.min", //
                       35: "cloud.sleet",
                       36: "thermometer.sun",
                       37: "cloud.sun.bolt", //
                       38: "cloud.sun.bolt", //
                       39: "cloud.sun.rain", //
                       40: "cloud.heavyrain",
                       41: "cloud.snow",
                       42: "snow",
                       43: "snow",
                       44: "wrench",
                       45: "cloud.sun.rain", //
                       46: "cloud.snow",
                       47: "cloud.sun.bolt", ]//

    let nightSymbols = [19: "moon",
                        21: "moon",
                        27: "cloud.moon",
                        28: "cloud.moon",
                        29: "cloud.moon",
                        30: "cloud.moon",
                        31: "moon.stars",
                        32: "moon.stars",
                        33: "moon",
                        34: "moon",
                        37: "cloud.moon.bolt",
                        38: "cloud.moon.bolt",
                        39: "cloud.moon.rain",
                        45: "cloud.moon.rain",
                        47: "cloud.moon.bolt", ]

    init(condition: Weather.Condition, isNight: Bool) {
        super.init()

        // In case icons are updated, it's important to test them !
        // test()

        let imagePath = Bundle(for: PreferencesWindowController.self).path(
            forResource: getSymbol(condition: condition.code, isNight: isNight),
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
        for code in 0..<48 {
            let imagePath = Bundle(for: PreferencesWindowController.self).path(
            forResource: getSymbol(condition: code, isNight: true),
            ofType: "pdf")
            if imagePath == nil {
                debugLog("ERROR night \(code)")
            } else {
                debugLog("OK night \(code)")
            }

        }

        for code in 0..<48 {
            let imagePath = Bundle(for: PreferencesWindowController.self).path(
            forResource: getSymbol(condition: code, isNight: true),
            ofType: "pdf")
            if imagePath == nil {
                debugLog("ERROR day \(code)")
            } else {
                debugLog("OK day \(code)")
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

}
