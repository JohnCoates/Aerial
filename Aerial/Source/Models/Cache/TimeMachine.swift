//
//  TimeMachine.swift
//  Aerial
//
//  Created by Guillaume Louel on 13/09/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

struct TimeMachine {

    static func isExcluded() -> Bool {
        let process: Process = Process()

        debugLog("Checking if our path \(Cache.path) is excluded in Time Machine")

        process.launchPath = "/usr/bin/tmutil"
        process.arguments = ["isexcluded", Cache.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        debugLog(output ?? "No output from tmutil")
        process.waitUntilExit()

        // Now parse output if any, we're looking for "Excluded" string
        // Tested on 10.14/10.16, should be "safe" even if it doesn't work on other oses
        if let output = output {
            return output.contains("Excluded")
        } else {
            return false
        }
    }

    static func exclude() {
        let process: Process = Process()

        debugLog("Trying to exclude our path \(Cache.path) in Time Machine")

        process.launchPath = "/usr/bin/tmutil"
        process.arguments = ["addexclusion", Cache.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        debugLog(output ?? "No output from tmutil")

        process.waitUntilExit()
    }

    static func reinclude() {
        let process: Process = Process()

        debugLog("Trying to reinclude our path \(Cache.path) in Time Machine")

        process.launchPath = "/usr/bin/tmutil"
        process.arguments = ["removeexclusion", Cache.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        debugLog(output ?? "No output from tmutil")

        process.waitUntilExit()
    }
}
