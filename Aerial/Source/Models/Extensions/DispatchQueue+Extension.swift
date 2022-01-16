//
//  DispatchQueue+Extension.swift
//  Aerial
//
//  Created by Guillaume Louel on 28/12/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//

import Foundation

extension DispatchQueue {

    static func background(delay: Double = 0.0, background: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }

}
