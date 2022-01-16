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

    static var windowController: PanelWindowController?

    // We use this to track whether we run as a screen saver or an app
    static var appMode = false

    // We also track darkmode here now
    static var darkMode = false

    // And we track if we are running under Aerial's Companion app
    static var underCompanion = false

    // Track our version number for logs and stuff
    static var version: String = {
        if let version = Bundle(identifier: "com.johncoates.Aerial-Test")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "Version " + version
        } else if let version = Bundle(identifier: "com.JohnCoates.Aerial")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "Version " + version
        }

        return "Version ?"
    }()

    static func checkCompanion() {
        for bundle in Bundle.allBundles {
            if let bundleId = bundle.bundleIdentifier {
                if bundleId.contains("AerialUpdater") {
                    underCompanion = true
                    debugLog("> Running under Aerial Companion!")
                }
            }
        }
    }

    static func computeDarkMode(view: NSView) {
        if #available(OSX 10.14, *) {
            debugLog("Best match appearance : \(view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]))")
            debugLog("Effective Appearence : \(view.effectiveAppearance)")
            darkMode =  view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        } else {
            darkMode = false
        }
    }

    // Language detection
    static func getPreferredLanguage() -> String {
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
    static func showErrorAlert(question: String, text: String, button: String = "OK") {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .critical
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.addButton(withTitle: button)
        alert.runModal()
    }

    static func showAlert(question: String, text: String, button1: String = "OK", button2: String = "Cancel") -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.addButton(withTitle: button1)
        alert.addButton(withTitle: button2)
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }

    static func showInfoAlert(title: String, text: String, button1: String = "OK", caution: Bool = false) {
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
    static func getSymbolLayer(_ named: String, size: CGFloat) -> CALayer {
        let imglayer = CALayer()
        imglayer.contents = Aerial.getSymbol(named)
        imglayer.frame.size = CGSize(width: size,
                                     height: size)
        return imglayer
    }

    // Symbol as a NSImage
    static func getSymbol(_ named: String) -> NSImage? {
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

    static func getMiniSymbol(_ named: String, tint: NSColor = .labelColor) -> NSImage? {
        if let symbol = getSymbol(named) {
            return resize(image: symbol, w: Int(symbol.size.width)/10, h: Int(symbol.size.height)/10).tinting(with: tint)
        } else {
            return nil
        }
    }

    // TODO: move to extension of NSImage...
    // swiftlint:disable:next identifier_name
    static func resize(image: NSImage, w: Int, h: Int) -> NSImage {
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

    static func getAccentedSymbol(_ named: String) -> NSImage? {
        if #available(OSX 10.14, *) {
            return getSymbol(named)?.tinting(with: .controlAccentColor)
        } else {
            // Fallback on earlier versions
            return getSymbol(named)?.tinting(with: .systemBlue)
        }
    }

    // This is a list of fallback symbols, until we can use those from SF Symbols 2,
    // we export from SF Symbols 1...
    private static func fallbackSymbol(_ forName: String) -> String {
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
    static func shell(launchPath: String, arguments: [String] = []) -> (String?, Int32) {
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
}
