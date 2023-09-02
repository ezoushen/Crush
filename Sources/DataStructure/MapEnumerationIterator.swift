//
//  MapEnumerationIterator.swift
//
//
//  Created by EZOU on 2023/9/1.
//

import Foundation

class MapEnumerationIterator<T, U>: NSEnumerator {
    var iterator: NSFastEnumerationIterator
    let from: (T) -> U
    
    init(iterator: NSFastEnumerationIterator, from: @escaping (T) -> U) {
        self.iterator = iterator
        self.from = from
    }
    
    override func nextObject() -> Any? {
        guard let value = iterator.next() as? T else { return nil }
        return from(value)
    }
}
