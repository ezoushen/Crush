//
//  Cahces.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - Cache Protocol

protocol CacheStore {
    associatedtype Element
    associatedtype Key: Hashable = AnyHashable
    
    static var cache: [Key: Element] { get set }
    
    static func get(_ key: Key) -> Element?
    static func set(_ key: Key, value: Element)
    static func reset()
}

extension CacheStore {
    static func get(_ key: Key) -> Element? {
        return cache[key]
    }
    
    static func set(_ key: Key, value: Element) {
        cache[key] = value
    }
    
    static func reset() {
        cache = [:]
    }
}

// MARK: - Cache type protocol

protocol Cache {
    associatedtype Store: CacheStore
    static var callbackStore: [Store.Key: [Callback]] { get set }
}

extension Cache {
    typealias Callback = (Store.Element) -> Void
    
    func set(_ key: Store.Key, value: Store.Element) {
        Store.set(key, value: value)
        
        guard let callbacks = Self.callbackStore[key] else { return }
        callbacks.forEach{ $0(value) }
        Self.callbackStore[key] = []
    }
    
    func get(_ key: Store.Key) -> Store.Element? {
        let value = Store.get(key)
        return value
    }
    
    func getAndWait(_ key: Store.Key, completion: @escaping Callback) {
        let value = Store.get(key)
        let callbackStore = Self.callbackStore
        
        if let value = value {
            completion(value)
        } else {
            let callbacks = callbackStore[key]
            Self.callbackStore[key] = (callbacks ?? []) + [completion]
        }
    }
    
    func clean() {
        Store.reset()
        Self.callbackStore = [:]
    }
}

// MARK: - Define all caches

struct EntityCache: Cache {
    struct Store: Crush.CacheStore {
        static var cache: [String: NSEntityDescription] = [:]
    }

    static var callbackStore: [String : [Callback]] = [:]
}

struct ManagedObjectModelcache: Cache {
    struct Store: CacheStore {
        static var cache: [Int: NSManagedObjectModel] = [:]
    }

    static var callbackStore: [Int : [Callback]] = [:]
}

internal enum Caches {
    static let entity: EntityCache = .init()
    static let managedObjectModel: ManagedObjectModelcache = .init()
}
