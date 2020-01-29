//
//  TimeManagement.swift
//  Aerial
//
//  Created by Guillaume Louel on 05/10/2018.
//  Copyright © 2018 John Coates. All rights reserved.
//

import Foundation
import Cocoa
import CoreLocation
import IOKit.ps

final class TimeManagement: NSObject {
    static let sharedInstance = TimeManagement()

    var solar: Solar?

    // MARK: - Lifecycle
    override init() {
        super.init()
        debugLog("Time Management initialized")
        _ = calculateFromCoordinates()
    }

    // MARK: - What should we play ?
    func shouldRestrictPlaybackToDayNightVideo() -> (Bool, String) {
        // We override everything on dark mode if we need to
        if PrefsTime.darkModeNightOverride && DarkMode.isEnabled() {
            return (true, "night")
        }

        // If not we check the modes
        if PrefsTime.timeMode == .lightDarkMode {
            return (true, DarkMode.isEnabled() ? "night" : "day")
        } else if PrefsTime.timeMode == .coordinates {
            _ = calculateFromCoordinates()

            if solar != nil {
                let zenith = getZenith(PrefsTime.solarMode)

                if (solar?.isDaytime(zenith: zenith))! {
                    return (true, "day")
                } else {
                    return (true, "night")
                }
            } else {
                errorLog("You need to input latitude and longitude for calculations to work")
                return (false, "")
            }
        } else if PrefsTime.timeMode == .nightShift {
            let (isNSCapable, sunrise, sunset, _) = NightShift.getInformation()
            if !isNSCapable {
                errorLog("Trying to use Night Shift on a non capable Mac")
                return (false, "")
            }

            return (true, dayNightCheck(sunrise: sunrise!, sunset: sunset!))
        } else if PrefsTime.timeMode == .manual {
            // We get the manual values from our preferences, as string, and convert them to dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"

            guard let dateSunrise = dateFormatter.date(from: PrefsTime.manualSunrise) else {
                errorLog("Invalid sunrise time in preferences")
                return(false, "")
            }
            guard let dateSunset = dateFormatter.date(from: PrefsTime.manualSunset) else {
                errorLog("Invalid sunset time in preferences")
                return(false, "")
            }

            return (true, dayNightCheck(sunrise: dateSunrise, sunset: dateSunset))
        }

        // default is show anything
        return (false, "")
    }

    // Get the correct Zenith value for our pref
    private func getZenith(_ mode: SolarMode) -> Solar.Zenith {
        switch mode {
        case .strict:
            return .strict
        case .official:
            return .official
        case .civil:
            return .civil
        case .nautical:
            return .nautical
        default:
            return .astronimical
        }
    }

    // Check if we are at day or night based on provided sunrise and sunset dates
    private func dayNightCheck(sunrise: Date, sunset: Date) -> String {
        var nsunrise = sunrise
        var nsunset = sunset
        let now = Date()
        // When used with manual mode, sunrise and sunset will always be set to 2000-01-01
        // With night mode, sunrise and sunset are the "current" ones (if at 23:00, sunset = today, sunrise = tomorrow)
        // That may not always be true though, if you mess with your system clock (go back in time), both values
        // can be in the future (and possibly in the past)
        //
        // As a sanity check, we check if we are between a sunset and a sunrise (prefered calculation mode with night
        // shift as it takes into account everything correctly for us), if not we todayize the dates. In manual mode,
        // will always be todayized
        if (now < sunrise && now < sunset) || (now > sunrise && now > sunset) {
            nsunrise = todayizeDate(date: sunrise)!
            nsunset = todayizeDate(date: sunset)!
        }

        // Then comparison is trivial !
        if nsunrise < now && now < nsunset {
            return "day"
        } else {
            return "night"
        }
    }

    // Change a date's day to today
    private func todayizeDate(date: Date) -> Date? {
        // Get today's date as a string
        let dateFormatter = DateFormatter()
        let current = Date()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: current)

        // Extract hour from date
        dateFormatter.dateFormat = "HH:mm:ss +zzzz"
        let format = today + " " + dateFormatter.string(from: date)

        // Now return the todayized string
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
        if let newdate = dateFormatter.date(from: format) {
            return newdate
        } else {
            return nil
        }
    }

    // MARK: Calculate using Solar
    func calculateFromCoordinates() -> (Bool, String) {
        if PrefsTime.latitude != "" && PrefsTime.longitude != "" {
            solar = Solar.init(coordinate: CLLocationCoordinate2D(
                latitude: Double(PrefsTime.latitude) ?? 0,
                longitude: Double(PrefsTime.longitude) ?? 0))

            if solar != nil {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm:ss", options: 0, locale: Locale.current)

                let (sunrise, sunset) = getSunriseSunsetForMode(PrefsTime.solarMode)

                if sunrise == nil || sunset == nil {
                   return (false, "Can't process your coordinates, please verify")
                }

                let sunriseString = dateFormatter.string(from: sunrise!)
                let sunsetString = dateFormatter.string(from: sunset!)

                if PrefsTime.solarMode == .official || PrefsTime.solarMode == .strict {
                    return(true, "Today’s sunrise: " + sunriseString + "  Today’s sunset: " + sunsetString)
                } else {
                    return(true, "Today’s dawn: " + sunriseString + "  Today’s dusk: " + sunsetString)
                }
            }
        }

        return (false, "Can't process your coordinates, please verify")
    }

    // Helper to get the correct sunrise/sunset
    func getSunriseSunsetForMode(_ mode: SolarMode) -> (Date?, Date?) {
        if let sol = solar {
            switch mode {
            case .official:
                return (sol.sunrise, sol.sunset)
            case .strict:
                return (sol.strictSunrise, sol.strictSunset)
            case .civil:
                return (sol.civilSunrise, sol.civilSunset)
            case .nautical:
                return (sol.nauticalSunrise, sol.nauticalSunset)
            default:
                return (sol.astronomicalSunrise, sol.astronomicalSunset)
            }
        }

        return (nil, nil)
    }

    // MARK: - Brightness stuff (early, may get moved/will change)
    func getCurrentSleepTime() -> Int {
        // pmset -g | grep "^[ ]*sleep" | awk '{ print $2 }'

        let pipe1 = Pipe()
        let pmset = Process()
        pmset.launchPath = "/usr/bin/env"
        pmset.arguments = ["pmset", "-g"]
        pmset.standardOutput = pipe1

        let pipe2 = Pipe()
        let grep = Process()
        grep.launchPath = "/usr/bin/env"
        grep.arguments = ["grep", "^[ ]*sleep"]
        grep.standardInput = pipe1
        grep.standardOutput = pipe2

        let pipeOut = Pipe()
        let awk = Process()
        awk.launchPath = "/usr/bin/env"
        awk.arguments = ["awk", "{ print $2 }"]
        awk.standardInput = pipe2
        awk.standardOutput = pipeOut
        awk.standardOutput = pipeOut

        pmset.launch()
        grep.launch()
        awk.launch()
        awk.waitUntilExit()

        let data = pipeOut.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        if output != nil {
            let lines = output!.split(separator: "\n")
            if lines.count == 1 {
                let newline = Int(lines[0])
                if let newLineIndex = newline {
                    return newLineIndex
                }
            }
        }

        return 0
    }

    // MARK: - Location detection
    func startLocationDetection() {
        let locationManager = CLLocationManager()
        locationManager.delegate = self

        if CLLocationManager.locationServicesEnabled() {
            debugLog("Location services enabled")
            locationManager.startUpdatingLocation()
        } else {
            errorLog("Location services are disabled, please check your macOS settings!")
        }

        if #available(OSX 10.14, *) {
            locationManager.requestLocation()
        } else {
            // Fallback on earlier versions
        }
    }

}

// MARK: - Core Location Delegates
extension TimeManagement: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        _ = locations[locations.count - 1]
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorLog("Location Manager error : \(error)")
    }
}
