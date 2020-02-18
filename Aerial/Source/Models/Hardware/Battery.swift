//
//  Battery.swift
//  Aerial
//
//  Created by Guillaume Louel on 06/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation

struct Battery {

    // MARK: - Battery detection
    static func isUnplugged() -> Bool {
        return IOPSGetTimeRemainingEstimate() != kIOPSTimeRemainingUnlimited
    }

    static func isCharging() -> Bool {
        let timeRemaining: CFTimeInterval = IOPSGetTimeRemainingEstimate()
        if timeRemaining == -2.0 {
            return true
        } else {
            return false
        }
    }

    static func isLow() -> Bool {
        let batteryLevel = getRemainingPercent()

        // If we have no battery, we'll get 0, so in that case we're NOT low
        if batteryLevel == 0 {
            return false
        }

        return batteryLevel < 20
    }

    static func getRemainingPercent() -> Int {
        // Take a snapshot of all the power source info
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
            else { return 0 }

        // Pull out a list of power sources
        guard let sources: NSArray = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue()
            else { return 0 }

        // swiftlint:disable:next empty_count
        if sources.count > 0 {
            // For each power source...
            for ps in sources {
                // Fetch the information for a given power source out of our snapshot
                guard let info: NSDictionary = IOPSGetPowerSourceDescription(snapshot, ps as CFTypeRef)?.takeUnretainedValue()
                    else { return 0 }

                // Pull out the name and current capacity
                if let capacity = info[kIOPSCurrentCapacityKey] as? Int,
                    let max = info[kIOPSMaxCapacityKey] as? Int {

                    return Int(Double(capacity)/Double(max)*100)
                }
            }
        }

        return 0
    }
}
