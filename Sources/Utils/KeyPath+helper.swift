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
}

private var propertyNameCache: NSCache<AnyKeyPath, NSString> = .init()

extension PartialKeyPath: CustomStringConvertible where Root: Entity {
    var optionalPropertyName: String? {
        guard let name = propertyNameCache.object(forKey: self) else {
            if let name = (Root.init()[keyPath: self] as? PropertyProtocol)?.name {
                propertyNameCache.setObject(name as NSString, forKey: self)
                return name
            }
            return nil
        }
        return name as String
    }

    public var description: String {
        optionalPropertyName ?? "\(self)"
    }
}

extension KeyPath where Root: Entity, Value: PropertyProtocol {
    var propertyName: String {
        guard let name = propertyNameCache.object(forKey: self) else {
            let name = Root.init()[keyPath: self].name
            propertyNameCache.setObject(name as NSString, forKey: self)
            return name
        }
        return name as String
    }

    public static func == (lhs: KeyPath, rhs: String) -> Bool {
        lhs.propertyName == rhs
    }

    public static func == (lhs: String, rhs: KeyPath) -> Bool {
        lhs == rhs.propertyName
    }
}


extension KeyPath: Expressible where Root: Entity, Value: PropertyProtocol {
    public func asExpression() -> Any {
        propertyName
    }
}
