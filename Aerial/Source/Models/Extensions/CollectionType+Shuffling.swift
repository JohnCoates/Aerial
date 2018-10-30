//
//  CollectionType+Shuffling.swift
//  Aerial
//
import Foundation

// shuffling thanks to Nate Cook http://stackoverflow.com/questions/24026510/how-do-i-shuffle-an-array-in-swift
extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let theCount = count
        guard theCount > 1 else { return }

        for (unshuffledCount, firstUnshuffled) in zip(stride(from: theCount, to: 1, by: -1), indices) {
            let digit: Int = numericCast(Int.random(in: 0..<unshuffledCount))
            guard digit != 0 else { continue }
            let idx = index(firstUnshuffled, offsetBy: digit)
            self.swapAt(firstUnshuffled, idx)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
