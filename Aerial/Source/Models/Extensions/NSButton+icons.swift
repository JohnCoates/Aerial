//
//  NSButton+icons.swift
//  Aerial
//
//  Created by Guillaume Louel on 01/08/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

import Cocoa

extension NSButton {
    func setIcons(_ named: String) {
        self.image = Aerial.getMiniSymbol(named)
        self.image?.isTemplate = true
    }

    func setLargeIcon(_ named: String) {
        self.image = Aerial.getSymbol(named)!.tinting(with: .secondaryLabelColor)
    }
}
