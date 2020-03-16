//
//  DescriptionCache.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// NMARK: - Cache Protocol

protocol CacheProtocol {
    associatedtype Element
    
    static var cache: [AnyHashable: Element] { get set }
    
    static func get(_ key: AnyHashable) -> Element?
    static func set(_ key: AnyHashable, value: Element)
    static func reset()
}

extension CacheProtocol {
    static func get(_ key: AnyHashable) -> Element? {
        return cache[key]
    }
    
    static func set(_ key: AnyHashable, value: Element) {
        cache[key] = value
    }
    
    static func reset() {
        cache = [:]
    }
}

// MARK: - Storage of each cache type

struct EntityDescriptionCache: CacheProtocol {
    @ThreadSafe
    static var cache: [AnyHashable: NSEntityDescription] = [:]
}

struct PropertyDescriptionCache: CacheProtocol {
    @ThreadSafe
    static var cache: [AnyHashable: NSPropertyDescription] = [:]
}

struct InverRelationshipCache: CacheProtocol {
    @ThreadSafe
    static var cache: [AnyHashable: [(AnyKeyPath, NSRelationshipDescription)]] = [:]
}

// MARK: - Cache type protocol

protocol DescriptionCacheType {
    associatedtype Cache: CacheProtocol
    static var callbackStore: [String: [Any]] { get set }
    static func getCache() -> Cache.Type
}

extension DescriptionCacheType {
    static func getCache() -> Cache.Type {
        return Self.Cache.self
    }
}

// MARK: - Define all cache types

struct EntityCacheType: DescriptionCacheType {
    typealias Cache = EntityDescriptionCache
    static var callbackStore: [String: [Any]] = [:]
}

struct PropertyCacheType: DescriptionCacheType {
    typealias Cache = PropertyDescriptionCache
    static var callbackStore: [String: [Any]] = [:]
}

struct InverRelationshipCacheType: DescriptionCacheType {
    typealias Cache = InverRelationshipCache
    static var callbackStore: [String : [Any]] = [:]
}
