//
//  EnumerableAttributeType.swift
//
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

public protocol EnumerableAttributeType:
    RawRepresentable,
    AttributeType,
    PredicateEquatable,
    PredicateComparable,
    Hashable
where
    RawValue: AttributeType & PredicateEquatable & PredicateComparable & Hashable { }

extension RawRepresentable where Self: AttributeType {
    public typealias ManagedValue = RawValue?
    public typealias RuntimeValue = Self?
}

extension EnumerableAttributeType {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func convert(managedValue: RawValue?) -> Self? {
        guard let value = managedValue else { return nil }
        return Self.init(rawValue: value)
    }

    public static func convert(runtimeValue: Self?) -> RawValue? {
        runtimeValue?.rawValue
    }

    public static var nativeType: NSAttributeType { RawValue.nativeType }
    public var predicateValue: NSObject { self.rawValue.predicateValue }
}
