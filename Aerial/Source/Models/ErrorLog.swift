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

func path() -> String {
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
    let preferences = Preferences.sharedInstance
    if level == .warning || level == .error || (level == .debug && preferences.debugMode) {
        Logger.sharedInstance.callBack(level: level)
    }

    // Log to disk
    if preferences.debugMode {
        logToDisk(message)
    }
}

func logToDisk(_ message: String) {
    DispatchQueue.main.async {
        // Prefix message with date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let string = dateFormatter.string(from: Date()) + " : " + message + "\n"

        // if let cacheDirectory = VideoCache.appSupportDirectory {

        let cacheDirectory = path()
        // if let cacheDirectory = path() {
        var cacheFileUrl = URL(fileURLWithPath: cacheDirectory as String)
        
        if Aerial.underCompanion {
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
    let preferences = Preferences.sharedInstance
    if preferences.debugMode {
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
    Log(level: .error, message: message)
}
