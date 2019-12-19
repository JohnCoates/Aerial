//
//  Brightness.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation

struct Brightness {

    static func get() -> Float {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        let pointer = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, pointer)
        let brightness = pointer.pointee
        IOObjectRelease(service)
        return brightness
    }

    static func set(level: Float) {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, level)
        IOObjectRelease(service)
    }

}
