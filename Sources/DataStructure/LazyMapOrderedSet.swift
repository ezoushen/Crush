//
//  File.swift
//  
//
//  Created by EZOU on 2023/9/1.
//

import Foundation

final class LazyMapOrderedSet<T, U>: NSOrderedSet {
    
    static func from(_ orderedSet: NSOrderedSet, from: @escaping (T) -> U, to: @escaping (U) -> T) -> LazyMapOrderedSet<T, U> {
        let this = LazyMapOrderedSet<T, U>()
        this.orderedSet = orderedSet
        this.from = from
        this.to = to
        return this
    }

    var from: ((T) -> U)!
    var to: ((U) -> T)!
    
    var orderedSet: NSOrderedSet!
    
    override var count: Int {
        orderedSet.count
    }
    
    override func contains(_ object: Any) -> Bool {
        guard let object = object as? U else { return false }
        return orderedSet.contains(object)
    }
    
    override func objectEnumerator() -> NSEnumerator {
        MapEnumerationIterator<T, U>(iterator: orderedSet.makeIterator(), from: from)
    }
    
    override func object(at idx: Int) -> Any {
        let object = orderedSet.object(at: idx) as! T
        return from(object)
    }
    
    override func copy() -> Any {
        LazyMapOrderedSet.from(orderedSet.copy() as! NSOrderedSet, from: from, to: to)
    }
    
    override func mutableCopy() -> Any {
        LazyMapMutableOrderedSet
            .from(orderedSet.mutableCopy() as! NSMutableOrderedSet, from: from, to: to)
    }
}
