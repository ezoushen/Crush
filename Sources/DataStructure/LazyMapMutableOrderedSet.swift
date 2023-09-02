//
//  LazyMapMutableOrderedSet.swift
//
//
//  Created by EZOU on 2023/9/1.
//

import Foundation

final class LazyMapMutableOrderedSet<T, U>: NSMutableOrderedSet {
    
    static func from(_ mutableOrderedSet: NSMutableOrderedSet, from: @escaping (T) -> U, to: @escaping (U) -> T) -> LazyMapMutableOrderedSet<T, U> {
        let this = LazyMapMutableOrderedSet<T, U>()
        this.mutableOrderedSet = mutableOrderedSet
        this.from = from
        this.to = to
        return this
    }
    
    var from: ((T) -> U)!
    var to: ((U) -> T)!
    
    var mutableOrderedSet: NSMutableOrderedSet!
    
    override var count: Int {
        mutableOrderedSet.count
    }
    
    override func contains(_ object: Any) -> Bool {
        guard let object = object as? U else { return false }
        return mutableOrderedSet.contains(object)
    }
    
    override func objectEnumerator() -> NSEnumerator {
        MapEnumerationIterator<T, U>(iterator: mutableOrderedSet.makeIterator(), from: from)
    }
    
    override func object(at idx: Int) -> Any {
        let object = mutableOrderedSet.object(at: idx) as! T
        return from(object)
    }
    
    override func add(_ object: Any) {
        guard let object = object as? U else { return }
        mutableOrderedSet.add(to(object))
    }
    
    override func remove(_ object: Any) {
        guard let object = object as? U else { return }
        mutableOrderedSet.remove(to(object))
    }
    
    override func insert(_ object: Any, at idx: Int) {
        guard let object = object as? U else { return }
        mutableOrderedSet.insert(to(object), at: idx)
    }
    
    override func removeObject(at idx: Int) {
        mutableOrderedSet.removeObject(at: idx)
    }
    
    override func copy() -> Any {
        LazyMapOrderedSet.from(mutableOrderedSet.copy() as! NSOrderedSet, from: from, to: to)
    }
    
    override func mutableCopy() -> Any {
        LazyMapMutableOrderedSet
            .from(mutableOrderedSet.mutableCopy() as! NSMutableOrderedSet, from: from, to: to)
    }
}
