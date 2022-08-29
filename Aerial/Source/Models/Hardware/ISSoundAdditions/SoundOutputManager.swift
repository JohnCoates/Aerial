//
//  SoundOutputManager.swift
//  
//
//  Created by Alessio Moiso on 08.03.22.
//

import CoreAudio
import AudioToolbox
import Cocoa

extension Sound {
  /// Mute, unmute and change the volume of the system default output device.
  ///
  /// # Overview
  /// You can interact with this class in two ways:
  /// - you can interact with its properties, meaning that all changes
  /// will be applied immediately and errors will be hidden.
  /// - you can call its methods and handle errors manually.
  public final class SoundOutputManager {
    /// All the possible errors that could occur while interacting
    /// with the default output device.
    enum Errors: Error {
            /// The system couldn't complete the requested operation and
            /// returned the given status.
      case  operationFailed(OSStatus)
            /// The current default output device doesn't support the requested property.
      case  unsupportedProperty
            /// The current default output device doesn't allow changing the requested property.
      case  immutableProperty
            /// There is no default output device.
      case  noDevice
    }
    
    internal init() { }
    
    /// Get the system default output device.
    ///
    /// You can use this value to interact with the device directly
    /// via other system calls.
    ///
    /// - throws: `Errors.operationFailed` if the system fails to return the default output device.
    /// - returns: the default device ID or `nil` if none is set.
    public func retrieveDefaultOutputDevice() throws -> AudioDeviceID? {
      var result = kAudioObjectUnknown
      var size = UInt32(MemoryLayout<AudioDeviceID>.size)
      var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
      )
      
      // Ensure that a default device exists.
      guard AudioObjectHasProperty(AudioObjectID(kAudioObjectSystemObject), &address) else { return nil }
      
      // Attempt to get the default output device.
      let error = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &result)
      guard error == noErr else {
        throw Errors.operationFailed(error)
      }
      
      if result == kAudioObjectUnknown {
        throw Errors.noDevice
      }
      
      return result
    }
    
    /// Get the volume of the system default output device.
    ///
    /// - throws: `Errors.noDevice` if the system doesn't have a default output device; `Errors.unsupportedProperty` if the current device doesn't have a volume property; `Errors.operationFailed` if the system is unable to read the property value.
    /// - returns: The current volume in a range between 0 and 1.
    public func readVolume() throws -> Float {
      guard let deviceID = try retrieveDefaultOutputDevice() else {
        throw Errors.noDevice
      }
      
      var size = UInt32(MemoryLayout<Float32>.size)
      var volume: Float = 0
      var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
      )
      
      // Ensure the device has a volume property.
      guard AudioObjectHasProperty(deviceID, &address) else {
        throw Errors.unsupportedProperty
      }
      
      let error = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
      guard error == noErr else {
        throw Errors.operationFailed(error)
      }
      
      return min(max(0, volume), 1)
    }
    
    /// Set the volume of the system default output device.
    ///
    /// - parameter newValue: The volume to set in a range between 0 and 1.
    /// - throws: `Erors.noDevice` if the system doesn't have a default output device; `Errors.unsupportedProperty` or `Errors.immutableProperty` if the output device doesn't support setting or doesn't currently allow changes to its volume; `Errors.operationFailed` if the system is unable to apply the volume change.
    public func setVolume(_ newValue: Float) throws {
      guard let deviceID = try retrieveDefaultOutputDevice() else {
        throw Errors.noDevice
      }
      
      var normalizedValue = min(max(0, newValue), 1)
      var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
      )
      
      // Ensure the device has a volume property.
      guard AudioObjectHasProperty(deviceID, &address) else {
        throw Errors.unsupportedProperty
      }
      
      var canChangeVolume = DarwinBoolean(true)
      let size = UInt32(MemoryLayout<Float>.size(ofValue: normalizedValue))
      let isSettableError = AudioObjectIsPropertySettable(deviceID, &address, &canChangeVolume)
      
      // Ensure the volume property is editable.
      guard isSettableError == noErr else {
        throw Errors.operationFailed(isSettableError)
      }
      guard canChangeVolume.boolValue else {
        throw Errors.immutableProperty
      }
      
      let error = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &normalizedValue)
      
      if error != noErr {
        throw Errors.operationFailed(error)
      }
    }
    
    /// Get whether the system default output device is currently muted or not.
    ///
    /// - throws: `Errors.noDevice` if the system doesn't have a default output device;
    /// `Errors.unsupportedProperty` if the current device doesn't have a mute property;
    /// `Errors.operationFailed` if the system is unable to read the property value.
    /// - returns: Whether the device is muted or not.
    public func readMute() throws -> Bool {
      guard let deviceID = try retrieveDefaultOutputDevice() else {
        throw Errors.noDevice
      }
      
      var isMuted: UInt32 = 0
      var size = UInt32(MemoryLayout<UInt32>.size(ofValue: isMuted))
      var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyMute,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
      )
      
      // Ensure the device supports the option to be muted.
      guard AudioObjectHasProperty(deviceID, &address) else {
        throw Errors.unsupportedProperty
      }
      
      let error = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &isMuted)
      
      guard error == noErr else {
        throw Errors.operationFailed(error)
      }
      
      return isMuted == 1
    }
    
    /// Mute or unmute the system default output device.
    ///
    /// - parameter isMuted: Mute or unmute.
    /// - throws: `Errors.noDevice` if the system doesn't have a default output device;
    /// `Errors.unsupportedProperty` or `Errors.immutableProperty` if the output device doesn't
    /// support setting or doesn't currently allow changes to its mute property; `Errors.operationFailed`
    /// if the system is unable to apply the change.
    public func mute(_ isMuted: Bool) throws {
      guard let deviceID = try retrieveDefaultOutputDevice() else {
        throw Errors.noDevice
      }
      
      var normalizedValue: UInt = isMuted ? 1 : 0
      var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyMute,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
      )
      
      // Ensure the device supports the option to be muted.
      guard AudioObjectHasProperty(deviceID, &address) else {
        throw Errors.unsupportedProperty
      }
      
      var canMute = DarwinBoolean(true)
      let size = UInt32(MemoryLayout<UInt>.size(ofValue: normalizedValue))
      let isSettableError = AudioObjectIsPropertySettable(deviceID, &address, &canMute)
      
      // Ensure that the mute property is editable.
      guard isSettableError == noErr, canMute.boolValue else {
        throw Errors.immutableProperty
      }
      
      let error = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &normalizedValue)
      
      if error != noErr {
        throw Errors.operationFailed(error)
      }
    }
  }
}
