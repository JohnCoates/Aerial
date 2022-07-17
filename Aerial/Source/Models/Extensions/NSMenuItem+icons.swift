//
//  NSMenuItem+icons.swift
//  Aerial
//
//  Created by Guillaume Louel on 30/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

extension NSMenuItem {
    func setIcons(_ named: String) {
        self.image = Aerial.helper.getMiniSymbol(named)
        self.image?.isTemplate = true
    }
}
