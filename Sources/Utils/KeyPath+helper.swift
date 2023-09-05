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
    fileprivate static var lock = UnfairLock()
    fileprivate static var propertyNameCache: [AnyHashable: String] = [:]

    fileprivate var propertyNameCache: [AnyHashable: String] {
        get { Self.propertyNameCache }
        set { Self.propertyNameCache = newValue }
    }
}

extension PartialKeyPath where Root: Entity {
    var optionalPropertyName: String? {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        return propertyNameCache[ObjectIdentifier(self)] ?? {
            let name = (Root()[keyPath: self] as? (any Property))?.name
            defer { if let name = name { propertyNameCache[ObjectIdentifier(self)] = name } }
            return name
        }()
    }
}

extension KeyPath where Root: Entity, Value: Property {
    var propertyName: String {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        let key = AnyHashable(self)
        return propertyNameCache[key] ?? {
            let name = Root()[keyPath: self].name
            defer { propertyNameCache[key] = name }
            return name
        }()
    }
}

extension KeyPath: Expressible where Root: Entity, Value: Property {
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
        Property: Crush.Property,
        Value.Destination == Target
    {
        "\(propertyName).\(keyPath.propertyName)"
    }
}
