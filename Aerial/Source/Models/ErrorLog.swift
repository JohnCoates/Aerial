//
//  ErrorLog.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/10/2018.
//  Copyright © 2018 John Coates. All rights reserved.
//

import Cocoa
import os.log

enum ErrorLevel: Int {
    case info, debug, warning, error
}

final class LogMessage {
    let date: Date
    let level: ErrorLevel
    let message: String
    var actionName: String?
    var actionBlock: BlockOperation?

    init(level: ErrorLevel, message: String) {
        self.level = level
        self.message = message
        self.date = Date()
    }
}

typealias LoggerCallback = (ErrorLevel) -> Void

final class Logger {
    static let sharedInstance = Logger()

    var callbacks = [LoggerCallback]()

    func addCallback(_ callback:@escaping LoggerCallback) {
        callbacks.append(callback)
    }

    func callBack(level: ErrorLevel) {
        DispatchQueue.main.async {
            for callback in self.callbacks {
                callback(level)
            }
        }
    }
}
var errorMessages = [LogMessage]()
/*
func appSupportPath() -> String {
    var appPath = ""

    // Grab an array of Application Support paths
    let appSupportPaths = NSSearchPathForDirectoriesInDomains(
        .applicationSupportDirectory,
        .userDomainMask,
        true)

    if appSupportPaths.isEmpty {
        errorLog("FATAL : app support does not exist!")
        return "/"
    }

    appPath = appSupportPaths[0]

    let appSupportDirectory = appPath as NSString

    return appSupportDirectory.appendingPathComponent("Aerial")
}*/

// This will clear the existing log if > 1MB
// This is called at startup
func rollLogIfNeeded() {
    let cacheDirectory = Cache.supportPath
    // if let cacheDirectory = path() {
    var cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
    
    if Aerial.helper.underCompanion {
        cacheFileUrl.appendPathComponent("AerialUnderCompanionLog.txt")
    } else {
        cacheFileUrl.appendPathComponent("AerialLog.txt")
    }
    
    if FileManager.default.fileExists(atPath: cacheFileUrl.path) {
        do {
            let resourceValues = try cacheFileUrl.resourceValues(forKeys: [.fileSizeKey])
            let fileSize = Int64(resourceValues.fileSize!)

            if (fileSize > 1000000) {
                try FileManager.default.removeItem(at: cacheFileUrl)
            }
                
        } catch {
            logToConsole(error.localizedDescription)
        }
    }
}

// swiftlint:disable:next identifier_name
func Log(level: ErrorLevel, message: String) {
    #if DEBUG
    print("\(message)\n")
    #endif

    errorMessages.append(LogMessage(level: level, message: message))

    // We report errors to Console.app
    if level == .error {
        if #available(OSX 10.12, *) {
            // This is faster when available
            let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Screensaver")
            os_log("AerialError: %{public}@", log: log, type: .error, message)
        } else {
            NSLog("AerialError: \(message)")
        }
    }

    // We may have set callbacks
    if level == .warning || level == .error || (level == .debug && PrefsAdvanced.debugMode) {
        Logger.sharedInstance.callBack(level: level)
    }

    // Log to disk
    if PrefsAdvanced.debugMode {
        logToConsole(message)
        logToDisk(message)
    }
}

func logToConsole(_ message: String) {
    if #available(OSX 10.12, *) {
        // This is faster when available
        let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Screensaver")
        os_log("Aerial: %{public}@", log: log, type: .default, message)
    } else {
        NSLog("Aerial: \(message)")
    }

}
func logToDisk(_ message: String) {
    DispatchQueue.main.async {
        // Prefix message with date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let string = dateFormatter.string(from: Date()) + " : " + message + "\n"

        // if let cacheDirectory = VideoCache.appSupportDirectory {

        let cacheDirectory = Cache.supportPath        // if let cacheDirectory = path() {
        var cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
        
        if Aerial.helper.underCompanion {
            cacheFileUrl.appendPathComponent("AerialUnderCompanionLog.txt")
        } else {
            cacheFileUrl.appendPathComponent("AerialLog.txt")
        }

        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)!

        if FileManager.default.fileExists(atPath: cacheFileUrl.path) {
            // Append to log
            do {
                let fileHandle = try FileHandle(forWritingTo: cacheFileUrl)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } catch {
                NSLog("AerialError: Can't open handle for AerialLog.txt")
            }
        } else {
            // Create new log
            do {
                try data.write(to: cacheFileUrl, options: .atomic)
            } catch {
                NSLog("AerialError: Can't write to file AerialLog.txt")
            }
        }
        // }
    }
}

func debugLog(_ message: String) {
    // Comment the condition to always log debug mode
    if PrefsAdvanced.debugMode {
        Log(level: .debug, message: message)
    }
}

func infoLog(_ message: String) {
    Log(level: .info, message: message)
}

func warnLog(_ message: String) {
    Log(level: .warning, message: message)
}

func errorLog(_ message: String) {
    Log(level: .error, message: "🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 " + message)
}
