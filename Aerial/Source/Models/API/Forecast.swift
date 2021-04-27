//
//  Forecast.swift
//  Aerial
//
//  Created by Guillaume Louel on 26/04/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let forecast = try? newJSONDecoder().decode(Forecast.self, from: jsonData)

import Foundation

// MARK: - Forecast
struct ForecastElement: Codable {
    let cod: String?
    let message, cnt: Int?
    let list: [FList]?
    let city: City?
}

// MARK: - City
struct City: Codable {
    let id: Int?
    let name: String?
    let coord: Coord?
    let country: String?
    let population, timezone, sunrise, sunset: Int?
}

// MARK: - Coord
struct Coord: Codable {
    let lat, lon: Double?
}

// MARK: - List
struct FList: Codable {
    let dt: Int?
    let main: MainClass?
    let weather: [OWWeather]?
    let clouds: Clouds?
    let wind: Wind?
    let visibility: Int?
    let pop: Double?
    let sys: Sys?
    let dtTxt: String?
    let rain: Rain?

    enum CodingKeys: String, CodingKey {
        case dt, main, weather, clouds, wind, visibility, pop, sys
        case dtTxt = "dt_txt"
        case rain
    }
}

// MARK: - Clouds
struct Clouds: Codable {
    let all: Int?
}

// MARK: - MainClass
struct MainClass: Codable {
    let temp, feelsLike, tempMin, tempMax: Double?
    let pressure, seaLevel, grndLevel, humidity: Int?
    let tempKf: Double?

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
        case humidity
        case tempKf = "temp_kf"
    }
}

// MARK: - Rain
struct Rain: Codable {
    let the3H: Double?

    enum CodingKeys: String, CodingKey {
        case the3H = "3h"
    }
}

// MARK: - Sys
struct Sys: Codable {
    let pod: String?
}

/*
// MARK: - Weather
struct Weather: Codable {
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

// MARK: - Wind
struct Wind: Codable {
    let speed: Double?
    let deg: Int?
    let gust: Double?
}

struct Forecast {

    static var testJson = ""
/*
     static var testJson =
"""
{"cod":"200","message":0,"cnt":40,"list":[{"dt":1619460000,"main":{"temp":11.39,"feels_like":10.33,"temp_min":9.31,"temp_max":11.39,"pressure":1015,"sea_level":1015,"grnd_level":1013,"humidity":67,"temp_kf":2.08},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01d"}],"clouds":{"all":4},"wind":{"speed":8.07,"deg":36,"gust":11.31},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-26 18:00:00"},{"dt":1619470800,"main":{"temp":9.18,"feels_like":5.85,"temp_min":7.55,"temp_max":9.18,"pressure":1015,"sea_level":1015,"grnd_level":1013,"humidity":74,"temp_kf":1.63},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01n"}],"clouds":{"all":1},"wind":{"speed":7.11,"deg":47,"gust":11.44},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-26 21:00:00"},{"dt":1619481600,"main":{"temp":6.18,"feels_like":2.59,"temp_min":6.18,"temp_max":6.18,"pressure":1014,"sea_level":1014,"grnd_level":1012,"humidity":79,"temp_kf":0},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01n"}],"clouds":{"all":5},"wind":{"speed":5.5,"deg":52,"gust":9.57},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-27 00:00:00"},{"dt":1619492400,"main":{"temp":5.39,"feels_like":2.37,"temp_min":5.39,"temp_max":5.39,"pressure":1012,"sea_level":1012,"grnd_level":1011,"humidity":78,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04n"}],"clouds":{"all":71},"wind":{"speed":3.95,"deg":51,"gust":5.74},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-27 03:00:00"},{"dt":1619503200,"main":{"temp":5.71,"feels_like":3.56,"temp_min":5.71,"temp_max":5.71,"pressure":1012,"sea_level":1012,"grnd_level":1011,"humidity":73,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"clouds":{"all":71},"wind":{"speed":2.73,"deg":59,"gust":3.82},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-27 06:00:00"},{"dt":1619514000,"main":{"temp":10.12,"feels_like":8.73,"temp_min":10.12,"temp_max":10.12,"pressure":1011,"sea_level":1011,"grnd_level":1010,"humidity":59,"temp_kf":0},"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02d"}],"clouds":{"all":11},"wind":{"speed":2.8,"deg":22,"gust":3.69},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-27 09:00:00"},{"dt":1619524800,"main":{"temp":11.47,"feels_like":10.24,"temp_min":11.47,"temp_max":11.47,"pressure":1010,"sea_level":1010,"grnd_level":1008,"humidity":60,"temp_kf":0},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01d"}],"clouds":{"all":6},"wind":{"speed":4.41,"deg":346,"gust":4.06},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-27 12:00:00"},{"dt":1619535600,"main":{"temp":11.4,"feels_like":10.21,"temp_min":11.4,"temp_max":11.4,"pressure":1009,"sea_level":1009,"grnd_level":1007,"humidity":62,"temp_kf":0},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01d"}],"clouds":{"all":1},"wind":{"speed":5.31,"deg":350,"gust":4.76},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-27 15:00:00"},{"dt":1619546400,"main":{"temp":9.73,"feels_like":7.64,"temp_min":9.73,"temp_max":9.73,"pressure":1008,"sea_level":1008,"grnd_level":1007,"humidity":66,"temp_kf":0},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01d"}],"clouds":{"all":1},"wind":{"speed":4.06,"deg":4,"gust":4.64},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-27 18:00:00"},{"dt":1619557200,"main":{"temp":7.47,"feels_like":5.9,"temp_min":7.47,"temp_max":7.47,"pressure":1008,"sea_level":1008,"grnd_level":1007,"humidity":73,"temp_kf":0},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01n"}],"clouds":{"all":0},"wind":{"speed":2.41,"deg":19,"gust":2.67},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-27 21:00:00"},{"dt":1619568000,"main":{"temp":6.42,"feels_like":4.93,"temp_min":6.42,"temp_max":6.42,"pressure":1007,"sea_level":1007,"grnd_level":1006,"humidity":73,"temp_kf":0},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01n"}],"clouds":{"all":0},"wind":{"speed":2.1,"deg":69,"gust":2.05},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-28 00:00:00"},{"dt":1619578800,"main":{"temp":5.55,"feels_like":4.67,"temp_min":5.55,"temp_max":5.55,"pressure":1006,"sea_level":1006,"grnd_level":1005,"humidity":70,"temp_kf":0},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01n"}],"clouds":{"all":3},"wind":{"speed":1.43,"deg":113,"gust":1.27},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-28 03:00:00"},{"dt":1619589600,"main":{"temp":6.38,"feels_like":6.38,"temp_min":6.38,"temp_max":6.38,"pressure":1006,"sea_level":1006,"grnd_level":1005,"humidity":66,"temp_kf":0},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01d"}],"clouds":{"all":5},"wind":{"speed":1.05,"deg":141,"gust":0.83},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-28 06:00:00"},{"dt":1619600400,"main":{"temp":9.56,"feels_like":9.56,"temp_min":9.56,"temp_max":9.56,"pressure":1006,"sea_level":1006,"grnd_level":1004,"humidity":55,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"clouds":{"all":81},"wind":{"speed":0.28,"deg":285,"gust":0.41},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-28 09:00:00"},{"dt":1619611200,"main":{"temp":10.96,"feels_like":9.65,"temp_min":10.96,"temp_max":10.96,"pressure":1005,"sea_level":1005,"grnd_level":1004,"humidity":59,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":{"all":87},"wind":{"speed":3.4,"deg":317,"gust":3.19},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-28 12:00:00"},{"dt":1619622000,"main":{"temp":11.02,"feels_like":10.08,"temp_min":11.02,"temp_max":11.02,"pressure":1004,"sea_level":1004,"grnd_level":1003,"humidity":73,"temp_kf":0},"weather":[{"id":500,"main":"Rain","description":"légère pluie","icon":"10d"}],"clouds":{"all":71},"wind":{"speed":4.85,"deg":356,"gust":4.49},"visibility":10000,"pop":0.39,"rain":{"3h":0.24},"sys":{"pod":"d"},"dt_txt":"2021-04-28 15:00:00"},{"dt":1619632800,"main":{"temp":9.54,"feels_like":7.22,"temp_min":9.54,"temp_max":9.54,"pressure":1005,"sea_level":1005,"grnd_level":1004,"humidity":78,"temp_kf":0},"weather":[{"id":500,"main":"Rain","description":"légère pluie","icon":"10d"}],"clouds":{"all":58},"wind":{"speed":4.48,"deg":349,"gust":5.41},"visibility":10000,"pop":0.39,"rain":{"3h":0.47},"sys":{"pod":"d"},"dt_txt":"2021-04-28 18:00:00"},{"dt":1619643600,"main":{"temp":8,"feels_like":5.34,"temp_min":8,"temp_max":8,"pressure":1006,"sea_level":1006,"grnd_level":1004,"humidity":87,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04n"}],"clouds":{"all":75},"wind":{"speed":4.43,"deg":2,"gust":5.66},"visibility":10000,"pop":0.19,"sys":{"pod":"n"},"dt_txt":"2021-04-28 21:00:00"},{"dt":1619654400,"main":{"temp":7.49,"feels_like":3.78,"temp_min":7.49,"temp_max":7.49,"pressure":1006,"sea_level":1006,"grnd_level":1005,"humidity":90,"temp_kf":0},"weather":[{"id":500,"main":"Rain","description":"légère pluie","icon":"10n"}],"clouds":{"all":55},"wind":{"speed":6.79,"deg":17,"gust":8.49},"visibility":10000,"pop":0.33,"rain":{"3h":0.41},"sys":{"pod":"n"},"dt_txt":"2021-04-29 00:00:00"},{"dt":1619665200,"main":{"temp":7.37,"feels_like":4.15,"temp_min":7.37,"temp_max":7.37,"pressure":1008,"sea_level":1008,"grnd_level":1007,"humidity":84,"temp_kf":0},"weather":[{"id":802,"main":"Clouds","description":"partiellement nuageux","icon":"03n"}],"clouds":{"all":47},"wind":{"speed":5.35,"deg":21,"gust":7.52},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-29 03:00:00"},{"dt":1619676000,"main":{"temp":7.42,"feels_like":4.25,"temp_min":7.42,"temp_max":7.42,"pressure":1009,"sea_level":1009,"grnd_level":1008,"humidity":79,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"clouds":{"all":58},"wind":{"speed":5.28,"deg":15,"gust":6.56},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-29 06:00:00"},{"dt":1619686800,"main":{"temp":8.37,"feels_like":5.77,"temp_min":8.37,"temp_max":8.37,"pressure":1011,"sea_level":1011,"grnd_level":1010,"humidity":68,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"clouds":{"all":55},"wind":{"speed":4.49,"deg":24,"gust":5.05},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-29 09:00:00"},{"dt":1619697600,"main":{"temp":9.77,"feels_like":7.19,"temp_min":9.77,"temp_max":9.77,"pressure":1012,"sea_level":1012,"grnd_level":1011,"humidity":63,"temp_kf":0},"weather":[{"id":802,"main":"Clouds","description":"partiellement nuageux","icon":"03d"}],"clouds":{"all":32},"wind":{"speed":5.29,"deg":357,"gust":4.79},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-29 12:00:00"},{"dt":1619708400,"main":{"temp":9.95,"feels_like":7.26,"temp_min":9.95,"temp_max":9.95,"pressure":1012,"sea_level":1012,"grnd_level":1011,"humidity":61,"temp_kf":0},"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02d"}],"clouds":{"all":23},"wind":{"speed":5.75,"deg":5,"gust":5.18},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-29 15:00:00"},{"dt":1619719200,"main":{"temp":9.36,"feels_like":6.82,"temp_min":9.36,"temp_max":9.36,"pressure":1013,"sea_level":1013,"grnd_level":1012,"humidity":62,"temp_kf":0},"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02d"}],"clouds":{"all":17},"wind":{"speed":4.93,"deg":24,"gust":5.48},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-29 18:00:00"},{"dt":1619730000,"main":{"temp":6.74,"feels_like":3.73,"temp_min":6.74,"temp_max":6.74,"pressure":1014,"sea_level":1014,"grnd_level":1013,"humidity":75,"temp_kf":0},"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01n"}],"clouds":{"all":10},"wind":{"speed":4.53,"deg":49,"gust":6.7},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-29 21:00:00"},{"dt":1619740800,"main":{"temp":5.73,"feels_like":2.46,"temp_min":5.73,"temp_max":5.73,"pressure":1014,"sea_level":1014,"grnd_level":1013,"humidity":80,"temp_kf":0},"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02n"}],"clouds":{"all":15},"wind":{"speed":4.56,"deg":68,"gust":7.84},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-30 00:00:00"},{"dt":1619751600,"main":{"temp":4.76,"feels_like":1.01,"temp_min":4.76,"temp_max":4.76,"pressure":1013,"sea_level":1013,"grnd_level":1012,"humidity":77,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04n"}],"clouds":{"all":65},"wind":{"speed":5.05,"deg":80,"gust":8.61},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-30 03:00:00"},{"dt":1619762400,"main":{"temp":5.31,"feels_like":1.39,"temp_min":5.31,"temp_max":5.31,"pressure":1013,"sea_level":1013,"grnd_level":1012,"humidity":67,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"clouds":{"all":82},"wind":{"speed":5.76,"deg":68,"gust":9.46},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-30 06:00:00"},{"dt":1619773200,"main":{"temp":8.82,"feels_like":5.61,"temp_min":8.82,"temp_max":8.82,"pressure":1013,"sea_level":1013,"grnd_level":1012,"humidity":55,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":{"all":100},"wind":{"speed":6.39,"deg":65,"gust":7.86},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-30 09:00:00"},{"dt":1619784000,"main":{"temp":10.46,"feels_like":9.05,"temp_min":10.46,"temp_max":10.46,"pressure":1012,"sea_level":1012,"grnd_level":1011,"humidity":57,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":{"all":100},"wind":{"speed":6.54,"deg":41,"gust":6.83},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-30 12:00:00"},{"dt":1619794800,"main":{"temp":9.83,"feels_like":6.46,"temp_min":9.83,"temp_max":9.83,"pressure":1011,"sea_level":1011,"grnd_level":1010,"humidity":62,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":{"all":100},"wind":{"speed":7.97,"deg":26,"gust":7.75},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-30 15:00:00"},{"dt":1619805600,"main":{"temp":8.71,"feels_like":5.46,"temp_min":8.71,"temp_max":8.71,"pressure":1011,"sea_level":1011,"grnd_level":1010,"humidity":66,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":{"all":100},"wind":{"speed":6.43,"deg":36,"gust":8.77},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-04-30 18:00:00"},{"dt":1619816400,"main":{"temp":7.72,"feels_like":4.21,"temp_min":7.72,"temp_max":7.72,"pressure":1011,"sea_level":1011,"grnd_level":1010,"humidity":64,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"clouds":{"all":100},"wind":{"speed":6.4,"deg":35,"gust":9.25},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-04-30 21:00:00"},{"dt":1619827200,"main":{"temp":7.18,"feels_like":3.93,"temp_min":7.18,"temp_max":7.18,"pressure":1011,"sea_level":1011,"grnd_level":1010,"humidity":71,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"clouds":{"all":100},"wind":{"speed":5.32,"deg":30,"gust":7.7},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-05-01 00:00:00"},{"dt":1619838000,"main":{"temp":7.29,"feels_like":4.03,"temp_min":7.29,"temp_max":7.29,"pressure":1011,"sea_level":1011,"grnd_level":1009,"humidity":77,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"clouds":{"all":100},"wind":{"speed":5.4,"deg":9,"gust":7.07},"visibility":10000,"pop":0,"sys":{"pod":"n"},"dt_txt":"2021-05-01 03:00:00"},{"dt":1619848800,"main":{"temp":7.75,"feels_like":4.43,"temp_min":7.75,"temp_max":7.75,"pressure":1011,"sea_level":1011,"grnd_level":1010,"humidity":76,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":{"all":100},"wind":{"speed":5.89,"deg":0,"gust":6.65},"visibility":10000,"pop":0.03,"sys":{"pod":"d"},"dt_txt":"2021-05-01 06:00:00"},{"dt":1619859600,"main":{"temp":8.23,"feels_like":5.14,"temp_min":8.23,"temp_max":8.23,"pressure":1013,"sea_level":1013,"grnd_level":1012,"humidity":74,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":{"all":100},"wind":{"speed":5.61,"deg":348,"gust":5.85},"visibility":10000,"pop":0.07,"sys":{"pod":"d"},"dt_txt":"2021-05-01 09:00:00"},{"dt":1619870400,"main":{"temp":8.96,"feels_like":6.23,"temp_min":8.96,"temp_max":8.96,"pressure":1014,"sea_level":1014,"grnd_level":1013,"humidity":66,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":{"all":100},"wind":{"speed":5.15,"deg":330,"gust":5.36},"visibility":10000,"pop":0.05,"sys":{"pod":"d"},"dt_txt":"2021-05-01 12:00:00"},{"dt":1619881200,"main":{"temp":8.84,"feels_like":6.44,"temp_min":8.84,"temp_max":8.84,"pressure":1015,"sea_level":1015,"grnd_level":1014,"humidity":62,"temp_kf":0},"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":{"all":100},"wind":{"speed":4.29,"deg":311,"gust":4.67},"visibility":10000,"pop":0,"sys":{"pod":"d"},"dt_txt":"2021-05-01 15:00:00"}],"city":{"id":3003796,"name":"Havre-de-Grâce","coord":{"lat":49.4938,"lon":0.1077},"country":"FR","population":185972,"timezone":7200,"sunrise":1619412359,"sunset":1619464104}}
"""
*/

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
                                "zh_tw", "zu", ]

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
        return "http://api.openweathermap.org/data/2.5/forecast"
            + "?lat=\(lat)&lon=\(lon)"
            + "&units=\(getUnits())"
            + "&lang=\(getShortcodeLanguage())"
            + "&APPID=\(APISecrets.openWeatherAppId)"
    }

    static func makeUrl(location: String) -> String {
        let nloc = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        return "http://api.openweathermap.org/data/2.5/forecast"
            + "?q=\(nloc)"
            + "&units=\(getUnits())"
            + "&lang=\(getShortcodeLanguage())"
            + "&APPID=\(APISecrets.openWeatherAppId)"
    }

    static func fetch(completion: @escaping(Result<ForecastElement, NetworkError>) -> Void) {
        guard testJson == "" else {
            let jsonData = testJson.data(using: .utf8)!

            if let forecast = try? newJSONDecoder().decode(ForecastElement.self, from: jsonData) {
                completion(.success(forecast))
            } else {
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
                debugLog("=== OF: Starting locationMode")

                fetchData(from: makeUrl(lat: lat, lon: lon)) { result in
                    switch result {
                    case .success(let jsonString):
                        let jsonData = jsonString.data(using: .utf8)!

                        if let forecast = try? newJSONDecoder().decode(ForecastElement.self, from: jsonData) {
                            completion(.success(forecast))
                        } else {
                            completion(.failure(.unknown))
                        }
                    case .failure(let error):
                        completion(.failure(.unknown))
                        print(error.localizedDescription)
                    }
                }
            })
        } else {
            // Just in case, we add a failsafe
            if PrefsInfo.weather.locationString == "" {
                PrefsInfo.weather.locationString = "Paris, FR"
            }
            debugLog("=== OF: Starting manual mode")

            print(makeUrl(location: PrefsInfo.weather.locationString))
            fetchData(from: makeUrl(location: PrefsInfo.weather.locationString)) { result in
                switch result {
                case .success(let jsonString):
                    let jsonData = jsonString.data(using: .utf8)!
                    do {
                        let forecast = try newJSONDecoder().decode(ForecastElement.self, from: jsonData)
                        completion(.success(forecast))
                    } catch {
                        print("error : \(error.localizedDescription)")
                        completion(.failure(.unknown))
                    }
                case .failure(let error):
                    completion(.failure(.unknown))
                    print(error.localizedDescription)
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
