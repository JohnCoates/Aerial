//
//  Music.swift
//  Aerial
//
//  Created by Guillaume Louel on 29/06/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Foundation
import AppKit

typealias MusicCallback = (SongInfo) -> Void

struct SongInfo {
    let name: String
    let artist: String
    let album: String
    let artwork: NSImage?
}

// swiftlint:disable:next type_body_length
class Music {
    static let instance: Music = Music()
    var callbacks = [MusicCallback]()
    var wasSetup = false

    // This is called once at init to set our observer
    func setup() {
        if !wasSetup {
            debugLog("🎧 registering private callback")

            // Load framework
            let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))
            
            // Get a Swift function for MRMediaRemoteRegisterForNowPlayingNotifications
            guard let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString) else { return }
            typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
            let MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)
            
            // Call the register function
            MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
            
            DispatchQueue.main.async {
                // Register App state change callback
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(Music.mediaRemoteAppStateChange(_:)),
                                                       name: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"), object: nil)
                
                // Register playback info change callback
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(Music.mediaRemoteCallback(_:)),
                                                       name: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"), object: nil)
            }

            wasSetup = true
        }
    }

    // Callback to get paused status from some apps that may not update info pause on change
    @objc func mediaRemoteAppStateChange(_ aNotification: Notification) {
        debugLog("🎧 app state change")
        
        if let userInfo = aNotification.userInfo {
            if let rate = userInfo["kMRMediaRemoteNowPlayingApplicationIsPlayingUserInfoKey"] as? Double {
                
                if rate == 0 {
                    debugLog("🎧 playback is paused, clearing")
                    // Pause the thing
                    for callback in self.callbacks {
                        callback(SongInfo(name: "", artist: "", album: "", artwork: nil))
                    }
                }
            }
        }
    }
    
    // General info change callback
    @objc func mediaRemoteCallback(_ aNotification: Notification?) {
        var album = ""
        var name = ""
        var artist = ""
        var artwork: NSImage?
        
        debugLog("🎧 media remote callback")
        // Load framework
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

        // Get a Swift function for MRMediaRemoteGetNowPlayingInfo
        guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else { return }
        typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
        let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        
        // Get song info
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { (information) in
            debugLog("🎧 audio info")

            
            if let info = information["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double {
                if (info != 0.0) {
                    // Player is running
                    if let info = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String {
                        artist = info
                    }
                    if let info = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String {
                        name = info
                    }
                    if let info = information["kMRMediaRemoteNowPlayingInfoAlbum"] as? String {
                        album = info
                    }


                    // try to grab image from the keys
                    if information.keys.contains("kMRMediaRemoteNowPlayingInfoArtworkData") {
                        if let _artwork = NSImage(data: information["kMRMediaRemoteNowPlayingInfoArtworkData"] as! Data) {
                            artwork = _artwork
                        }
                    }
                    
                    debugLog("🎧 " + artist + " - " + name + " (" + album + ")" + ((artwork != nil) ? " with artwork " : " without artwork"))
                } else {
                    debugLog("🎧 Player is paused")
                }
            }
            
            // Let everyone who wants to know that we have a new song playing !
            for callback in self.callbacks {
                callback(SongInfo(name: name, artist: artist, album: album, artwork: artwork))
            }
        })
    }
    
    // MARK: - Callbacks
    func addCallback(_ callback:@escaping MusicCallback) {
        debugLog("🎧 Adding music callback")
        callbacks.append(callback)
    }
}
