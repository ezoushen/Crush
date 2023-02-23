//
//  PrimitiveAttributeType.swift
//  Crush
//
//  Created by ezou on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData
import Foundation

public protocol AnyPropertyAdaptor {
    func managedToRuntime(_ managedValue: Any?) -> Any?
    func runtimeToManaged(_ runtimeValue: Any?) -> Any?
}

public protocol PropertyAdaptor: AnyPropertyAdaptor {
    associatedtype RuntimeObjectValue
    associatedtype ManagedObjectValue
    
    static func convert(value: ManagedObjectValue) -> RuntimeObjectValue
    static func convert(value: RuntimeObjectValue) -> ManagedObjectValue

    static var defaultRuntimeValue: RuntimeObjectValue { get }
    static var defaultManagedValue: ManagedObjectValue { get }
}

extension PropertyAdaptor where RuntimeObjectValue: OptionalProtocol {
    @inlinable
    public static var defaultRuntimeValue: RuntimeObjectValue {
        return RuntimeObjectValue.null
    }
}

extension PropertyAdaptor where ManagedObjectValue: OptionalProtocol {
    @inlinable
    public static var defaultManagedValue: ManagedObjectValue {
        return ManagedObjectValue.null
    }
}

extension PropertyAdaptor where RuntimeObjectValue: Collection & ExpressibleByArrayLiteral {
    @inlinable
    public static var defaultRuntimeValue: RuntimeObjectValue {
        return []
    }
}

extension PropertyAdaptor where ManagedObjectValue: Collection & ExpressibleByArrayLiteral {
    @inlinable
    public static var defaultManagedValue: ManagedObjectValue {
        return []
    }
}

extension PropertyAdaptor where ManagedObjectValue == NSMutableSet {
    public static var defaultManagedValue: NSMutableSet {
        NSMutableSet()
    }
}

extension PropertyAdaptor where ManagedObjectValue == NSMutableOrderedSet {
    public static var defaultManagedValue: NSMutableOrderedSet {
        NSMutableOrderedSet()
    }
}

extension PropertyAdaptor {
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

public protocol AttributeType: PropertyAdaptor
where ManagedObjectValue: OptionalProtocol {
    associatedtype RuntimeObjectValue: OptionalProtocol = Self?
    static var nativeType: NSAttributeType { get }
}

public protocol PrimitiveAttributeType: AttributeType {
    associatedtype ManagedObjectValue: OptionalProtocol = Self?
}

public protocol TransformableAttributeType: NSObject, NSCoding, AttributeType
where RuntimeObjectValue == ManagedObjectValue {
    static var attributeValueClassName: String? { get }
    static var valueTransformerName: String? { get }
}

extension TransformableAttributeType {
    public static var nativeType: NSAttributeType { .transformableAttributeType }
    
    public static var attributeValueClassName: String? {
        String(describing: Self.self)
    }
}

extension TransformableAttributeType {
    public static var valueTransformerName: String? {
        NSStringFromClass(DefaultTransformer.self)
    }
}

extension AttributeType
where
    RuntimeObjectValue == Self?,
    RuntimeObjectValue == ManagedObjectValue
{
    @inlinable
    public static func convert(value: Self?) -> Self? { value }
}

public typealias PredicateComparableAttributeType = PrimitiveAttributeType & PredicateComparable
public typealias PredicateEquatableAttributeType = PrimitiveAttributeType & PredicateEquatable

public typealias IntegerAttributeType = PredicateComparableAttributeType & PredicateExpressibleByString & PredicateComputable

extension Int: IntegerAttributeType {
    public static var nativeType: NSAttributeType {
#if (arch(x86_64) || arch(arm64))
        return .integer64AttributeType
#else
        return .integer32AttributeType
#endif
    }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int64: IntegerAttributeType {
    public static var nativeType: NSAttributeType { .integer64AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int32: IntegerAttributeType {
    public static var nativeType: NSAttributeType { .integer32AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int16: IntegerAttributeType {
    public static var nativeType: NSAttributeType { .integer16AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension NSDecimalNumber: PredicateComparableAttributeType, PredicateExpressibleByString, PredicateComputable {
    public typealias RuntimeObjectValue = NSDecimalNumber?
    public typealias ManagedObjectValue = NSDecimalNumber?

    public static var nativeType: NSAttributeType { .decimalAttributeType }
    public var predicateValue: NSObject { self }
}

extension Double: PredicateComparableAttributeType, PredicateExpressibleByString, PredicateComputable {
    public static var nativeType: NSAttributeType { .doubleAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Float: PredicateComparableAttributeType, PredicateExpressibleByString, PredicateComputable {
    public static var nativeType: NSAttributeType { .floatAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension String: PrimitiveAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .stringAttributeType }
    public var predicateValue: NSObject { NSString(string: self) }
}

extension Bool: PredicateEquatableAttributeType, PredicateExpressibleByString {
    public static var nativeType: NSAttributeType { .booleanAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Date: PredicateComparableAttributeType, PredicateExpressibleByString {
    public static var nativeType: NSAttributeType { .dateAttributeType }
    public var predicateValue: NSObject { self as NSDate }
}

extension Data: PrimitiveAttributeType, PredicateEquatable {
    public static var nativeType: NSAttributeType { .binaryDataAttributeType }
    public var predicateValue: NSObject { self as NSData }
}

extension NSNull: PropertyAdaptor {
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

extension UUID: PredicateEquatableAttributeType, PredicateExpressibleByString {
    public static var nativeType: NSAttributeType { .UUIDAttributeType }
    public var predicateValue: NSObject { self as NSUUID }
}

public protocol EntityEquatableType: PredicateEquatable { }

extension ReadOnly: EntityEquatableType {
    public var predicateValue: NSObject { managedObject }
}

extension NSManagedObject: EntityEquatableType {
    public var predicateValue: NSObject { self }
}

extension NSManagedObjectID: EntityEquatableType {
    public var predicateValue: NSObject { self }
}
