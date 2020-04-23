//
//  PrefsAdvanced.swift
//  Aerial
//
//  Created by Guillaume Louel on 23/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

struct PrefsAdvanced {
    // Display margins
    @SimpleStorage(key: "muteSound", defaultValue: true)
    static var muteSound: Bool
}
