//
//  EnumerableAttributeType.swift
//
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

public protocol EnumerableAttributeType<RawAttributeType>:
    RawRepresentable,
    AttributeType,
    PredicateEquatable,
    PredicateComparable,
    Hashable
where
    RawValue: PredicateEquatable & PredicateComparable & Hashable,
    ManagedValue == RawAttributeType.ManagedValue,
    RuntimeValue == Self?,
    PredicateValue == RawAttributeType.PredicateValue,
    PredicateType == RawValue.PredicateType
{
    associatedtype RawAttributeType: PrimitiveAttributeType
    associatedtype PredicateValue = RawValue
    associatedtype ManagedValue = RawValue?
    associatedtype RuntimeValue = Self?
}

extension EnumerableAttributeType {
    @inlinable public static var defaultRuntimeValue: RuntimeValue { nil }
    @inlinable public static var defaultManagedValue: ManagedValue { nil }

    public static func convert(managedValue: RawValue?) -> Self? {
        guard let value = managedValue else { return nil }
        return Self.init(rawValue: value)
    }

    @inlinable public static func convert(runtimeValue: Self?) -> RawValue? {
        runtimeValue?.rawValue
    }

    @inlinable public static var nativeType: NSAttributeType { RawAttributeType.nativeType }
    @inlinable public var predicateValue: PredicateType { self.rawValue.predicateValue }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
