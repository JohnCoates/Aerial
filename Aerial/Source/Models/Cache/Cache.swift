//
//  Cache.swift
//  Aerial
//
//  Created by Guillaume Louel on 06/06/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import CoreWLAN

/**
 Aerial's new Cache management
 
 Everything Cache related is moved here.
 
 - Note: Where is our cache ?
 
 Starting with 2.0, Aerial is splitting its files in two locations :
 - `~/Library/Application Support/Aerial/` : Contains manifests files and strings bundles
 - `~/Library/Caches/Aerial/` : Contains (only) videos, may be wiped by system
 
 Users of version 1.x.x will automatically see their video files migrated to the correct location.
 
 In Catalina, those paths live inside a user's container :
 `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application Support/`
 
 - Attention: Shared by multiple users writable locations are no longer possible, because sandboxing is awesome !
 */
struct Cache {
    /**
     Returns the SSID of the Wi-Fi network the user is currently connected to.
     - Note: Returns an empty string if not connected to Wi-Fi
     */
    static var ssid: String {
        return CWWiFiClient.shared().interface(withName: nil)?.ssid() ?? ""
    }

    /**
     Returns Aerial's Application Support path.
     
     + On macOS 10.14 and earlier : `~/Library/Application Support/Aerial/`
     + Starting with 10.15 : `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application Support/Aerial/`
     
     - Note: Returns `/` on failure.
     
     In some rare instances those system folders may not exist in the container, in this case Aerial can't work.
     */
    static var supportPath: String {
        // Grab an array of Application Support paths
        let appSupportPaths = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory,
            .userDomainMask,
            true)

        if appSupportPaths.isEmpty {
            errorLog("FATAL : app support does not exist!")
            return "/"
        }

        let appSupportDirectory = appSupportPaths[0] as NSString

        if aerialFolderExists(at: appSupportDirectory) {
            return appSupportDirectory.appendingPathComponent("Aerial")
        } else {
            debugLog("Creating app support directory...")
            let asPath = appSupportDirectory.appendingPathComponent("Aerial")

            let fileManager = FileManager.default
            do {
                try fileManager.createDirectory(atPath: asPath,
                                                withIntermediateDirectories: false, attributes: nil)
                return asPath
            } catch let error {
                errorLog("FATAL : Couldn't create app support directory in User directory: \(error)")
                return "/"
            }
        }
    }

    /**
     Returns Aerial's Caches path.
     
     + On macOS 10.14 and earlier : `~/Library/Caches/Aerial/`
     + Starting with 10.15 : `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Caches/Aerial/`
     
     - Note: Returns `/` on failure.
     
     In some rare instances those system folders may not exist in the container, in this case Aerial can't work.
     
     Also note that the shared `Caches` folder, `/Library/Caches/Aerial/`, is no longer user writable in Catalina and will be ignored.
     */
    static var path: String = {
        print("svp")
        // Grab an array of Cache paths
        let cacheSupportPaths = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory,
            .userDomainMask,
            true)

        if cacheSupportPaths.isEmpty {
            errorLog("Couldn't find Caches paths!")
            return "/"
        }

        let cacheSupportDirectory = cacheSupportPaths[0] as NSString
        if aerialFolderExists(at: cacheSupportDirectory) {
            return cacheSupportDirectory.appendingPathComponent("Aerial")
        } else {
            debugLog("creating Caches directory")
            let cPath = cacheSupportDirectory.appendingPathComponent("Aerial")

            let fileManager = FileManager.default
            do {
                try fileManager.createDirectory(atPath: cPath,
                                                withIntermediateDirectories: false, attributes: nil)
                return cPath
            } catch let error {
                errorLog("FATAL : Couldn't create Caches directory in User directory: \(error)")
                return "/"
            }
        }
    }()

    // MARK: - Migration from Aerial 1.x.x to 2.x.x
    /**
     Migrate files from previous versions of Aerial to the 2.x.x structure.
     
     Moves the video files from Application Support to the Caches directory.
     */
    static func migrate() {
        let supportURL = URL(fileURLWithPath: supportPath as String)
        do {
            let directoryContent = try FileManager.default.contentsOfDirectory(at: supportURL, includingPropertiesForKeys: nil)
            let videoURLs = directoryContent.filter { $0.pathExtension == "mov" }

            if !videoURLs.isEmpty {
                debugLog("Starting migration of your video files from Application Support to Caches")
                for videoURL in videoURLs {
                    debugLog("moving \(videoURL.lastPathComponent)")
                    let newURL = URL(fileURLWithPath: path.appending("/\(videoURL.lastPathComponent)"))
                    try FileManager.default.moveItem(at: videoURL, to: newURL)
                }
                debugLog("Migration done.")
            }
        } catch {
            errorLog("Error during migration, please report")
            errorLog(error.localizedDescription)
        }
    }

    //
    /**
     Is our cache full ?
     */
    static func isFull() -> Bool {
        return size() > PrefsCache.cacheLimit
    }

    /**
     Returns the cache size in GB as a string (eg. 5.1 GB)
     */
    static func sizeString() -> String {
        let pathURL = Foundation.URL(fileURLWithPath: path)

        // check if the url is a directory
        if (try? pathURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            var folderSize = 0
            (FileManager.default.enumerator(at: pathURL, includingPropertiesForKeys: nil)?.allObjects as? [URL])?.lazy.forEach {
                folderSize += (try? $0.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0
            }
            let byteCountFormatter =  ByteCountFormatter()
            byteCountFormatter.allowedUnits = .useGB
            byteCountFormatter.countStyle = .file
            let sizeToDisplay = byteCountFormatter.string(for: folderSize) ?? ""
            return sizeToDisplay
        }

        // In case it fails somehow
        return "No cache found"
    }

    // MARK: - Helpers
    /**
     Does an `/Aerial/` subfolder exist inside the given path
     - parameter at: Source path
     - returns: Path existance as a Bool.
     */
    private static func aerialFolderExists(at: NSString) -> Bool {
        let aerialFolder = at.appendingPathComponent("Aerial")
        return FileManager.default.fileExists(atPath: aerialFolder as String)
    }

    /**
     Returns cache size in GB
     */
    private static func size() -> Double {
        let pathURL = URL(fileURLWithPath: path)

        // check if the url is a directory
        if (try? pathURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            var folderSize = 0
            (FileManager.default.enumerator(at: pathURL, includingPropertiesForKeys: nil)?.allObjects as? [URL])?.lazy.forEach {
                folderSize += (try? $0.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0
            }

            return Double(folderSize) / 1000000000
        }

        return 0
    }

    // swiftlint:disable line_length
    // MARK: UI for overriding/declining a download when cache is full
    /**
     Can we download a file ?
     
     Depending on user's settings, the cache may be full or the user may not be on a trusted network.
     - Note: If a user disabled cache management (full manual mode), this will always be true.
     - parameter action: A closure with the action to be accomplished should the conditions be met.
     */
    static func ensureDownload(action: @escaping () -> Void) {
        // Do we manage the cache or not ?
        if PrefsCache.enableManagement {
            // Check network first
            if !canNetwork() {
                if !showAlert(question: "You are on a restricted WiFi network",
                             text: "Your current settings restrict downloads when not connected to a trusted network. Do you wish to proceed?\n\nReminder: You can change this setting in the Cache tab.",
                             button1: "Download Anyway",
                             button2: "Cancel") {
                    return
                }
            }

            // Then cache status
            if isFull() {
                if !showAlert(question: "Your cache is full",
                             text: "Do you want to proceed with the download ?\n\nReminder: You can change this setting in the Cache tab.",
                             button1: "Download Anyway",
                             button2: "Cancel") {
                    return
                }
            }
        }

        // If all is fine then proceed
        action()
    }

    /**
    Can we safely use network ?
    
    Depending on user's settings, they may not be on a trusted network.
    - Note: If a user disabled cache management (full manual mode), this will always be true.
    */
    static func canNetwork() -> Bool {
        if !PrefsCache.enableManagement {
            return true
        }

        if PrefsCache.restrictOnWiFi {
            // If we are not connected to WiFi we allow
            if Cache.ssid == "" || PrefsCache.allowedNetworks.contains(ssid) {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }

    // TODO: this should probably be somewhere else
    private static func showAlert(question: String, text: String, button1: String = "OK", button2: String = "Cancel") -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.addButton(withTitle: button1)
        alert.addButton(withTitle: button2)
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }
}
