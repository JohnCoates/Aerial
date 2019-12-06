//
//  BatteryManagement.swift
//  Aerial
//
//  Created by Guillaume Louel on 06/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation

struct BatteryManagement {

    // MARK: - Battery detection
    func isOnBattery() -> Bool {
        return IOPSGetTimeRemainingEstimate() != kIOPSTimeRemainingUnlimited
    }

    func isBatteryLow() -> Bool {
        enum BatteryError: Error { case error }

        do {
            // Take a snapshot of all the power source info
            guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
                else { throw BatteryError.error }

            // Pull out a list of power sources
            guard let sources: NSArray = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue()
                else { throw BatteryError.error }

            //swiftlint:disable:next empty_count
            if sources.count > 0 {
                // For each power source...
                for ps in sources {
                    // Fetch the information for a given power source out of our snapshot
                    guard let info: NSDictionary = IOPSGetPowerSourceDescription(snapshot, ps as CFTypeRef)?.takeUnretainedValue()
                        else { throw BatteryError.error }

                    // Pull out the name and current capacity
                    if let name = info[kIOPSNameKey] as? String,
                        let capacity = info[kIOPSCurrentCapacityKey] as? Int,
                        let max = info[kIOPSMaxCapacityKey] as? Int {

                        var perc: Double
                        if max != 100 {
                            perc = Double(capacity)/Double(max)*100
                        } else {
                            perc = Double(capacity)
                        }

                        debugLog("\(name): \(capacity) of \(max)")
                        debugLog("percentage : \(perc)")

                        // If any battery (should only be one but...) is below 20%, return true
                        // If not we keep looking
                        if perc < 20 {
                            return true
                        }
                    }
                }
            } else {
                debugLog("No battery source")
                // There's no battery, so no issue here
                return false
            }
        } catch {
            debugLog("Battery detection error")
        }

        return false
    }

}
