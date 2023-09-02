//
//  LazyMapMutableSet.swift
//
//
//  Created by EZOU on 2023/9/1.
//

import Foundation

final class LazyMapMutableSet<T, U>: NSMutableSet {
    
    static func from(_ mutableSet: NSMutableSet, from: @escaping (T) -> U, to: @escaping (U) -> T) -> LazyMapMutableSet<T, U> {
        let this = LazyMapMutableSet<T, U>()
        this.mutableSet = mutableSet
        this.from = from
        this.to = to
        return this
    }

    var from: ((T) -> U)!
    var to: ((U) -> T)!
    
    var mutableSet: NSMutableSet!
    
    override var count: Int {
        mutableSet.count
    }
    
    override func member(_ object: Any) -> Any? {
        guard let object = object as? U,
              let result = mutableSet.member(to(object)) as? T else { return nil }
        return from(result)
    }
    
    override func objectEnumerator() -> NSEnumerator {
        MapEnumerationIterator<T, U>(iterator: mutableSet.makeIterator(), from: from)
    }
    
    override func add(_ object: Any) {
        guard let object = object as? U else { return }
        mutableSet.add(to(object))
    }
    
    override func remove(_ object: Any) {
        guard let object = object as? U else { return }
        mutableSet.remove(to(object))
    }
    
    override func copy() -> Any {
        LazyMapSet.from(mutableSet.copy() as! NSSet, from: from, to: to)
    }
    
    override func mutableCopy() -> Any {
        LazyMapMutableSet
            .from(mutableSet.mutableCopy() as! NSMutableSet, from: from, to: to)
    }
}
