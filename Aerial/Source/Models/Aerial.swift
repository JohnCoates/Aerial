//
//  Aerial.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class Aerial: NSObject {
    static let instance = Aerial()

    // We use this to track whether we run as a screen saver or an app
    var appMode = false

    static func getVersionString() -> String {
        if let version = Bundle(identifier: "com.johncoates.Aerial-Test")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "Version " + version
        } else if let version = Bundle(identifier: "com.JohnCoates.Aerial")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "Version " + version
        }

        return "Version ?"
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

    static func getSymbol(_ named: String) -> NSImage? {
        if let imagePath = Bundle(for: PreferencesWindowController.self).path(
            forResource: named,
            ofType: "pdf") {
            return NSImage(contentsOfFile: imagePath)
        }

        return nil
    }
}
