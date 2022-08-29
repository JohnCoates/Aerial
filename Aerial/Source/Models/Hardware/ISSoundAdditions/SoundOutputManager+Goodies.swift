//
//  File.swift
//  
//
//  Created by Alessio Moiso on 09.03.22.
//

public extension Sound.SoundOutputManager {
  /// Increase the volume of the default output device
  /// by the given amount.
  ///
  /// Errors will be ignored.
  ///
  /// The values range between 0 and 1. If the increase results
  /// in a value outside of the bounds, it will be normalized to the closest
  /// value in the bounds.
  func increaseVolume(by value: Float, autoMuteUnmute: Bool = false, muteThreshold: Float = 0.005) {
    setVolume(volume+value, autoMuteUnmute: autoMuteUnmute, muteThreshold: muteThreshold)
  }
  
  /// Decrease the volume of the default output device
  /// by the given amount.
  ///
  /// Errors will be ignored.
  ///
  /// The values range between 0 and 1. If the decrease results
  /// in a value outside of the bounds, it will be normalized to the closest
  /// value in the bounds.
  func decreaseVolume(by value: Float, autoMuteUnmute: Bool = false, muteThreshold: Float = 0.005) {
    setVolume(volume-value, autoMuteUnmute: autoMuteUnmute, muteThreshold: muteThreshold)
  }
  
  /// Set the volume of the default output device and,
  /// if lower or higher then `muteThreshold` also toggles the mute property.
  ///
  /// - warning: This function will unmute a muted device, if the volume is greater
  /// then `muteThreshold`. Please, make sure that the user is aware of this and always
  /// respect the Do Not Disturb modes and other system settings.
  ///
  /// - parameters:
  ///   - newValue: The volume.
  ///   - autoMuteUnmute: If `true`, will use the `muteThreshold` to determine whether the device
  ///   should also be muted or unmuted.
  ///   - muteThreshold: Defines the threshold that should cause an automatic mute for all values below it.
  func setVolume(_ newValue: Float, autoMuteUnmute: Bool, muteThreshold: Float = 0.005) {
    volume = newValue
    guard autoMuteUnmute else { return }
    isMuted = newValue <= muteThreshold
  }
}
