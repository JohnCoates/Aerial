//
//  SoundOutputManager+Properties.swift
//  
//
//  Created by Alessio Moiso on 09.03.22.
//
import CoreAudio

public extension Sound.SoundOutputManager {
  /// Get the system default output device.
  ///
  /// You can use this value to interact with the device directly via
  /// other system calls.
  ///
  /// This value will return `nil` if there is currently no device selected in
  /// System Preferences > Sound > Output.
  var defaultOutputDevice: AudioDeviceID? {
    try? retrieveDefaultOutputDevice()
  }
  
  /// Get or set the volume of the default output device.
  ///
  /// Errors will be ignored. If you need to handle errors,
  /// use `readVolume` and `setVolume`.
  ///
  /// The values range between 0 and 1.
  var volume: Float {
    get {
      (try? readVolume()) ?? 0
    }
    set {
      do {
        try setVolume(newValue)
      } catch { }
    }
  }
  
  /// Get or set whether the system default output device is muted or not.
  ///
  /// Errors will be ignored. If you need to handle errors,
  /// use `readMute` and `mute`. Devices that do not support muting
  /// will always return `false`.
  var isMuted: Bool {
    get {
      (try? readMute()) ?? false
    }
    set {
      do {
        try mute(newValue)
      } catch { }
    }
  }
}
