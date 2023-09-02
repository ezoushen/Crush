//
//  LazyMapSet.swift
//  
//
//  Created by EZOU on 2023/9/1.
//

import Foundation

final class LazyMapSet<T, U>: NSSet {
    
    static func from(_ nsset: NSSet, from: @escaping (T) -> U, to: @escaping (U) -> T) -> LazyMapSet<T, U> {
        let this = LazyMapSet<T, U>()
        this.nsset = nsset
        this.from = from
        this.to = to
        return this
    }
    
    var from: ((T) -> U)!
    var to: ((U) -> T)!
    
    var nsset: NSSet!
    
    override var count: Int {
        nsset.count
    }
    
    override func member(_ object: Any) -> Any? {
        guard let object = object as? U,
              let result = nsset.member(to(object)) as? T else { return nil }
        return from(result)
    }
    
    override func objectEnumerator() -> NSEnumerator {
        MapEnumerationIterator<T, U>(iterator: nsset.makeIterator(), from: from)
    }
    
    override func copy() -> Any {
        LazyMapSet.from(nsset.copy() as! NSSet, from: from, to: to)
    }
    
    override func mutableCopy() -> Any {
        LazyMapMutableSet.from(nsset.mutableCopy() as! NSMutableSet, from: from, to: to)
    }
}
