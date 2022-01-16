//
//  OWOneCall.swift
//  Aerial
//
//  Created by Guillaume Louel on 23/03/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let oCOneCall = try? newJSONDecoder().decode(OCOneCall.self, from: jsonData)

import Foundation

// MARK: - OCOneCall
struct OCOneCall: Codable {
    let lat, lon: Double?
    let timezone: String?
    let timezoneOffset: Int?
    let current: OCCurrent?
    let minutely: [OCMinutely]?
    let hourly: [OCCurrent]?
    let daily: [OCDaily]?

    enum CodingKeys: String, CodingKey {
        case lat, lon, timezone
        case timezoneOffset = "timezone_offset"
        case current, minutely, hourly, daily
    }

    // We round them down a bit as openweather provides up to two decimal point precision
    mutating func processTemperatures() {
        /*
        guard main != nil else {
            return
        }

        if PrefsInfo.weather.degree == .celsius {
            main!.temp = main!.temp.rounded(toPlaces: 1)
            main!.feelsLike = main!.feelsLike.rounded(toPlaces: 1)
        } else {
            main!.temp = main!.temp.rounded()
            main!.feelsLike = main!.feelsLike.rounded()
        }*/
    }
}

// MARK: - OCCurrent
struct OCCurrent: Codable {
    let dt, sunrise, sunset: Int?
    let temp, feelsLike: Double?
    let pressure, humidity: Int?
    let dewPoint, uvi: Double?
    let clouds, visibility: Int?
    let windSpeed: Double?
    let windDeg: Int?
    let weather: [OWWeather]?
    let windGust, pop: Double?
    let rain: OCRain?

    enum CodingKeys: String, CodingKey {
        case dt, sunrise, sunset, temp
        case feelsLike = "feels_like"
        case pressure, humidity
        case dewPoint = "dew_point"
        case uvi, clouds, visibility
        case windSpeed = "wind_speed"
        case windDeg = "wind_deg"
        case weather
        case windGust = "wind_gust"
        case pop, rain
    }
}

// MARK: - OCRain
struct OCRain: Codable {
    let the1H: Double?

    enum CodingKeys: String, CodingKey {
        case the1H = "1h"
    }
}
/*
// MARK: - OCWeather
struct OCWeather: Codable {
    let id: Int?
    let main: String?
    let weatherDescription: String?
    let icon: String?

    enum CodingKeys: String, CodingKey {
        case id, main
        case weatherDescription = "description"
        case icon
    }
}*/

// MARK: - OCDaily
struct OCDaily: Codable {
    let dt, sunrise, sunset: Int?
    let temp: OCTemp?
    let feelsLike: OCFeelsLike?
    let pressure, humidity: Int?
    let dewPoint, windSpeed: Double?
    let windDeg: Int?
    let weather: [OWWeather]?
    let clouds: Int?
    let pop, uvi, rain: Double?

    enum CodingKeys: String, CodingKey {
        case dt, sunrise, sunset, temp
        case feelsLike = "feels_like"
        case pressure, humidity
        case dewPoint = "dew_point"
        case windSpeed = "wind_speed"
        case windDeg = "wind_deg"
        case weather, clouds, pop, uvi, rain
    }
}

// MARK: - OCFeelsLike
struct OCFeelsLike: Codable {
    let day, night, eve, morn: Double?
}

// MARK: - OCTemp
struct OCTemp: Codable {
    let day, min, max, night: Double?
    let eve, morn: Double?
}

// MARK: - OCMinutely
struct OCMinutely: Codable {
    let dt, precipitation: Int?
}

struct OneCall {

    static var testJson = ""

    static func getUnits() -> String {
        if PrefsInfo.weather.degree == .celsius {
            return "metric"
        } else {
            return "imperial"
        }
    }

    static func getShortcodeLanguage() -> String {
        let preferences = Preferences.sharedInstance

        // Those are the languages supported by OpenWeather
        let weatherLanguages = ["af", "al", "ar", "az", "bg", "ca", "cz", "da", "de", "el", "en",
                                "eu", "fa", "fi", "fr", "gl", "he", "hi", "hr", "hu", "id", "it",
                                "ja", "kr", "la", "lt", "mk", "no", "nl", "pl", "pt", "pt_br", "ro",
                                "ru", "sv", "sk", "sl", "es", "sr", "th", "tr", "uk", "vi", "zh_cn",
                                "zh_tw", "zu" ]

        if preferences.ciOverrideLanguage == "" {
            let bestMatchedLanguage = Bundle.preferredLocalizations(from: weatherLanguages, forPreferences: Locale.preferredLanguages).first
            if let match = bestMatchedLanguage {
                debugLog("Best matched language : \(match)")
                return match
            }
        } else {
            debugLog("Overrode matched language : \(preferences.ciOverrideLanguage!)")
            return preferences.ciOverrideLanguage!
        }

        // We fallback here if nothing works
        return "en"
    }

    static func makeUrl(lat: String, lon: String) -> String {
        return "http://api.openweathermap.org/data/2.5/onecall"
            + "?lat=\(lat)&lon=\(lon)"
            + "&units=\(getUnits())"
            + "&lang=\(getShortcodeLanguage())"
            + "&APPID=\(APISecrets.openWeatherAppId)"
    }

    /*
    static func makeUrl(location: String) -> String {
        
        let nloc = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        return "http://api.openweathermap.org/data/2.5/onecall"
            + "?q=\(nloc)"
            + "&units=\(getUnits())"
            + "&lang=\(getShortcodeLanguage())"
            + "&APPID=\(APISecrets.openWeatherAppId)"
    }*/

    // swiftlint:disable:next cyclomatic_complexity
    static func fetch(completion: @escaping(Result<OCOneCall, NetworkError>) -> Void) {
        guard testJson == "" else {
            let jsonData = testJson.data(using: .utf8)!

            do {
                let openWeather = try newJSONDecoder().decode(OCOneCall.self, from: jsonData)
                completion(.success(openWeather))
            } catch {
                completion(.failure(.unknown))
            }

            return
        }

        if PrefsInfo.weather.locationMode == .useCurrent {
            let location = Locations.sharedInstance

            location.getCoordinates(failure: { (_) in
                completion(.failure(.unknown))
            }, success: { (coordinates) in
                let lat = String(format: "%.2f", coordinates.latitude)
                let lon = String(format: "%.2f", coordinates.longitude)
                debugLog("=== OC: Starting locationMode")

                fetchData(from: makeUrl(lat: lat, lon: lon)) { result in
                    switch result {
                    case .success(let jsonString):
                        let jsonData = jsonString.data(using: .utf8)!

                        if var openWeather = try? newJSONDecoder().decode(OCOneCall.self, from: jsonData) {
                            openWeather.processTemperatures()

                            completion(.success(openWeather))
                        } else {
                            completion(.failure(.unknown))
                        }
                    case .failure(_):
                        completion(.failure(.unknown))
                    }
                }
            })
        } else {
            // Urgh, please use location services...
            debugLog("=== OC: Starting manual mode")

            GeoCoding.fetch { result in
                switch result {
                case .success(let geoLocation):
                    fetchData(from: makeUrl(lat: geoLocation.lat, lon: geoLocation.lon)) { result in
                        switch result {
                        case .success(let jsonString):
                            let jsonData = jsonString.data(using: .utf8)!

                            if var openWeather = try? newJSONDecoder().decode(OCOneCall.self, from: jsonData) {
                                openWeather.processTemperatures()

                                completion(.success(openWeather))
                            } else {
                                completion(.failure(.unknown))
                            }
                        case .failure(_):
                            completion(.failure(.unknown))
                        }
                    }
                case .failure(let error):
                    debugLog(error.localizedDescription)
                    completion(.failure(.unknown))
                }
            }
        }
    }

    private static func fetchData(from urlString: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
        // check the URL is OK, otherwise return with a failure
        guard let url = URL(string: urlString) else {
            completion(.failure(.badURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            // the task has completed – push our work back to the main thread
            DispatchQueue.main.async {
                if let data = data {
                    // success: convert the data to a string and send it back
                    let stringData = String(decoding: data, as: UTF8.self)
                    completion(.success(stringData))
                } else if error != nil {
                    // any sort of network failure
                    completion(.failure(.requestFailed))
                } else {
                    // this ought not to be possible, yet here we are
                    completion(.failure(.unknown))
                }
            }
        }.resume()
    }
}
