//
//  Cahces.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - Cache type protocol

class Cache<Key: Hashable, Element> {
    var cache: [Key: Element] = [:]
    var callbackStore: [Key: [Callback]] = [:]

    typealias Callback = (Element) -> Void

    func set(_ key: Key, value: Element) {
        cache[key] = value
        guard let callbacks = callbackStore.removeValue(forKey: key) else { return }
        callbacks.forEach{ $0(value) }
    }

    func get(_ key: Key) -> Element? {
        cache[key]
    }

    func get(_ key: Key, completion: @escaping Callback) {
        let value = get(key)

        if let value = value {
            completion(value)
        } else {
            let callbacks = callbackStore[key]
            callbackStore[key] = (callbacks ?? []) + [completion]
        }
    }

    func clean() {
        cache = [:]
        callbackStore = [:]
    }
}

class ThreadSafeCache<Key: Hashable, Element>: Cache<Key, Element> {
    private let lock = UnfairLock()

    override func set(_ key: Key, value: Element) {
        lock.lock()
        defer { lock.unlock() }
        super.set(key, value: value)
    }

    override func get(_ key: Key) -> Element? {
        lock.lock()
        defer { lock.unlock() }
        return super.get(key)
    }

    override func get(_ key: Key, completion: @escaping Cache<Key, Element>.Callback) {
        lock.lock()
        defer { lock.unlock() }
        super.get(key, completion: completion)
    }

    override func clean() {
        lock.lock()
        defer { lock.unlock() }
        super.clean()
    }
}

// MARK: - Define all caches

typealias EntityCache = Cache<String, NSEntityDescription>
typealias ManagedObjectModelCache = ThreadSafeCache<Int, NSManagedObjectModel>

internal enum Caches {
    static let managedObjectModel: ManagedObjectModelCache = .init()
}
