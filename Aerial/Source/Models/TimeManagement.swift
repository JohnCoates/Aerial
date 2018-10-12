//
//  TimeManagement.swift
//  Aerial
//
//  Created by Guillaume Louel on 05/10/2018.
//  Copyright © 2018 John Coates. All rights reserved.
//

import Foundation
import Cocoa

class TimeManagement {
    static let sharedInstance = TimeManagement()

    // Night shift
    var isNightShiftDataCached = false
    var nightShiftAvailable = false
    var nightShiftSunrise = Date()
    var nightShiftSunset = Date()
    

    // MARK: init
    init() {
        debugLog("Time Management initialized")
    }

    func shouldRestrictPlaybackToDayNightVideo() -> (Bool,String)
    {
        let preferences = Preferences.sharedInstance
        if preferences.timeMode == Preferences.TimeMode.lightDarkMode.rawValue {
            if (isDarkModeEnabled()) {
                return (true, "night")
            } else {
                return (true, "day")
            }
        }
        else if preferences.timeMode == Preferences.TimeMode.nightShift.rawValue {
            let (isNSCapable, sunrise, sunset, _) = getNightShiftInformation()
            if (!isNSCapable) {
                NSLog("Aerial : Trying to use Night Shift on a non capable Mac")
                return (false,"")
            }
            
            return (true,dayNightCheck(sunrise: sunrise!, sunset: sunset!))
        }
        else if preferences.timeMode == Preferences.TimeMode.manual.rawValue {
            // We get the manual values from our preferences, as string, and convert them to dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            
            guard let dateSunrise = dateFormatter.date(from: preferences.manualSunrise!) else {
                NSLog("Aerial : Invalid sunrise time in preferences")
                return(false,"")
            }
            guard let dateSunset = dateFormatter.date(from: preferences.manualSunset!) else {
                NSLog("Aerial : Invalid sunrise time in preferences")
                return(false,"")
            }
            
            return (true,dayNightCheck(sunrise: dateSunrise, sunset: dateSunset))
        }
        
        // default is show anything
        return (false, "")
    }
    
    // Check if we are at day or night based on provided sunrise and sunset dates
    private func dayNightCheck(sunrise:Date,sunset:Date) -> String
    {
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
        if (nsunrise < now && now < nsunset) {
            return "day"
        } else {
            return "night"
        }
    }
    
    // Change a date's day to today
    private func todayizeDate(date:Date) -> Date? {
        // Get today's date as a string
        let dateFormatter = DateFormatter()
        let current = Date()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from:current)
        
        // Extract hour from date
        dateFormatter.dateFormat = "HH:mm:ss +zzzz"
        let format = today + " " + dateFormatter.string(from:date)
        
        // Now return the todayized string
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
        if let newdate = dateFormatter.date(from: format) {
            return newdate
        } else {
            return nil
        }
    }
    
    // MARK: Dark Mode
    func isLightDarkModeAvailable() -> (Bool,reason: String) {
        if #available(OSX 10.14, *) {
            if (isDarkModeEnabled()) {
                return (true,"Your Mac is currently in Dark Mode")
            }
            else {
                return (true,"Your Mac is currently in Light Mode")
            }
        } else {
            // Fallback on earlier versions
            return (false,"macOS 10.14 Mojave or above is required")
        }
    }
    
    func isDarkModeEnabled() -> Bool {
        if #available(OSX 10.14, *) {
            let modeString = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
            
            return (modeString == "Dark")
        }
        else {
            return false
        }
    }

    // MARK: Night Shift
    func isNightShiftAvailable() -> (Bool,reason: String) {
        if #available(OSX 10.12.4, *) {
            let (isAvailable,sunriseDate,sunsetDate, errorMessage) = getNightShiftInformation()
            
            if (isAvailable) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm:ss", options: 0, locale: Locale.current)
                let sunriseString = dateFormatter.string(from: sunriseDate!)
                let sunsetString = dateFormatter.string(from: sunsetDate!)

                return (true,"Today's Sunrise: " + sunriseString + "  Today's Sunset: " + sunsetString)

            } else {
                isNightShiftDataCached = true
                return (false,errorMessage!)
            }
        } else {
            return (false,"macOS 10.12.4 or above is required")
        }
    }

    func getNightShiftInformation() -> (Bool,sunrise: Date?, sunset: Date?, error: String?)
    {
        if (isNightShiftDataCached) {
            return (nightShiftAvailable, nightShiftSunrise, nightShiftSunset, nil)
        }
        
        let (nsInfo,ts) = shell(launchPath: "/usr/bin/corebrightnessdiag", arguments: ["nightshift-internal"])

        if (ts != 0) {
            // Task didn't return correctly ? Abort
            return (false,nil,nil,"Your Mac does not support Night Shift")
        }
        let lines = nsInfo?.split(separator: "\n")
        if lines!.count < 5 {
            // We get a couple of lines of output on unsupported Macs
            return (false,nil,nil,"Your Mac does not support Night Shift")
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
        
        if (sunset != nil && sunrise != nil)
        {
            nightShiftSunrise = sunrise!
            nightShiftSunset = sunset!
            nightShiftAvailable = true
            isNightShiftDataCached = true
            
            return(true,sunrise,sunset, nil)
        }
        
        // /usr/bin/corebrightnessdiag nightshift-internal | grep nextSunset | cut -d \" -f2
        
        return (false,nil,nil,"Location services may be disabled")
    }
    
    private func shell(launchPath: String, arguments: [String] = []) -> (String? , Int32) {
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

}
