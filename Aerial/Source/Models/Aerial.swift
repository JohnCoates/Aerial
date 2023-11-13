//
//  Aerial.swift
//  Aerial
//
//  Contains some common helpers used throughout the code
//
//  Created by Guillaume Louel on 17/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class Aerial: NSObject {
    static let helper = Aerial()
    
    var windowController: PanelWindowController?

    // We use this to track whether we run as a screen saver or an app
    var appMode = false

    // We also track darkmode here now
    var darkMode = false

    // And we track if we are running under Aerial's Companion 
    var underCompanion = false

    let userName = NSUserName()
    
    // Track our version number for logs and stuff
    var version: String = {
        if let version = Bundle(identifier: "com.johncoates.Aerial-Test")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "Version " + version
        } else if let version = Bundle(identifier: "com.JohnCoates.Aerial")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "Version " + version
        }

        return "Version ?"
    }()


    // Using HDR in the panel will crash System Settings in macOS 13. This is fixed in macOS 13.4 🎉
    func canHDR() -> Bool {
        if #available(OSX 13.0, *) {
            if #unavailable(OSX 13.4) {
                return false
            }
        }
        
        return true
    }
    
    // Are we running under Aerial Companion ? Desktop mode/Fullscreen mode
    // Xcode debug mode is also considered as running under Companion
    
    func checkCompanion() {
        logToConsole("Checking for companion")
        if appMode {
            underCompanion = true
            logToConsole("> Running in appMode, simming Companion!")
        } else {
            for bundle in Bundle.allBundles {
                if let bundleId = bundle.bundleIdentifier {
                    if bundleId.contains("AerialUpdater") {
                        underCompanion = true
                        logToConsole("> Running under Aerial Companion!")
                    }
                }
            }
        }
    }

    func computeDarkMode(view: NSView) {
        if #available(OSX 10.14, *) {
            //debugLog("Best match appearance : \(view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]))")
            //debugLog("Effective Appearence : \(view.effectiveAppearance)")
            darkMode =  view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        } else {
            darkMode = false
        }
    }

    // Language detection
    func getPreferredLanguage() -> String {
        let printOutputLocale: NSLocale = NSLocale(localeIdentifier: Locale.preferredLanguages[0])
        if let deviceLanguageName: String = printOutputLocale.displayName(forKey: .identifier, value: Locale.preferredLanguages[0]) {
            if #available(OSX 10.12, *) {
                return "Preferred language: \(deviceLanguageName) [\(printOutputLocale.languageCode)]"
            } else {
                return "Preferred language: \(deviceLanguageName)"
            }
        } else {
            return ""
        }
    }

    // Alerts
    func showErrorAlert(question: String, text: String, button: String = "OK") {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .critical
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.addButton(withTitle: button)
        alert.runModal()
    }

    func showAlert(question: String, text: String, button1: String = "OK", button2: String = "Cancel") -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.addButton(withTitle: button1)
        alert.addButton(withTitle: button2)
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }

    func showInfoAlert(title: String, text: String, button1: String = "OK", caution: Bool = false) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = .warning
        if caution {
            alert.icon = NSImage(named: NSImage.cautionName)
        } else {
            alert.icon = NSImage(named: NSImage.infoName)
        }
        alert.addButton(withTitle: button1)
        alert.runModal()
    }

    // Symbol/icon generation

    // Symbol as a CALayer
    func getSymbolLayer(_ named: String, size: CGFloat) -> CALayer {
        let imglayer = CALayer()
        imglayer.contents = Aerial.helper.getSymbol(named)
        imglayer.frame.size = CGSize(width: size,
                                     height: size)
        return imglayer
    }

    // Symbol as a NSImage
    func getSymbol(_ named: String) -> NSImage? {
        // Use SFSymbols if available
        if #available(macOS 11.0, *) {
            if let image = NSImage(systemSymbolName: named, accessibilityDescription: named) {
                image.isTemplate = true

                // return image
                let config = NSImage.SymbolConfiguration(pointSize: 100, weight: .regular)
                return image.withSymbolConfiguration(config)?.tinting(with: .white)
            }
        }

        if let imagePath = Bundle(for: PanelWindowController.self).path(
            forResource: fallbackSymbol(named),
            ofType: "pdf") {
            return NSImage(contentsOfFile: imagePath)
        }

        return nil
    }

    func getMiniSymbol(_ named: String, tint: NSColor = .labelColor) -> NSImage? {
        if let symbol = getSymbol(named) {
            return resize(image: symbol, w: Int(symbol.size.width)/10, h: Int(symbol.size.height)/10).tinting(with: tint)
        } else {
            return nil
        }
    }

    // TODO: move to extension of NSImage...
    // swiftlint:disable:next identifier_name
    func resize(image: NSImage, w: Int, h: Int) -> NSImage {
        let destSize = NSSize(width: CGFloat(w), height: CGFloat(h))
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0,
                              width: destSize.width,
                              height: destSize.height),
                   from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
                   operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.tiffRepresentation!)!
    }

    func getAccentedSymbol(_ named: String) -> NSImage? {
        if #available(OSX 10.14, *) {
            return getSymbol(named)?.tinting(with: .controlAccentColor)
        } else {
            // Fallback on earlier versions
            return getSymbol(named)?.tinting(with: .systemBlue)
        }
    }

    // This is a list of fallback symbols, until we can use those from SF Symbols 2,
    // we export from SF Symbols 1...
    private func fallbackSymbol(_ forName: String) -> String {
        switch forName {
        case "cloud":
            return "regular.cloud"
        case "sun.max":
            return "regular.sun.max"
        case "sun.min":
            return "regular.sun.min"
        case "moon.stars":
            return "regular.moon.stars"
        case "leaf":
            return "flame"
        case "dial.min":
            return "dial"
        case "internaldrive":
            return "arrow.down.circle"
        case "display.2":
            return "tv"
        case "wrench.and.screwdriver":
            return "wrench"
        default:
            return forName
        }

    }

    // Launch a process through shell and capture/return output
    func shell(launchPath: String, arguments: [String] = []) -> (String?, Int32) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        if #available(OSX 10.13, *) {
            do {
                try task.run()
            } catch {
                // handle errors
                debugLog("Error: \(error.localizedDescription)")
            }
        } else {
            // A non existing command will crash 10.12
            task.launch()
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()

        return (output, task.terminationStatus)
    }

    func shell(_ command:String, args: [String] = []) -> String
    {
        let task = Process()
        var arguments = ["-c"]
        arguments.append(command)
        arguments += args
        task.launchPath = "/bin/bash"
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()

        return output ?? ""
        
/*        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)!
*/        /*if output.count > 0 {
            //remove newline character.
            let lastIndex = output.index(before: output.endIndex)
            return String(output[output.startIndex ..< lastIndex])
        }*/
        //return output
    }
    
    // Launch a process through shell and capture/return output
    func shell(executableURL: String, arguments: [String] = []) -> (String?, Int32) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executableURL)
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        if #available(OSX 10.13, *) {
            do {
                try task.run()
            } catch {
                // handle errors
                debugLog("Error: \(error.localizedDescription)")
            }
        } else {
            // A non existing command will crash 10.12
            task.launch()
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()

        return (output, task.terminationStatus)
    }

    
    /*
    func trySettings() {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .long
        dateFormatter.dateStyle = .none
        let time = dateFormatter.string(from: date)
        let bundleID = "/Users/guillaume/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/com.glouel.synctest"

        // Test 1
        CFPreferencesSetValue("underCompanion" as CFString, (underCompanion ? "under" : "notunder") as CFString, bundleID as CFString as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)

        CFPreferencesSetValue("lastRun" as CFString, time as CFString, bundleID as CFString as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)

        let val = CFPreferencesAppSynchronize(bundleID as CFString)
        print("value : " + String(val))
        
        
        // Test 2
        let bundleID2 = "/Users/guillaume/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/com.glouel.synctest2"
        let userDefaults = UserDefaults(suiteName: bundleID2)
        userDefaults?.setValue(time, forKey: "lastRun")

        userDefaults?.synchronize()


        userDefaults?.setValue(underCompanion ? "under" : "notunder", forKey: "underCompanion")
        userDefaults?.setValue(time, forKey: "lastRun")

        userDefaults?.synchronize()
        
 
        /*let (result, _) = shell(launchPath: "/usr/bin/defaults", arguments: ["read", "~/Library/Preferences/com.glouel.synctest","lastRun"])
        debugLog(result!)
        print(result!)*/
    }*/
    
    func getPreferencesDirectory() -> String {
        // Grab an array of Application Support paths
        let libPaths = NSSearchPathForDirectoriesInDomains(
            .libraryDirectory,
            .userDomainMask,
            true)
        
        if !libPaths.isEmpty {
            if underCompanion {
                return libPaths.first! + "/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/"
                
            } else {
                return libPaths.first! + "/Preferences/"
            }
        } else {
            return "/Users/" + Aerial.helper.userName + "/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/"
        }
    }
    
    
    // Starting with 3.1.0beta2, existing settings are moved from Preferences/ByHost to Preferences
    // This allows the sharing of preferences between regular screen saver and companion-hosted screensaver
    func migratePreferences() {
        // First check if the new settings already exists !
        let baseContainerPrefPath = getPreferencesDirectory()
        
        let newBundleFile = baseContainerPrefPath + "com.glouel.Aerial.plist"

        if FileManager.default.fileExists(atPath: newBundleFile) {
            // We are done
            logToConsole("!!! New prefs already exists")
        } else {
            logToConsole("!!! New prefs does NOT exist")
            //Look for ByHost
            let byHostPath = baseContainerPrefPath + "ByHost/"
            
            if FileManager.default.fileExists(atPath: byHostPath) {
                logToConsole("ByHost exists")
                var oldPlist = ""
                
                // Try and find the old plist
                do {
                    let directoryContents = try FileManager.default.contentsOfDirectory(atPath: byHostPath)

                    for directoryContent in directoryContents {
                        if directoryContent.starts(with: "com.JohnCoates.Aerial") {
                            // We found it !
                            oldPlist = directoryContent
                            break
                        }
                    }
                } catch {
                    logToConsole(error.localizedDescription)
                }

                // Did we get it ?
                if oldPlist != "" {
                    logToConsole("plist found " + oldPlist)
                    do {
                        try FileManager.default.copyItem(atPath: byHostPath + oldPlist, toPath: newBundleFile)
                        logToConsole("plist moved")
                    } catch {
                        logToConsole(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    // Mute me maybe
    func maybeMuteSound() {
        if !appMode && !underCompanion && PrefsAdvanced.muteGlobalSound{
            Sound.output.isMuted = true
        }
    }
    
    func maybeUnmuteSound() {
        if !appMode && !underCompanion && PrefsAdvanced.muteGlobalSound {
            Sound.output.isMuted = false
        }
    }
}
