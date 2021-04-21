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

/*    static var testJson =
"""
{"lat":49.49,"lon":0.117,"timezone":"Europe/Paris","timezone_offset":3600,"current":{"dt":1616517018,"sunrise":1616478944,"sunset":1616523379,"temp":12.31,"feels_like":9.79,"pressure":1024,"humidity":62,"dew_point":5.25,"uvi":0.25,"clouds":0,"visibility":10000,"wind_speed":2.06,"wind_deg":340,"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01d"}]},"minutely":[{"dt":1616517060,"precipitation":0},{"dt":1616517120,"precipitation":0},{"dt":1616517180,"precipitation":0},{"dt":1616517240,"precipitation":0},{"dt":1616517300,"precipitation":0},{"dt":1616517360,"precipitation":0},{"dt":1616517420,"precipitation":0},{"dt":1616517480,"precipitation":0},{"dt":1616517540,"precipitation":0},{"dt":1616517600,"precipitation":0},{"dt":1616517660,"precipitation":0},{"dt":1616517720,"precipitation":0},{"dt":1616517780,"precipitation":0},{"dt":1616517840,"precipitation":0},{"dt":1616517900,"precipitation":0},{"dt":1616517960,"precipitation":0},{"dt":1616518020,"precipitation":0},{"dt":1616518080,"precipitation":0},{"dt":1616518140,"precipitation":0},{"dt":1616518200,"precipitation":0},{"dt":1616518260,"precipitation":0},{"dt":1616518320,"precipitation":0},{"dt":1616518380,"precipitation":0},{"dt":1616518440,"precipitation":0},{"dt":1616518500,"precipitation":0},{"dt":1616518560,"precipitation":0},{"dt":1616518620,"precipitation":0},{"dt":1616518680,"precipitation":0},{"dt":1616518740,"precipitation":0},{"dt":1616518800,"precipitation":0},{"dt":1616518860,"precipitation":0},{"dt":1616518920,"precipitation":0},{"dt":1616518980,"precipitation":0},{"dt":1616519040,"precipitation":0},{"dt":1616519100,"precipitation":0},{"dt":1616519160,"precipitation":0},{"dt":1616519220,"precipitation":0},{"dt":1616519280,"precipitation":0},{"dt":1616519340,"precipitation":0},{"dt":1616519400,"precipitation":0},{"dt":1616519460,"precipitation":0},{"dt":1616519520,"precipitation":0},{"dt":1616519580,"precipitation":0},{"dt":1616519640,"precipitation":0},{"dt":1616519700,"precipitation":0},{"dt":1616519760,"precipitation":0},{"dt":1616519820,"precipitation":0},{"dt":1616519880,"precipitation":0},{"dt":1616519940,"precipitation":0},{"dt":1616520000,"precipitation":0},{"dt":1616520060,"precipitation":0},{"dt":1616520120,"precipitation":0},{"dt":1616520180,"precipitation":0},{"dt":1616520240,"precipitation":0},{"dt":1616520300,"precipitation":0},{"dt":1616520360,"precipitation":0},{"dt":1616520420,"precipitation":0},{"dt":1616520480,"precipitation":0},{"dt":1616520540,"precipitation":0},{"dt":1616520600,"precipitation":0},{"dt":1616520660,"precipitation":0}],"hourly":[{"dt":1616515200,"temp":12.31,"feels_like":10.75,"pressure":1024,"humidity":62,"dew_point":5.25,"uvi":0.8,"clouds":0,"visibility":10000,"wind_speed":0.69,"wind_deg":160,"wind_gust":2.36,"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01d"}],"pop":0},{"dt":1616518800,"temp":11.8,"feels_like":10.38,"pressure":1024,"humidity":64,"dew_point":5.22,"uvi":0.25,"clouds":21,"visibility":10000,"wind_speed":0.49,"wind_deg":147,"wind_gust":1.81,"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02d"}],"pop":0},{"dt":1616522400,"temp":10.77,"feels_like":9.05,"pressure":1024,"humidity":67,"dew_point":4.9,"uvi":0,"clouds":29,"visibility":10000,"wind_speed":0.82,"wind_deg":145,"wind_gust":1.19,"weather":[{"id":802,"main":"Clouds","description":"partiellement nuageux","icon":"03d"}],"pop":0},{"dt":1616526000,"temp":9.93,"feels_like":7.61,"pressure":1024,"humidity":71,"dew_point":4.92,"uvi":0,"clouds":2,"visibility":10000,"wind_speed":1.68,"wind_deg":156,"wind_gust":1.69,"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01n"}],"pop":0},{"dt":1616529600,"temp":9.1,"feels_like":6,"pressure":1024,"humidity":75,"dew_point":4.91,"uvi":0,"clouds":1,"visibility":10000,"wind_speed":2.8,"wind_deg":174,"wind_gust":3.49,"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01n"}],"pop":0},{"dt":1616533200,"temp":8.22,"feels_like":4.58,"pressure":1024,"humidity":79,"dew_point":4.81,"uvi":0,"clouds":2,"visibility":10000,"wind_speed":3.54,"wind_deg":188,"wind_gust":5.32,"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01n"}],"pop":0},{"dt":1616536800,"temp":7.87,"feels_like":4.03,"pressure":1024,"humidity":80,"dew_point":4.69,"uvi":0,"clouds":19,"visibility":10000,"wind_speed":3.77,"wind_deg":193,"wind_gust":5.48,"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02n"}],"pop":0},{"dt":1616540400,"temp":7.52,"feels_like":3.62,"pressure":1024,"humidity":81,"dew_point":4.54,"uvi":0,"clouds":34,"visibility":10000,"wind_speed":3.82,"wind_deg":199,"wind_gust":5.53,"weather":[{"id":802,"main":"Clouds","description":"partiellement nuageux","icon":"03n"}],"pop":0},{"dt":1616544000,"temp":7.11,"feels_like":3.07,"pressure":1024,"humidity":82,"dew_point":4.29,"uvi":0,"clouds":40,"visibility":10000,"wind_speed":3.95,"wind_deg":188,"wind_gust":5.44,"weather":[{"id":802,"main":"Clouds","description":"partiellement nuageux","icon":"03n"}],"pop":0},{"dt":1616547600,"temp":6.87,"feels_like":2.81,"pressure":1024,"humidity":82,"dew_point":3.96,"uvi":0,"clouds":19,"visibility":10000,"wind_speed":3.92,"wind_deg":189,"wind_gust":5.63,"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02n"}],"pop":0},{"dt":1616551200,"temp":6.62,"feels_like":2.52,"pressure":1023,"humidity":82,"dew_point":3.73,"uvi":0,"clouds":26,"visibility":10000,"wind_speed":3.91,"wind_deg":195,"wind_gust":5.7,"weather":[{"id":802,"main":"Clouds","description":"partiellement nuageux","icon":"03n"}],"pop":0},{"dt":1616554800,"temp":6.41,"feels_like":2.37,"pressure":1023,"humidity":82,"dew_point":3.57,"uvi":0,"clouds":22,"visibility":10000,"wind_speed":3.77,"wind_deg":199,"wind_gust":5.3,"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02n"}],"pop":0},{"dt":1616558400,"temp":6.2,"feels_like":2.27,"pressure":1023,"humidity":83,"dew_point":3.4,"uvi":0,"clouds":22,"visibility":10000,"wind_speed":3.6,"wind_deg":198,"wind_gust":4.63,"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02n"}],"pop":0},{"dt":1616562000,"temp":6,"feels_like":1.96,"pressure":1023,"humidity":83,"dew_point":3.3,"uvi":0,"clouds":25,"visibility":10000,"wind_speed":3.71,"wind_deg":197,"wind_gust":4.72,"weather":[{"id":802,"main":"Clouds","description":"partiellement nuageux","icon":"03n"}],"pop":0},{"dt":1616565600,"temp":5.8,"feels_like":1.68,"pressure":1023,"humidity":83,"dew_point":3.1,"uvi":0,"clouds":27,"visibility":10000,"wind_speed":3.77,"wind_deg":194,"wind_gust":4.89,"weather":[{"id":802,"main":"Clouds","description":"partiellement nuageux","icon":"03d"}],"pop":0},{"dt":1616569200,"temp":6.25,"feels_like":2.14,"pressure":1023,"humidity":81,"dew_point":3.17,"uvi":0.26,"clouds":97,"visibility":10000,"wind_speed":3.79,"wind_deg":198,"wind_gust":5.44,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0},{"dt":1616572800,"temp":7.1,"feels_like":2.89,"pressure":1023,"humidity":78,"dew_point":3.39,"uvi":0.82,"clouds":98,"visibility":10000,"wind_speed":4.01,"wind_deg":208,"wind_gust":5.44,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0},{"dt":1616576400,"temp":8.05,"feels_like":3.85,"pressure":1023,"humidity":75,"dew_point":3.78,"uvi":1.72,"clouds":94,"visibility":10000,"wind_speed":4.08,"wind_deg":211,"wind_gust":5.46,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0},{"dt":1616580000,"temp":9.1,"feels_like":5.22,"pressure":1023,"humidity":72,"dew_point":4.33,"uvi":2.65,"clouds":82,"visibility":10000,"wind_speed":3.75,"wind_deg":227,"wind_gust":5.55,"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"pop":0},{"dt":1616583600,"temp":9.81,"feels_like":6.51,"pressure":1023,"humidity":71,"dew_point":4.66,"uvi":3.42,"clouds":71,"visibility":10000,"wind_speed":3.05,"wind_deg":247,"wind_gust":4.99,"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"pop":0},{"dt":1616587200,"temp":10.25,"feels_like":7.07,"pressure":1023,"humidity":68,"dew_point":4.61,"uvi":3.73,"clouds":71,"visibility":10000,"wind_speed":2.82,"wind_deg":272,"wind_gust":4.58,"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"pop":0},{"dt":1616590800,"temp":10.49,"feels_like":7.11,"pressure":1023,"humidity":66,"dew_point":4.17,"uvi":2.93,"clouds":100,"visibility":10000,"wind_speed":3.05,"wind_deg":291,"wind_gust":4.48,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0},{"dt":1616594400,"temp":10.6,"feels_like":7.14,"pressure":1022,"humidity":65,"dew_point":4.07,"uvi":2.27,"clouds":100,"visibility":10000,"wind_speed":3.14,"wind_deg":302,"wind_gust":4.64,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0},{"dt":1616598000,"temp":10.68,"feels_like":7.42,"pressure":1022,"humidity":68,"dew_point":4.74,"uvi":1.44,"clouds":100,"visibility":10000,"wind_speed":3.06,"wind_deg":302,"wind_gust":4.28,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0},{"dt":1616601600,"temp":10.54,"feels_like":7.57,"pressure":1022,"humidity":72,"dew_point":5.73,"uvi":0.65,"clouds":100,"visibility":10000,"wind_speed":2.84,"wind_deg":296,"wind_gust":3.98,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0},{"dt":1616605200,"temp":10.34,"feels_like":7.78,"pressure":1022,"humidity":75,"dew_point":6.08,"uvi":0.21,"clouds":100,"visibility":10000,"wind_speed":2.38,"wind_deg":291,"wind_gust":3.79,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0},{"dt":1616608800,"temp":9.88,"feels_like":7.2,"pressure":1022,"humidity":77,"dew_point":6.2,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":2.53,"wind_deg":297,"wind_gust":3.57,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0},{"dt":1616612400,"temp":9.79,"feels_like":7.41,"pressure":1023,"humidity":80,"dew_point":6.45,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":2.25,"wind_deg":307,"wind_gust":2.93,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0},{"dt":1616616000,"temp":9.4,"feels_like":7.34,"pressure":1023,"humidity":82,"dew_point":6.55,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":1.78,"wind_deg":310,"wind_gust":1.82,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0},{"dt":1616619600,"temp":9.32,"feels_like":7.63,"pressure":1023,"humidity":83,"dew_point":6.63,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":1.29,"wind_deg":309,"wind_gust":1.37,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0},{"dt":1616623200,"temp":9.23,"feels_like":7.38,"pressure":1023,"humidity":84,"dew_point":6.77,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":1.54,"wind_deg":291,"wind_gust":1.65,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0},{"dt":1616626800,"temp":9.17,"feels_like":7.3,"pressure":1022,"humidity":87,"dew_point":6.99,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":1.72,"wind_deg":275,"wind_gust":1.73,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0},{"dt":1616630400,"temp":9.02,"feels_like":7.23,"pressure":1022,"humidity":89,"dew_point":7.13,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":1.66,"wind_deg":250,"wind_gust":1.75,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0.02},{"dt":1616634000,"temp":8.93,"feels_like":6.67,"pressure":1022,"humidity":89,"dew_point":7.18,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":2.3,"wind_deg":257,"wind_gust":2.82,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0.08},{"dt":1616637600,"temp":8.76,"feels_like":6.54,"pressure":1022,"humidity":90,"dew_point":7.21,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":2.24,"wind_deg":252,"wind_gust":2.93,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0.02},{"dt":1616641200,"temp":8.64,"feels_like":6.06,"pressure":1022,"humidity":91,"dew_point":7.16,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":2.77,"wind_deg":241,"wind_gust":3.66,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0.03},{"dt":1616644800,"temp":8.5,"feels_like":5.64,"pressure":1022,"humidity":91,"dew_point":7.14,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":3.13,"wind_deg":243,"wind_gust":4.2,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0.03},{"dt":1616648400,"temp":8.21,"feels_like":5.13,"pressure":1022,"humidity":93,"dew_point":7.09,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":3.45,"wind_deg":240,"wind_gust":4.66,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04n"}],"pop":0.11},{"dt":1616652000,"temp":8.17,"feels_like":5.05,"pressure":1022,"humidity":93,"dew_point":7.16,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":3.5,"wind_deg":243,"wind_gust":4.86,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0.2},{"dt":1616655600,"temp":8.62,"feels_like":5.64,"pressure":1022,"humidity":91,"dew_point":7.18,"uvi":0.24,"clouds":99,"visibility":10000,"wind_speed":3.34,"wind_deg":263,"wind_gust":5.13,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"pop":0.2},{"dt":1616659200,"temp":8.89,"feels_like":5.64,"pressure":1022,"humidity":89,"dew_point":7.06,"uvi":0.71,"clouds":98,"visibility":10000,"wind_speed":3.7,"wind_deg":284,"wind_gust":5.14,"weather":[{"id":500,"main":"Rain","description":"légère pluie","icon":"10d"}],"pop":0.24,"rain":{"1h":0.15}},{"dt":1616662800,"temp":9.08,"feels_like":5.52,"pressure":1023,"humidity":85,"dew_point":6.66,"uvi":1.47,"clouds":78,"visibility":10000,"wind_speed":3.99,"wind_deg":279,"wind_gust":4.54,"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"pop":0.2},{"dt":1616666400,"temp":9.44,"feels_like":6.1,"pressure":1023,"humidity":81,"dew_point":6.3,"uvi":1.74,"clouds":64,"visibility":10000,"wind_speed":3.57,"wind_deg":266,"wind_gust":3.75,"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"pop":0.1},{"dt":1616670000,"temp":9.77,"feels_like":6.21,"pressure":1023,"humidity":78,"dew_point":5.97,"uvi":2.25,"clouds":56,"visibility":10000,"wind_speed":3.81,"wind_deg":266,"wind_gust":4.15,"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"pop":0.1},{"dt":1616673600,"temp":10,"feels_like":6.47,"pressure":1022,"humidity":74,"dew_point":5.36,"uvi":2.45,"clouds":50,"visibility":10000,"wind_speed":3.6,"wind_deg":271,"wind_gust":4.3,"weather":[{"id":802,"main":"Clouds","description":"partiellement nuageux","icon":"03d"}],"pop":0.06},{"dt":1616677200,"temp":10.17,"feels_like":7.18,"pressure":1022,"humidity":69,"dew_point":4.55,"uvi":2.66,"clouds":18,"visibility":10000,"wind_speed":2.59,"wind_deg":272,"wind_gust":3.53,"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02d"}],"pop":0},{"dt":1616680800,"temp":10.38,"feels_like":7.85,"pressure":1022,"humidity":67,"dew_point":4.25,"uvi":2.06,"clouds":18,"visibility":10000,"wind_speed":1.87,"wind_deg":273,"wind_gust":2.88,"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02d"}],"pop":0},{"dt":1616684400,"temp":10.59,"feels_like":8.16,"pressure":1021,"humidity":65,"dew_point":4.11,"uvi":1.3,"clouds":14,"visibility":10000,"wind_speed":1.66,"wind_deg":262,"wind_gust":2.81,"weather":[{"id":801,"main":"Clouds","description":"peu nuageux","icon":"02d"}],"pop":0}],"daily":[{"dt":1616500800,"sunrise":1616478944,"sunset":1616523379,"temp":{"day":9.74,"min":4.43,"max":12.31,"night":7.87,"eve":10.77,"morn":4.43},"feels_like":{"day":6.83,"night":4.03,"eve":9.05,"morn":0.4},"pressure":1026,"humidity":64,"dew_point":3.14,"wind_speed":2.08,"wind_deg":204,"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"clouds":54,"pop":0,"uvi":3.9},{"dt":1616587200,"sunrise":1616565214,"sunset":1616609871,"temp":{"day":10.25,"min":5.8,"max":10.68,"night":9.23,"eve":9.88,"morn":5.8},"feels_like":{"day":7.07,"night":7.38,"eve":7.2,"morn":1.68},"pressure":1023,"humidity":68,"dew_point":4.61,"wind_speed":2.82,"wind_deg":272,"weather":[{"id":803,"main":"Clouds","description":"nuageux","icon":"04d"}],"clouds":71,"pop":0,"uvi":3.73},{"dt":1616673600,"sunrise":1616651484,"sunset":1616696363,"temp":{"day":10,"min":8.03,"max":10.68,"night":8.03,"eve":9.65,"morn":8.17},"feels_like":{"day":6.47,"night":3.57,"eve":7.06,"morn":5.05},"pressure":1022,"humidity":74,"dew_point":5.36,"wind_speed":3.6,"wind_deg":271,"weather":[{"id":500,"main":"Rain","description":"légère pluie","icon":"10d"}],"clouds":50,"pop":0.24,"rain":0.15,"uvi":2.66},{"dt":1616760000,"sunrise":1616737755,"sunset":1616782855,"temp":{"day":12.23,"min":6.34,"max":12.23,"night":6.47,"eve":7.25,"morn":6.34},"feels_like":{"day":5.31,"night":-3.23,"eve":-2.3,"morn":0.47},"pressure":1013,"humidity":65,"dew_point":5.81,"wind_speed":8.53,"wind_deg":207,"weather":[{"id":500,"main":"Rain","description":"légère pluie","icon":"10d"}],"clouds":0,"pop":1,"rain":4.15,"uvi":3.53},{"dt":1616846400,"sunrise":1616824025,"sunset":1616869346,"temp":{"day":9.25,"min":6.42,"max":10.1,"night":8.47,"eve":9.51,"morn":6.8},"feels_like":{"day":4,"night":4.64,"eve":5.38,"morn":-1.04},"pressure":1027,"humidity":64,"dew_point":2.64,"wind_speed":5.31,"wind_deg":265,"weather":[{"id":500,"main":"Rain","description":"légère pluie","icon":"10d"}],"clouds":84,"pop":0.77,"rain":2.45,"uvi":3.36},{"dt":1616932800,"sunrise":1616910296,"sunset":1616955838,"temp":{"day":11.23,"min":6.68,"max":11.83,"night":9.57,"eve":10.58,"morn":6.68},"feels_like":{"day":6.82,"night":6.33,"eve":9.18,"morn":0.45},"pressure":1028,"humidity":67,"dew_point":5.31,"wind_speed":4.79,"wind_deg":236,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":88,"pop":0,"uvi":4},{"dt":1617019200,"sunrise":1616996566,"sunset":1617042330,"temp":{"day":14.31,"min":7.43,"max":16.01,"night":11.32,"eve":14.47,"morn":7.43},"feels_like":{"day":11.39,"night":8.27,"eve":11.91,"morn":3.6},"pressure":1028,"humidity":59,"dew_point":6.23,"wind_speed":2.99,"wind_deg":182,"weather":[{"id":800,"main":"Clear","description":"ciel dégagé","icon":"01d"}],"clouds":0,"pop":0,"uvi":4},{"dt":1617105600,"sunrise":1617082837,"sunset":1617128821,"temp":{"day":16.34,"min":9.27,"max":16.56,"night":14.33,"eve":15.49,"morn":9.27},"feels_like":{"day":13.69,"night":12.13,"eve":13.09,"morn":5.58},"pressure":1023,"humidity":70,"dew_point":10.58,"wind_speed":4.19,"wind_deg":181,"weather":[{"id":804,"main":"Clouds","description":"couvert","icon":"04d"}],"clouds":87,"pop":0,"uvi":4}]}
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

    static func fetch(completion: @escaping(Result<OCOneCall, NetworkError>) -> Void) {
        guard testJson == "" else {
            let jsonData = testJson.data(using: .utf8)!

            do {
                var openWeather = try newJSONDecoder().decode(OCOneCall.self, from: jsonData)
                completion(.success(openWeather))
            } catch {
                print("decoder failure")
                // print(error)
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
                debugLog("=== OW: Starting locationMode")

                fetchData(from: makeUrl(lat: lat, lon: lon)) { result in
                    switch result {
                    case .success(let jsonString):
                        print(jsonString)
                        let jsonData = jsonString.data(using: .utf8)!

                        if var openWeather = try? newJSONDecoder().decode(OCOneCall.self, from: jsonData) {
                            openWeather.processTemperatures()

                            completion(.success(openWeather))
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
            /*
            // Just in case, we add a failsafe
            if PrefsInfo.weather.locationString == "" {
                PrefsInfo.weather.locationString = "Paris, FR"
            }
            debugLog("=== OW: Starting manual mode")

            print(makeUrl(location: PrefsInfo.weather.locationString))
            fetchData(from: makeUrl(location: PrefsInfo.weather.locationString)) { result in
                switch result {
                case .success(let jsonString):
                    print(jsonString)
                    let jsonData = jsonString.data(using: .utf8)!
                    do {
                        var openWeather = try newJSONDecoder().decode(OWeather.self, from: jsonData)
                        openWeather.processTemperatures()
                        completion(.success(openWeather))
                    } catch {
                        print("error : \(error.localizedDescription)")
                        completion(.failure(.unknown))
                    }
                case .failure(let error):
                    completion(.failure(.unknown))
                    print(error.localizedDescription)
                }
            }
            */
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
