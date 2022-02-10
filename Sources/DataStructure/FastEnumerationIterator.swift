//
//  FastEnumerationIterator.swift
//  
//
//  Created by ezou on 2022/2/10.
//

import Foundation

public struct FastEnumerationIterator<T>: IteratorProtocol {
    internal var iterator: NSFastEnumerationIterator

    internal init(_ iterator: NSFastEnumerationIterator) {
        self.iterator = iterator
    }

    public mutating func next() -> T? {
        guard let next = iterator.next() else { return nil }
        let result: T = next as! T
        return result
    }
}
