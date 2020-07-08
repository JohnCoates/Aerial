//
//  FileHelpers.swift
//  Aerial
//
//  Created by Guillaume Louel on 08/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

struct FileHelpers {
    static func createDirectory(atPath: String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: atPath) == false {
            do {
                try fileManager.createDirectory(atPath: atPath,
                                                withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                errorLog("Couldn't create directory at \(atPath) : \(error)")
                errorLog("FATAL : There's nothing more we can do at this point, please report")
            }
        }
    }

    static func unTar(file: String, atPath: String) {
        let process: Process = Process()

        debugLog("untaring \(file) at \(atPath)")
        process.currentDirectoryPath = atPath
        process.launchPath = "/usr/bin/tar"
        process.arguments = ["-xvf", file]

        process.launch()

        process.waitUntilExit()
    }
}
