//
//  Location.swift
//  Aerial
//
//  Created by Guillaume Louel on 24/05/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import CoreLocation

class Locations: NSObject {
    static let sharedInstance = Locations()
    let locationManager = CLLocationManager()
    var coordinates: CLLocationCoordinate2D?
    var failures: [(String) -> Void] = []
    var successes: [(CLLocationCoordinate2D) -> Void] = []

    // MARK: - Lifecycle
    override init() {
        super.init()
        locationManager.delegate = self
        debugLog("Location initialized")
    }

    func getCoordinates(failure: @escaping (_ error: String) -> Void,
                        success: @escaping (_ response: CLLocationCoordinate2D) -> Void) {
        // Perhaps they are cached already ?
        if coordinates != nil {
            debugLog("Location using cached data")
            success(coordinates!)
            return
        }

        // Check for access & start
        if CLLocationManager.locationServicesEnabled() {
            debugLog("Location services enabled")
            locationManager.startUpdatingLocation()
        } else {
            failure("Location services disabled")
        }

        if #available(OSX 10.14, *) {
            // Add our callbacks, as this is the only time we'll really defer
            failures.append(failure)
            successes.append(success)

            locationManager.requestLocation()
        } else {
            // Fallback on earlier versions
            failure("macOS 10.14 is required")
        }
    }
}

extension Locations: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations[locations.count - 1]
        coordinates = currentLocation.coordinate    // Wondering, why singular?
        debugLog("Location coordinate : \(currentLocation.coordinate)")
        locationManager.stopUpdatingLocation()      // We only want them once

        for success in successes {
            success(currentLocation.coordinate)
        }
        successes.removeAll()
        failures.removeAll()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        debugLog("LMauth status change : \(status.rawValue)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        for failure in failures {
            failure("Unable to fetch location")
        }
        successes.removeAll()
        failures.removeAll()
    }
}
