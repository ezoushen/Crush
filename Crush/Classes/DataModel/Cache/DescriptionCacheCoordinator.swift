//
//  DescriptionCacheCoordinator.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

class DescriptionCacheCoordinator {
    
    static let shared: DescriptionCacheCoordinator = .init()
    
    private init() { }
    
    func setDescription<T: DescriptionCacheType>(_ key: String, value: T.Cache.Element, type: T.Type) {
        let cache = type.getCache()
        cache.set(key, value: value)
        
        guard let callbacks = type.callbackStore[key] else { return }
        callbacks.forEach{ ($0 as! (T.Cache.Element) -> Void)(value) }
        type.callbackStore[key] = []
    }
    
    func getDescription<T: DescriptionCacheType>(_ key: String, type: T.Type) -> T.Cache.Element? {
        let cache = type.getCache()
        let value = cache.get(key)
        return value
    }
    
    func getAndWaitDescription<T: DescriptionCacheType>(_ key: String, type: T.Type, completion: @escaping (T.Cache.Element) -> Void) {
        let cache = type.getCache()
        let value = cache.get(key)
        let callbackStore = type.callbackStore
        
        if let value = value {
            completion(value)
        } else {
            let callbacks = callbackStore[key]
            type.callbackStore[key] = (callbacks ?? []) + [completion as Any]
        }
    }
    
    func cleanCache<T: DescriptionCacheType>(type: T.Type) {
        let cache = type.getCache()
        cache.reset()
    }
}
