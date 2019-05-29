//
//  SeededGenerator.swift
//  Aerial
//
//  Created by Guillaume Louel on 21/05/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import GameplayKit

@available(OSX 10.11, *)
class SeededGenerator: RandomNumberGenerator {
    let seed: UInt64
    private let generator: GKMersenneTwisterRandomSource

    convenience init() {
        self.init(seed: 0)
    }

    init(seed: UInt64) {
        self.seed = seed
        generator = GKMersenneTwisterRandomSource(seed: seed)
    }

    func next<T>(upperBound: T) -> T where T: FixedWidthInteger, T: UnsignedInteger {
        return T(abs(generator.nextInt(upperBound: Int(upperBound))))
    }

    func next<T>() -> T where T: FixedWidthInteger, T: UnsignedInteger {
        return T(abs(generator.nextInt()))
    }
}
