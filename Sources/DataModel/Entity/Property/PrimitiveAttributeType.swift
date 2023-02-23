//
//  PrimitiveAttributeType.swift
//  Crush
//
//  Created by ezou on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData
import Foundation

public protocol AnyPropertyType {
    func managedToRuntime(_ managedValue: Any?) -> Any?
    func runtimeToManaged(_ runtimeValue: Any?) -> Any?
}

public protocol PropertyType: AnyPropertyType {
    associatedtype RuntimeValue
    associatedtype ManagedValue
    
    static func convert(managedValue: ManagedValue) -> RuntimeValue
    static func convert(runtimeValue: RuntimeValue) -> ManagedValue

    static var defaultRuntimeValue: RuntimeValue { get }
    static var defaultManagedValue: ManagedValue { get }
}

extension PropertyType where RuntimeValue: OptionalProtocol {
    @inlinable
    public static var defaultRuntimeValue: RuntimeValue {
        return RuntimeValue.null
    }
}

extension PropertyType where ManagedValue: OptionalProtocol {
    @inlinable
    public static var defaultManagedValue: ManagedValue {
        return ManagedValue.null
    }
}

extension PropertyType where RuntimeValue: Collection & ExpressibleByArrayLiteral {
    @inlinable
    public static var defaultRuntimeValue: RuntimeValue {
        return []
    }
}

extension PropertyType where ManagedValue: Collection & ExpressibleByArrayLiteral {
    @inlinable
    public static var defaultManagedValue: ManagedValue {
        return []
    }
}

extension PropertyType where ManagedValue == NSMutableSet {
    public static var defaultManagedValue: NSMutableSet {
        NSMutableSet()
    }
}

extension PropertyType where ManagedValue == NSMutableOrderedSet {
    public static var defaultManagedValue: NSMutableOrderedSet {
        NSMutableOrderedSet()
    }
}

extension PropertyType {
    public func managedToRuntime(_ managedValue: Any?) -> Any? {
        guard let managedValue = managedValue as? ManagedValue else {
            return nil
        }
        return Self.convert(managedValue: managedValue)
    }

    public func runtimeToManaged(_ runtimeValue: Any?) -> Any? {
        guard let runtimeValue = runtimeValue as? RuntimeValue else {
            return nil
        }
        return Self.convert(runtimeValue: runtimeValue)
    }
}

public protocol PredicateExpressibleByString { }

public protocol PredicateComputable { }

public protocol PredicateEquatable {
    var predicateValue: NSObject { get }
}

public protocol PredicateComparable: PredicateEquatable { }

public protocol AttributeType: PropertyType
where ManagedValue: OptionalProtocol {
    associatedtype RuntimeValue: OptionalProtocol = Self?
    static var nativeType: NSAttributeType { get }
}

public protocol PrimitiveAttributeType: AttributeType {
    associatedtype ManagedValue: OptionalProtocol = Self?
}

public protocol TransformableAttributeType: NSObject, NSCoding, AttributeType
where RuntimeValue == ManagedValue {
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

extension PropertyType where RuntimeValue == ManagedValue {
    @inlinable public static func convert(runtimeValue: RuntimeValue) -> ManagedValue { runtimeValue }
    @inlinable public static func convert(managedValue: ManagedValue) -> RuntimeValue { managedValue }
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
    public typealias RuntimeValue = NSDecimalNumber?
    public typealias ManagedValue = NSDecimalNumber?

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

extension NSNull: PropertyType {
    public typealias RuntimeValue = NSNull
    public typealias ManagedValue = NSNull

    @inlinable public static var defaultRuntimeValue: NSNull { NSNull() }
    @inlinable public static var defaultManagedValue: NSNull { NSNull() }
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
