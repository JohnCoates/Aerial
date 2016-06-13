//
//  CollectionType+Shuffling.swift
//  Aerial
//


import Foundation

// shuffling thanks to Nate Cook http://stackoverflow.com/questions/24026510/how-do-i-shuffle-an-array-in-swift

extension Collection {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Iterator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollection where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<self.endIndex - 1 {
            let j = Int(arc4random_uniform(UInt32(self.endIndex - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}
