//
//  YahooWeatherAPI.swift
//  Weather API Sample Code
//
//  Copyright 2019 Oath Inc. Licensed under the terms of the zLib license see https://opensource.org/licenses/Zlib for terms.
//
//  Taken from Yahoo weather's documentation
//  https://developer.yahoo.com/weather/documentation.html#oauth-swift
//  Modified for Aerial

import Foundation

import OAuthSwift

enum YahooWeatherAPIResponseType: String {
    case json = "json"
    case xml = "xml"
}

enum YahooWeatherAPIUnitType: String {
    case imperial = "f"
    case metric = "c"
}

private struct YahooWeatherAPIClientCredentials {
    var appId = ""
    var clientId = ""
    var clientSecret = ""
}

class YahooWeatherAPI {
    // Configure the following with your values.

    private let credentials = YahooWeatherAPIClientCredentials(appId: APISecrets.yahooAppId,
                                                               clientId: APISecrets.yahooClientId,
                                                               clientSecret: APISecrets.yahooClientSecret)

    private let url: String = "https://weather-ydn-yql.media.yahoo.com/forecastrss"
    private let oauth: OAuth1Swift?

    public static let shared = YahooWeatherAPI()

    private init() {
        self.oauth = OAuth1Swift(consumerKey: self.credentials.clientId, consumerSecret: self.credentials.clientSecret)
    }

    private var headers: [String: String] {
        return [
            "X-Yahoo-App-Id": self.credentials.appId,
        ]
    }

    /// Requests weather data by location name.
    ///
    /// - Parameters:
    ///   - location: the name of the location, i.e. sunnyvale,ca
    ///   - failure: failure callback
    ///   - success: success callback
    ///   - responseFormat: .xml or .json. default is .json.
    ///   - unit: metric or imperial units. default = .imperial

    public func weather(location: String,
                        failure: @escaping (_ error: OAuthSwiftError) -> Void,
                        success: @escaping (_ response: OAuthSwiftResponse) -> Void,
                        responseFormat: YahooWeatherAPIResponseType = .json,
                        unit: YahooWeatherAPIUnitType = .metric) {
        self.makeRequest(parameters: ["location": location, "format": responseFormat.rawValue, "u": unit.rawValue],
                         failure: failure, success: success)
    }

    /// Requests weather data by woeid (Where on Earth ID)
    ///
    /// - Parameters:
    ///   - woeid: The location's woeid
    ///   - failure: failure callback
    ///   - success: success callback
    ///   - responseFormat: .xml or .json. default is .json.
    ///   - unit: metric or imperial units. default = .imperial

    public func weather(woeid: String,
                        failure: @escaping (_ error: OAuthSwiftError) -> Void,
                        success: @escaping (_ response: OAuthSwiftResponse) -> Void,
                        responseFormat: YahooWeatherAPIResponseType = .json,
                        unit: YahooWeatherAPIUnitType = .metric) {
        self.makeRequest(parameters: ["woeid": woeid, "format": responseFormat.rawValue, "u": unit.rawValue], failure: failure, success: success)
    }

    /// Requests weather data by latitude and longitude
    ///
    /// - Parameters:
    ///   - lat: latitude
    ///   - lon: longiture
    ///   - failure: failure callback
    ///   - success: success callback
    ///   - responseFormat: .xml or .json. default is .json.
    ///   - unit: metric or imperial units. default = .imperial
    public func weather(lat: String,
                        lon: String,
                        failure: @escaping (_ error: OAuthSwiftError) -> Void,
                        success: @escaping (_ response: OAuthSwiftResponse) -> Void,
                        responseFormat: YahooWeatherAPIResponseType = .json,
                        unit: YahooWeatherAPIUnitType = .metric) {
        self.makeRequest(parameters: ["lat": lat, "lon": lon, "format": responseFormat.rawValue, "u": unit.rawValue],
                         failure: failure, success: success)
    }

    /// Performs the API request with the OAuthSwift client
    ///
    /// - Parameters:
    ///   - parameters: Any URL parameters to pass to the endpoint.
    ///   - failure: failure callback
    ///   - success: success callback
    private func makeRequest(parameters: [String: String],
                             failure: @escaping (_ error: OAuthSwiftError) -> Void,
                             success: @escaping (_ response: OAuthSwiftResponse) -> Void) {
        // OAuthSwift's API changed in 2.0.0
        self.oauth?.client.get(self.url, parameters: parameters, headers: self.headers) { result in
            switch result {
            case .success(let response):
                success(response)
            case .failure(let error):
                failure(error)
            }
        }
    }

}
