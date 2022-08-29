//
//  SoundOutputManager.swift
//
//
//  Created by Alessio Moiso on 08.03.22.
//

/// Entry point to access and modify the system sound settings, such
/// muting/unmuting and changing the volume.
///
/// # Overview
/// This class cannot be instantiated, but you can interact with its `output` property directly.
/// You can use the shared instance to change the output volume as well as
/// mute and unmute.
public enum Sound {
  static let output = SoundOutputManager()
}
