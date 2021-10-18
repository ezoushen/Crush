//
//  PrimitiveAttribute+Enumerator.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

public protocol Enumerator:
    RawRepresentable,
    FieldAttribute,
    PredicateEquatable,
    Hashable
where
    RawValue: FieldAttribute & PredicateEquatable & Hashable { }

extension Enumerator {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func convert(value: RawValue?) -> Self? {
        guard let value = value else { return nil }
        return Self.init(rawValue: value)
    }

    public static func convert(value: Self?) -> RawValue? {
        value?.rawValue
    }

    public static var nativeType: NSAttributeType { RawValue.nativeType }
    public var predicateValue: NSObject { self.rawValue.predicateValue }
}
