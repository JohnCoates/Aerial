//
//  WeatherAPI.swift
//  Aerial
//
//  Created by Guillaume Louel on 15/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import OAuthSwift

struct Weather {

    static func fetch(failure: @escaping (_ error: OAuthSwiftError) -> Void,
                      success: @escaping (_ response: OAuthSwiftResponse) -> Void) {
        if PrefsInfo.weather.locationMode == .useCurrent {
            print("=== init yw")
            YahooWeatherAPI.shared.weather(location: "sunnyvale,ca", failure: failure, success: success, unit: .imperial)
        } else {
            // Just in case, we add a failsafe
            if PrefsInfo.weather.locationString == "" {
                PrefsInfo.weather.locationString = "Paris, FR"
            }
            print("=== init yw")
            YahooWeatherAPI.shared.weather(location: PrefsInfo.weather.locationString, failure: failure, success: success, unit: .imperial)
        }
    }
}
