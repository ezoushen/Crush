//
//  KeyPath+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation
import CoreData

extension AnyKeyPath {
    fileprivate static var mutex: pthread_mutex_t = {
        var lock = pthread_mutex_t()
        pthread_mutex_init(&lock, nil)
        return lock
    }()
    
    fileprivate static var propertyNameCache: [AnyKeyPath: String] = [:]

    fileprivate var propertyNameCache: [AnyKeyPath: String] {
        get { Self.propertyNameCache }
        set { Self.propertyNameCache = newValue }
    }
}

extension PartialKeyPath where Root: Entity {
    var optionalPropertyName: String? {
        pthread_mutex_lock(&Self.mutex)
        defer { pthread_mutex_unlock(&Self.mutex) }
        return propertyNameCache[self] ?? {
            let name = (Root()[keyPath: self] as? PropertyProtocol)?.name
            defer { if let name = name { propertyNameCache[self] = name } }
            return name
        }()
    }
}

extension KeyPath where Root: Entity, Value: PropertyProtocol {
    var propertyName: String {
        pthread_mutex_lock(&Self.mutex)
        defer { pthread_mutex_unlock(&Self.mutex) }
        return propertyNameCache[self] ?? {
            let name = Root()[keyPath: self].name
            defer { propertyNameCache[self] = name }
            return name
        }()
    }
}

extension KeyPath: Expressible where Root: Entity, Value: PropertyProtocol {
    public func getHashValue() -> Int {
        propertyName.hashValue
    }

    public func asExpression() -> Any {
        propertyName
    }
}

extension KeyPath where Root: Entity, Value: RelationshipProtocol {
    public func extend<Target, Property>(
        _ keyPath: KeyPath<Target, Property>) -> String
    where
        Property: PropertyProtocol,
        Value.Destination == Target
    {
        "\(propertyName).\(keyPath.propertyName)"
    }
}
