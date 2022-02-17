//
//  KeyPath+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation
import CoreData

public protocol Expressible {
    func asExpression() -> Any
    func getHashValue() -> Int
}

extension Expressible {
    func equal(to: Expressible) -> Bool {
        getHashValue() == to.getHashValue()
    }
}

extension AnyKeyPath {
    fileprivate static var lock = os_unfair_lock()
    fileprivate static var propertyNameCache: [ObjectIdentifier: String] = [:]
}

extension PartialKeyPath where Root: Entity {
    var optionalPropertyName: String? {
        let key = ObjectIdentifier(self)
        os_unfair_lock_lock(&Self.lock)
        defer { os_unfair_lock_unlock(&Self.lock) }
        guard let name = Self.propertyNameCache[key] else {
            if let name = (Root()[keyPath: self] as? PropertyProtocol)?.name {
                Self.propertyNameCache[key] = name
                return name
            }
            return nil
        }
        return name
    }
}

extension KeyPath where Root: Entity, Value: PropertyProtocol {
    var propertyName: String {
        let key = ObjectIdentifier(self)
        os_unfair_lock_lock(&Self.lock)
        defer { os_unfair_lock_unlock(&Self.lock) }
        guard let name = Self.propertyNameCache[key] else {
            let name = Root()[keyPath: self].name
            Self.propertyNameCache[key] = name
            return name
        }
        return name
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
