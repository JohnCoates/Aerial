//
//  OpenWeather.swift
//  Aerial
//
//  Created by Guillaume Louel on 04/03/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let openWeather = try? newJSONDecoder().decode(OWeather.self, from: jsonData)

import Foundation

enum NetworkError: Error {
    case badURL
    case requestFailed
    case unknown
    case cityNotFound
}

// MARK: - OpenWeather
struct OWeather: Codable {
    let coord: OWCoord?
    let weather: [OWWeather]?
    let base: String?
    var main: OWMain?
    let visibility: Int?
    let wind: OWWind?
    let clouds: OWClouds?
    let dt: Int?
    let sys: OWSys?
    let timezone, id: Int?
    let name: String?
    let cod: Int?

    // We round them down a bit as openweather provides up to two decimal point precision
    mutating func processTemperatures() {
        guard main != nil else {
            return
        }

        if PrefsInfo.weather.degree == .celsius {
            main!.temp = main!.temp.rounded(toPlaces: 1)
            main!.feelsLike = main!.feelsLike.rounded(toPlaces: 1)
        } else {
            main!.temp = main!.temp.rounded()
            main!.feelsLike = main!.feelsLike.rounded()
        }
    }
}

// MARK: - OWClouds
struct OWClouds: Codable {
    let all: Int?
}

// MARK: - OWCoord
struct OWCoord: Codable {
    let lon, lat: Double?
}
// MARK: - OWMain
struct OWMain: Codable {
    var temp: Double
    var feelsLike: Double
    var tempMin, tempMax, pressure, humidity: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure, humidity
    }
}

// MARK: - OWSys
struct OWSys: Codable {
    let type, id: Int
    let country: String
    let sunrise, sunset: Int
}

// MARK: - OWWeather
struct OWWeather: Codable {
    let id: Int
    let main, weatherDescription, icon: String

    enum CodingKeys: String, CodingKey {
        case id, main
        case weatherDescription = "description"
        case icon
    }
}

// MARK: - OWWind
struct OWWind: Codable {
    let speed: Double
    let deg: Int
}

struct OpenWeather {

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
        return "http://api.openweathermap.org/data/2.5/weather"
            + "?lat=\(lat)&lon=\(lon)"
            + "&units=\(getUnits())"
            + "&lang=\(getShortcodeLanguage())"
            + "&APPID=\(APISecrets.openWeatherAppId)"
    }

    static func makeUrl(location: String) -> String {
        let nloc = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        return "http://api.openweathermap.org/data/2.5/weather"
            + "?q=\(nloc)"
            + "&units=\(getUnits())"
            + "&lang=\(getShortcodeLanguage())"
            + "&APPID=\(APISecrets.openWeatherAppId)"
    }

    static func fetch(completion: @escaping(Result<OWeather, NetworkError>) -> Void) {
        guard testJson == "" else {
            let jsonData = testJson.data(using: .utf8)!

            if var openWeather = try? newJSONDecoder().decode(OWeather.self, from: jsonData) {
                openWeather.processTemperatures()

                completion(.success(openWeather))
            } else {
                completion(.failure(.cityNotFound))
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
                debugLog("=== OW: Starting locationMode")

                fetchData(from: makeUrl(lat: lat, lon: lon)) { result in
                    switch result {
                    case .success(let jsonString):
                        let jsonData = jsonString.data(using: .utf8)!

                        if var openWeather = try? newJSONDecoder().decode(OWeather.self, from: jsonData) {
                            openWeather.processTemperatures()

                            completion(.success(openWeather))
                        } else {
                            completion(.failure(.cityNotFound))
                        }
                    case .failure(let error):
                        completion(.failure(.unknown))
                    }
                }
            })
        } else {
            // Just in case, we add a failsafe
            if PrefsInfo.weather.locationString == "" {
                PrefsInfo.weather.locationString = "Paris, FR"
            }
            debugLog("=== OW: Starting manual mode")

            fetchData(from: makeUrl(location: PrefsInfo.weather.locationString)) { result in
                switch result {
                case .success(let jsonString):
                    let jsonData = jsonString.data(using: .utf8)!
                    do {
                        var openWeather = try newJSONDecoder().decode(OWeather.self, from: jsonData)
                        openWeather.processTemperatures()
                        completion(.success(openWeather))
                    } catch {
                        completion(.failure(.cityNotFound))
                    }
                case .failure(_):
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
