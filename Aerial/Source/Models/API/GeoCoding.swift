//
//  GeoCoding.swift
//  Aerial
//
//  Created by Guillaume Louel on 22/04/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Foundation

// MARK: - GeoCodingElement
struct GeoCodingElement: Codable {
    let name: String?
    let lat, lon: Double?
    let country, state: String?

    enum CodingKeys: String, CodingKey {
        case name
        case lat, lon, country, state
    }
}
typealias GeoCodingArray = [GeoCodingElement]

struct GeoLocation {
    let lat, lon: String
}

struct GeoCoding {

    static func fetch(completion: @escaping(Result<GeoLocation, NetworkError>) -> Void) {
        // Check if we already have a geocoded location for this ?
        if PrefsTime.geocodedString == PrefsInfo.weather.locationString {
            debugLog("returning cached location from previous geocoding")
            let lat = String(format: "%.2f", PrefsTime.cachedLatitude)
            let lon = String(format: "%.2f", PrefsTime.cachedLongitude)

            completion(.success(GeoLocation(lat: lat, lon: lon)))
        } else {
            // Seriously, please use Location services...
            debugLog("looking for location through geocoding api")
            // Just in case, we add a ugly failsafe
            if PrefsInfo.weather.locationString == "" {
                PrefsInfo.weather.locationString = "Paris, FR"
            }

            fetchData(from: makeUrl()) { result in
                switch result {
                case .success(let jsonString):
                    let jsonData = jsonString.data(using: .utf8)!

                    if let geoEntity = try? newJSONDecoder().decode(GeoCodingArray.self, from: jsonData) {
                        if geoEntity.count >= 1 {
                            let lat = String(format: "%.2f", geoEntity[0].lat!)
                            let lon = String(format: "%.2f", geoEntity[0].lon!)

                            // Let's save for next time
                            PrefsTime.geocodedString = PrefsInfo.weather.locationString
                            PrefsTime.cachedLatitude = geoEntity[0].lat!
                            PrefsTime.cachedLongitude = geoEntity[0].lon!

                            completion(.success(GeoLocation(lat: lat, lon: lon)))
                        } else {
                            completion(.failure(.unknown))

                        }
                    } else {
                        completion(.failure(.unknown))
                    }
                case .failure(_):
                    completion(.failure(.unknown))
                }
            }
        }
    }

    static func makeUrl() -> String {
        let nloc = PrefsInfo.weather.locationString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        return "http://api.openweathermap.org/geo/1.0/direct"
            + "?q=\(nloc)"
            + "&appid=\(APISecrets.openWeatherAppId)"
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
