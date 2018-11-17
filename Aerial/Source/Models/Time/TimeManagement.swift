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

// swiftlint:disable:next type_body_length
final class TimeManagement: NSObject {
    static let sharedInstance = TimeManagement()

    // Night shift
    var isNightShiftDataCached = false
    var nightShiftAvailable = false
    var nightShiftSunrise = Date()
    var nightShiftSunset = Date()
    var solar: Solar?

    // MARK: - Lifecycle
    override init() {
        super.init()
        debugLog("Time Management initialized")
        _ = calculateFromCoordinates()
    }

    // MARK: - What should we play ?
    // swiftlint:disable:next cyclomatic_complexity
    func shouldRestrictPlaybackToDayNightVideo() -> (Bool, String) {
        let preferences = Preferences.sharedInstance
        // We can override everything on dark mode if we need to
        if preferences.darkModeNightOverride && isDarkModeEnabled() {
            return (true, "night")
        }

        // If not we check the modes
        if preferences.timeMode == Preferences.TimeMode.lightDarkMode.rawValue {
            if isDarkModeEnabled() {
                return (true, "night")
            } else {
                return (true, "day")
            }
        } else if preferences.timeMode == Preferences.TimeMode.coordinates.rawValue {
            _ = calculateFromCoordinates()

            if let _ = solar {
                var zenith: Solar.Zenith
                switch preferences.solarMode {
                case Preferences.SolarMode.strict.rawValue:
                    zenith = .strict
                case Preferences.SolarMode.official.rawValue:
                    zenith = .official
                case Preferences.SolarMode.civil.rawValue:
                    zenith = .civil
                case Preferences.SolarMode.nautical.rawValue:
                    zenith = .nautical
                default:
                    zenith = .astronimical
                }

                if (solar?.isDaytime(zenith: zenith))! {
                    return (true, "day")
                } else {
                    return (true, "night")
                }
            } else {
                errorLog("You need to input latitude and longitude for calculations to work")
                return (false, "")
            }
        } else if preferences.timeMode == Preferences.TimeMode.nightShift.rawValue {
            let (isNSCapable, sunrise, sunset, _) = getNightShiftInformation()
            if !isNSCapable {
                errorLog("Trying to use Night Shift on a non capable Mac")
                return (false, "")
            }

            return (true, dayNightCheck(sunrise: sunrise!, sunset: sunset!))
        } else if preferences.timeMode == Preferences.TimeMode.manual.rawValue {
            // We get the manual values from our preferences, as string, and convert them to dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"

            guard let dateSunrise = dateFormatter.date(from: preferences.manualSunrise!) else {
                errorLog("Invalid sunrise time in preferences")
                return(false, "")
            }
            guard let dateSunset = dateFormatter.date(from: preferences.manualSunset!) else {
                errorLog("Invalid sunset time in preferences")
                return(false, "")
            }

            return (true, dayNightCheck(sunrise: dateSunrise, sunset: dateSunset))
        }

        // default is show anything
        return (false, "")
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
    // swiftlint:disable:next cyclomatic_complexity
    func calculateFromCoordinates() -> (Bool, String) {
        let preferences = Preferences.sharedInstance

        if preferences.latitude != "" && preferences.longitude != "" {
            solar = Solar.init(coordinate: CLLocationCoordinate2D(latitude: Double(preferences.latitude!) ?? 0,
                                                                  longitude: Double(preferences.longitude!) ?? 0))
            if solar != nil {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm:ss", options: 0, locale: Locale.current)

                var sunriseString, sunsetString: String

                switch preferences.solarMode {
                case Preferences.SolarMode.official.rawValue:
                    guard let sunrise = solar?.sunrise, let sunset = solar?.sunset else {
                       return (false, "Can't process your coordinates, please verify")
                    }
                    sunriseString = dateFormatter.string(from: sunrise)
                    sunsetString = dateFormatter.string(from: sunset)
                case Preferences.SolarMode.strict.rawValue:
                    guard let sunrise = solar?.strictSunrise, let sunset = solar?.strictSunset else {
                        return (false, "Can't process your coordinates, please verify")
                    }
                    sunriseString = dateFormatter.string(from: sunrise)
                    sunsetString = dateFormatter.string(from: sunset)
                case Preferences.SolarMode.civil.rawValue:
                    guard let sunrise = solar?.civilSunrise, let sunset = solar?.civilSunset else {
                        return (false, "Can't process your coordinates, please verify")
                    }
                    sunriseString = dateFormatter.string(from: sunrise)
                    sunsetString = dateFormatter.string(from: sunset)
                case Preferences.SolarMode.nautical.rawValue:
                    guard let sunrise = solar?.nauticalSunrise, let sunset = solar?.nauticalSunset else {
                        return (false, "Can't process your coordinates, please verify")
                    }
                    sunriseString = dateFormatter.string(from: sunrise)
                    sunsetString = dateFormatter.string(from: sunset)
                default:
                    guard let sunrise = solar?.astronomicalSunrise, let sunset = solar?.astronomicalSunset else {
                        return (false, "Can't process your coordinates, please verify")
                    }
                    sunriseString = dateFormatter.string(from: sunrise)
                    sunsetString = dateFormatter.string(from: sunset)
                }

                if preferences.solarMode == Preferences.SolarMode.official.rawValue ||
                    preferences.solarMode == Preferences.SolarMode.strict.rawValue {
                    return(true, "Today’s sunrise: " + sunriseString + "  Today’s sunset: " + sunsetString)
                } else {
                    return(true, "Today’s dawn: " + sunriseString + "  Today’s dusk: " + sunsetString)
                }
            }
        }

        return (false, "Can't process your coordinates, please verify")
    }

    // MARK: Dark Mode
    func isLightDarkModeAvailable() -> (Bool, reason: String) {
        if #available(OSX 10.14, *) {
            if isDarkModeEnabled() {
                return (true, "Your Mac is currently in Dark Mode")
            } else {
                return (true, "Your Mac is currently in Light Mode")
            }
        } else {
            // Fallback on earlier versions
            return (false, "macOS 10.14 Mojave or above is required")
        }
    }

    func isDarkModeEnabled() -> Bool {
        if #available(OSX 10.14, *) {
            let modeString = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
            return (modeString == "Dark")
        } else {
            return false
        }
    }

    // MARK: Night Shift
    func isNightShiftAvailable() -> (Bool, reason: String) {
        if #available(OSX 10.12.4, *) {
            let (isAvailable, sunriseDate, sunsetDate, errorMessage) = getNightShiftInformation()

            if isAvailable {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm:ss", options: 0, locale: Locale.current)
                let sunriseString = dateFormatter.string(from: sunriseDate!)
                let sunsetString = dateFormatter.string(from: sunsetDate!)

                return (true, "Today’s sunrise: " + sunriseString + "  Today’s sunset: " + sunsetString)

            } else {
                isNightShiftDataCached = true
                return (false, errorMessage!)
            }
        } else {
            return (false, "macOS 10.12.4 or above is required")
        }
    }

    // swiftlint:disable:next cyclomatic_complexity large_tuple
    func getNightShiftInformation() -> (Bool, sunrise: Date?, sunset: Date?, error: String?) {
        if isNightShiftDataCached {
            return (nightShiftAvailable, nightShiftSunrise, nightShiftSunset, nil)
        }

        let (nsInfo, ts) = shell(launchPath: "/usr/bin/corebrightnessdiag", arguments: ["nightshift-internal"])

        if ts != 0 {
            // Task didn't return correctly ? Abort
            return (false, nil, nil, "Your Mac does not support Night Shift")
        }
        let lines = nsInfo?.split(separator: "\n")
        if lines!.count < 5 {
            // We get a couple of lines of output on unsupported Macs
            return (false, nil, nil, "Your Mac does not support Night Shift")
        }
        var sunrise: Date?, sunset: Date?

        for line in lines ?? [""] {
            if line.contains("sunrise") {
                let tmp = line.split(separator: "\"")
                if tmp.count > 1 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"

                    if let dateObj =  dateFormatter.date(from: String(tmp[1])) {
                        sunrise = dateObj
                        //dateFormatter.dateFormat = "HH:mm:ss"
                        //sunrise = dateFormatter.string(from: dateObj)
                    }
                }
            } else if line.contains("sunset") {
                let tmp = line.split(separator: "\"")
                if tmp.count > 1 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"

                    if let dateObj = dateFormatter.date(from: String(tmp[1])) {
                        sunset = dateObj
                        //dateFormatter.dateFormat = "HH:mm:ss"
                        //sunset = dateFormatter.string(from: dateObj)
                    }
                }
            }
        }

        if sunset != nil && sunrise != nil {
            nightShiftSunrise = sunrise!
            nightShiftSunset = sunset!
            nightShiftAvailable = true
            isNightShiftDataCached = true

            return (true, sunrise, sunset, nil)
        }

        // /usr/bin/corebrightnessdiag nightshift-internal | grep nextSunset | cut -d \" -f2
        warnLog("Location services may be disabled, Night Shift can't detect Sunrise and Sunset times without them")
        return (false, nil, nil, "Location services may be disabled")
    }

    private func shell(launchPath: String, arguments: [String] = []) -> (String?, Int32) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()

        return (output, task.terminationStatus)
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

    func getBrightness() -> Float {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        let pointer = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, pointer)
        let brightness = pointer.pointee
        IOObjectRelease(service)
        return brightness
    }

    func setBrightness(level: Float) {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, level)
        IOObjectRelease(service)
    }

    // MARK: - Battery detection
    func isOnBattery() -> Bool {
        return IOPSGetTimeRemainingEstimate() != -2.0
    }

    func isBatteryLow() -> Bool {
        return [kIOPSLowBatteryWarningEarly, kIOPSLowBatteryWarningFinal].contains(IOPSGetBatteryWarningLevel())
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

        /*let status = CLLocationManager.authorizationStatus()
        if status == .restricted || status == .denied {
            
            print("Location Denied")
            
            return
        }
        else if status == .notDetermined {
            
            print("Show ask for location")
            
            return
        }
        else if status == .authorized {
            print("This should work?")
            
            return
        }*/

        if #available(OSX 10.14, *) {
            print("reqloc")
            locationManager.requestLocation()
        } else {
            // Fallback on earlier versions
        }
    }

}

// MARK: - Core Location Delegates
extension TimeManagement: CLLocationManagerDelegate {
/*    func locationManager(_ manager: CLLocationManager, didUpdateTo newLocation: CLLocation, from oldLocation: CLLocation) {
        
        print("\(newLocation) \(oldLocation)")
        
    }*/

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations[locations.count - 1]
        print("\(currentLocation)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorLog("Location Manager error : \(error)")
    }
}
