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
    static var info: Welcome?

    // MARK: - Welcome
    struct Welcome: Codable {
        let location: Location
        let currentObservation: CurrentObservation
        let forecasts: [Forecast]

        enum CodingKeys: String, CodingKey {
            case location
            case currentObservation = "current_observation"
            case forecasts
        }
    }

    // MARK: - CurrentObservation
    struct CurrentObservation: Codable {
        let wind: Wind
        let atmosphere: Atmosphere
        let astronomy: Astronomy
        let condition: Condition
        let pubDate: Int
    }

    // MARK: - Astronomy
    struct Astronomy: Codable {
        let sunrise, sunset: String
    }

    // MARK: - Atmosphere
    struct Atmosphere: Codable {
        let humidity: Double
        let visibility: Double
        let pressure: Double
        let rising: Int
    }

    // MARK: - Condition
    struct Condition: Codable {
        let text: String
        let code, temperature: Int
    }

    // MARK: - Wind
    struct Wind: Codable {
        let chill, direction: Int
        let speed: Double
    }

    // MARK: - Forecast
    struct Forecast: Codable {
        let day: String
        let date, low, high: Int
        let text: String
        let code: Int
    }

    // MARK: - Location
    struct Location: Codable {
        let city, region: String
        let woeid: Int
        let country: String
        let lat, long: Double
        let timezoneID: String

        enum CodingKeys: String, CodingKey {
            case city, region, woeid, country, lat, long
            case timezoneID = "timezone_id"
        }
    }

    static func fetch(failure: @escaping (_ error: OAuthSwiftError) -> Void,
                      success: @escaping (_ response: OAuthSwiftResponse) -> Void) {
        if PrefsInfo.weather.locationMode == .useCurrent {
            print("=== init yw")
            YahooWeatherAPI.shared.weather(location: "sunnyvale,ca", failure: failure, success: success, unit: getDegree())
        } else {
            // Just in case, we add a failsafe
            if PrefsInfo.weather.locationString == "" {
                PrefsInfo.weather.locationString = "Paris, FR"
            }
            print("=== init yw")
            YahooWeatherAPI.shared.weather(location: PrefsInfo.weather.locationString, failure: failure, success: { response in
                    processJson(response: response) // First we process
                    success(response)   // Then the callback
                }, unit: getDegree())
        }
    }

    static func processJson(response: OAuthSwiftResponse) {
        //try? print(response.jsonObject())

        info = try? newJSONDecoder().decode(Welcome.self, from: response.data)

        if info == nil {
           errorLog("Couldn't parse JSON, please report")
            print(response.dataString())
        }
    }

    static func getDegree() -> YahooWeatherAPIUnitType {
        if PrefsInfo.weather.degree == .celsius {
            return .metric
        } else {
            return .imperial
        }
    }
}
