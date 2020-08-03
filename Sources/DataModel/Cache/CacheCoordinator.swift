//
//  DescriptionCacheCoordinator.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

class CacheCoordinator {
    
    static let shared: CacheCoordinator = .init()
    
    private init() { }
    
    func set<T: Cache>(_ key: String, value: T.Store.Element, in store: T) {
        store.set(key, value: value)
    }
    
    func get<T: Cache>(_ key: String, in store: T) -> T.Store.Element? {
        store.get(key)
    }
    
    func getAndWait<T: Cache>(_ key: String, in store: T, completion: @escaping (T.Store.Element) -> Void) {
        store.getAndWait(key, completion: completion)
    }
    
    func cleanCache<T: Cache>(in store: T) {
        store.clean()
    }
    
    func cleanCallbacks() {
        EntityCache.callbackStore = [:]
        PropertyCache.callbackStore = [:]
        InverseRelationshipCache.callbackStore = [:]
    }
}

// MARK: - Cache Protocol

protocol CacheStore {
    associatedtype Element
    
    static var cache: [AnyHashable: Element] { get set }
    
    static func get(_ key: AnyHashable) -> Element?
    static func set(_ key: AnyHashable, value: Element)
    static func reset()
}

extension CacheStore {
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

// MARK: - Cache type protocol

protocol Cache {
    associatedtype Store: CacheStore
    static var callbackStore: [String: [Callback]] { get set }
}

extension Cache {
    typealias Callback = (Store.Element) -> Void
    
    fileprivate func set(_ key: String, value: Store.Element) {
        Store.set(key, value: value)
        
        guard let callbacks = Self.callbackStore[key] else { return }
        callbacks.forEach{ $0(value) }
        Self.callbackStore[key] = []
    }
    
    fileprivate func get(_ key: String) -> Store.Element? {
        let value = Store.get(key)
        return value
    }
    
    fileprivate func getAndWait(_ key: String, completion: @escaping Callback) {
        let value = Store.get(key)
        let callbackStore = Self.callbackStore
        
        if let value = value {
            completion(value)
        } else {
            let callbacks = callbackStore[key]
            Self.callbackStore[key] = (callbacks ?? []) + [completion]
        }
    }
    
    fileprivate func clean() {
        Store.reset()
        Self.callbackStore = [:]
    }
}

// MARK: - Define all cache types
struct EntityCache: Cache {
    struct Store: Crush.CacheStore {
        @ThreadSafe
        static var cache: [AnyHashable: NSEntityDescription] = [:]
    }

    static var callbackStore: [String : [Callback]] = [:]
}

struct PropertyCache: Cache {
    struct Store: CacheStore {
        @ThreadSafe
        static var cache: [AnyHashable: NSPropertyDescription] = [:]
    }

    static var callbackStore: [String : [Callback]] = [:]
}

struct InverseRelationshipCache: Cache {
    struct Store: CacheStore {
        @ThreadSafe
        static var cache: [AnyHashable: [(AnyKeyPath, NSRelationshipDescription)]] = [:]
    }
    
    static var callbackStore: [String : [Callback]] = [:]
}

struct ObjectModelCache: Cache {
    struct Store: CacheStore {
        @ThreadSafe
        static var cache: [AnyHashable: NSManagedObjectModel] = [:]
    }
    
    static var callbackStore: [String : [Callback]] = [:]
}

struct MigrationCache: Cache {
    struct Store: CacheStore {
        @ThreadSafe
        static var cache: [AnyHashable: Migration] = [:]
    }
    
    static var callbackStore: [String : [Callback]] = [:]
}

internal enum CacheType {
    static var entity: EntityCache { .init() }
    static var property: PropertyCache { .init() }
    static var inverseRelationship: InverseRelationshipCache { .init() }
    static var objectModel: ObjectModelCache { .init() }
    static var migration: MigrationCache { .init() }
}
