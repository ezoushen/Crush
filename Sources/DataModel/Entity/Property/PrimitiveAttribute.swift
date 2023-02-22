//
//  PrimitiveAttribute.swift
//  Crush
//
//  Created by ezou on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData
import Foundation

public protocol AnyFieldConvertible {
    func managedToRuntime(_ managedValue: Any?) -> Any?
    func runtimeToManaged(_ runtimeValue: Any?) -> Any?
}

public protocol FieldConvertible: AnyFieldConvertible {
    associatedtype RuntimeObjectValue
    associatedtype ManagedObjectValue
    
    static func convert(value: ManagedObjectValue) -> RuntimeObjectValue
    static func convert(value: RuntimeObjectValue) -> ManagedObjectValue

    static var defaultRuntimeValue: RuntimeObjectValue { get }
    static var defaultManagedValue: ManagedObjectValue { get }
}

extension FieldConvertible where RuntimeObjectValue: OptionalProtocol {
    @inlinable
    public static var defaultRuntimeValue: RuntimeObjectValue {
        return RuntimeObjectValue.null
    }
}

extension FieldConvertible where ManagedObjectValue: OptionalProtocol {
    @inlinable
    public static var defaultManagedValue: ManagedObjectValue {
        return ManagedObjectValue.null
    }
}

extension FieldConvertible where RuntimeObjectValue: Collection & ExpressibleByArrayLiteral {
    @inlinable
    public static var defaultRuntimeValue: RuntimeObjectValue {
        return []
    }
}

extension FieldConvertible where ManagedObjectValue: Collection & ExpressibleByArrayLiteral {
    @inlinable
    public static var defaultManagedValue: ManagedObjectValue {
        return []
    }
}

extension FieldConvertible where ManagedObjectValue == NSMutableSet {
    public static var defaultManagedValue: NSMutableSet {
        NSMutableSet()
    }
}

extension FieldConvertible where ManagedObjectValue == NSMutableOrderedSet {
    public static var defaultManagedValue: NSMutableOrderedSet {
        NSMutableOrderedSet()
    }
}

extension FieldConvertible {
    public func managedToRuntime(_ managedValue: Any?) -> Any? {
        guard let managedValue = managedValue as? ManagedObjectValue else {
            return nil
        }
        return Self.convert(value: managedValue)
    }

    public func runtimeToManaged(_ runtimeValue: Any?) -> Any? {
        guard let runtimeValue = runtimeValue as? RuntimeObjectValue else {
            return nil
        }
        return Self.convert(value: runtimeValue)
    }
}

public protocol PredicateExpressibleByString { }

public protocol PredicateComputable { }

public protocol PredicateEquatable {
    var predicateValue: NSObject { get }
}

public protocol PredicateComparable: PredicateEquatable { }

public protocol FieldAttributeProtocol {
    static var nativeType: NSAttributeType { get }
}

public protocol FieldAttribute: FieldAttributeProtocol, FieldConvertible
where ManagedObjectValue: OptionalProtocol {
    associatedtype RuntimeObjectValue: OptionalProtocol = Self?
}

public protocol PrimitiveAttribute: FieldAttribute {
    associatedtype ManagedObjectValue: OptionalProtocol = Self?
}

extension FieldAttribute
where
    RuntimeObjectValue == Self?,
    RuntimeObjectValue == ManagedObjectValue
{
    @inlinable
    public static func convert(value: Self?) -> Self? { value }
}

public typealias PredicateComparableAttribute = PrimitiveAttribute & PredicateComparable
public typealias PredicateEquatableAttribute = PrimitiveAttribute & PredicateEquatable

public typealias IntegerAttribute = PredicateComparableAttribute & PredicateExpressibleByString & PredicateComputable

extension Int: IntegerAttribute {
    public static var nativeType: NSAttributeType {
#if (arch(x86_64) || arch(arm64))
        return .integer64AttributeType
#else
        return .integer32AttributeType
#endif
    }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int64: IntegerAttribute {
    public static var nativeType: NSAttributeType { .integer64AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int32: IntegerAttribute {
    public static var nativeType: NSAttributeType { .integer32AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int16: IntegerAttribute {
    public static var nativeType: NSAttributeType { .integer16AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension NSDecimalNumber: PredicateComparableAttribute, PredicateExpressibleByString, PredicateComputable {
    public typealias RuntimeObjectValue = NSDecimalNumber?
    public typealias ManagedObjectValue = NSDecimalNumber?

    public static var nativeType: NSAttributeType { .decimalAttributeType }
    public var predicateValue: NSObject { self }
}

extension Double: PredicateComparableAttribute, PredicateExpressibleByString, PredicateComputable {
    public static var nativeType: NSAttributeType { .doubleAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Float: PredicateComparableAttribute, PredicateExpressibleByString, PredicateComputable {
    public static var nativeType: NSAttributeType { .floatAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension String: PrimitiveAttribute, PredicateComparable {
    public static var nativeType: NSAttributeType { .stringAttributeType }
    public var predicateValue: NSObject { NSString(string: self) }
}

extension Bool: PredicateEquatableAttribute, PredicateExpressibleByString {
    public static var nativeType: NSAttributeType { .booleanAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Date: PredicateComparableAttribute, PredicateExpressibleByString {
    public static var nativeType: NSAttributeType { .dateAttributeType }
    public var predicateValue: NSObject { self as NSDate }
}

extension Data: PrimitiveAttribute, PredicateEquatable {
    public static var nativeType: NSAttributeType { .binaryDataAttributeType }
    public var predicateValue: NSObject { self as NSData }
}

extension NSNull: FieldConvertible {
    public typealias RuntimeObjectValue = NSNull
    public typealias ManagedObjectValue = NSNull

    @inlinable
    public static func convert(value: NSNull) -> NSNull { value }

    @inlinable
    public static var defaultRuntimeValue: NSNull {
        NSNull()
    }

    @inlinable
    public static var defaultManagedValue: NSNull {
        NSNull()
    }
}

extension UUID: PredicateEquatableAttribute, PredicateExpressibleByString {
    public static var nativeType: NSAttributeType { .UUIDAttributeType }
    public var predicateValue: NSObject { self as NSUUID }
}

extension NSCoding where Self: FieldAttribute {
    public typealias RawType = Self
    public typealias PresentingType = Self
    public static var nativeType: NSAttributeType { .transformableAttributeType }
}

extension RawRepresentable where Self: FieldAttribute {
    public typealias ManagedObjectValue = RawValue?
    public typealias RuntimeObjectValue = Self?
}

public protocol EntityEquatable: PredicateEquatable { }

extension ReadOnly: EntityEquatable {
    public var predicateValue: NSObject { managedObject }
}

extension NSManagedObject: EntityEquatable {
    public var predicateValue: NSObject { self }
}

extension NSManagedObjectID: EntityEquatable {
    public var predicateValue: NSObject { self }
}
