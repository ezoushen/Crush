//
//  PrimitiveAttributeType.swift
//  Crush
//
//  Created by ezou on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData
import Foundation

// MARK: - AttributeType

public protocol AnyPropertyType {
    func managedToRuntime(_ managedValue: Any?) -> Any?
    func runtimeToManaged(_ runtimeValue: Any?) -> Any?
}

public protocol PropertyType: AnyPropertyType {
    associatedtype RuntimeValue
    associatedtype ManagedValue
    associatedtype PredicateValue
    
    static func convert(managedValue: ManagedValue) -> RuntimeValue
    static func convert(runtimeValue: RuntimeValue) -> ManagedValue

    static var defaultRuntimeValue: RuntimeValue { get }
    static var defaultManagedValue: ManagedValue { get }
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

extension PropertyType where RuntimeValue == ManagedValue {
    @inlinable public static func convert(runtimeValue: RuntimeValue) -> ManagedValue { runtimeValue }
    @inlinable public static func convert(managedValue: ManagedValue) -> RuntimeValue { managedValue }
}

public protocol AttributeType: PropertyType
where
    ManagedValue: OptionalProtocol,
    RuntimeValue: OptionalProtocol
{
    static var nativeType: NSAttributeType { get }
}

public protocol PrimitiveAttributeType: AttributeType
where
    ManagedValue == RuntimeValue,
    PredicateValue == PrimitiveType,
    ManagedValue == PrimitiveType?
{
    associatedtype PrimitiveType

    associatedtype RuntimeValue = PrimitiveType?
    associatedtype ManagedValue = PrimitiveType?
    associatedtype PredicateValue = PrimitiveType
}

extension PrimitiveAttributeType {
    @inlinable public static var defaultRuntimeValue: RuntimeValue { nil }
    @inlinable public static var defaultManagedValue: ManagedValue { nil }
}

/// This protocol is used to mark all integer attribute types
public protocol IntAttributeType: PrimitiveAttributeType
where PrimitiveType: BinaryInteger {
    associatedtype RuntimeValue = PrimitiveType?
    associatedtype ManagedValue = PrimitiveType?
    associatedtype PredicateValue = PrimitiveType
}

public enum Int16AttributeType: IntAttributeType {
    public typealias PrimitiveType = Int16
    @inlinable public static var nativeType: NSAttributeType { .integer16AttributeType }
}

public enum Int32AttributeType: IntAttributeType {
    public typealias PrimitiveType = Int32
    @inlinable public static var nativeType: NSAttributeType { .integer32AttributeType }
}

public enum Int64AttributeType: IntAttributeType {
    public typealias PrimitiveType = Int64
    @inlinable public static var nativeType: NSAttributeType { .integer64AttributeType }
}

public enum DoubleAttributeType: PrimitiveAttributeType {
    public typealias PrimitiveType = Double
    @inlinable public static var nativeType: NSAttributeType { .doubleAttributeType }
}

public enum FloatAttributeType: PrimitiveAttributeType {
    public typealias PrimitiveType = Float
    @inlinable public static var nativeType: NSAttributeType { .floatAttributeType }
}

public enum StringAttributeType: PrimitiveAttributeType {
    public typealias PrimitiveType = String
    @inlinable public static var nativeType: NSAttributeType { .stringAttributeType }
}

public enum DateAttributeType: PrimitiveAttributeType {
    public typealias PrimitiveType = Date
    @inlinable public static var nativeType: NSAttributeType { .dateAttributeType }
}

public enum BoolAttributeType: PrimitiveAttributeType {
    public typealias PrimitiveType = Bool
    @inlinable public static var nativeType: NSAttributeType { .booleanAttributeType }
}

public enum BinaryDataAttributeType: PrimitiveAttributeType {
    public typealias PrimitiveType = Data
    @inlinable public static var nativeType: NSAttributeType { .binaryDataAttributeType }
}

public enum DecimalAttributeType: PrimitiveAttributeType {
    public typealias PrimitiveType = Decimal
    @inlinable public static var nativeType: NSAttributeType { .decimalAttributeType }
}

public enum UUIDAttributeType: PrimitiveAttributeType {
    public typealias PrimitiveType = UUID
    @inlinable public static var nativeType: NSAttributeType { .UUIDAttributeType }
}

public enum URIAttributeType: PrimitiveAttributeType {
    public typealias PrimitiveType = URL
    @inlinable public static var nativeType: NSAttributeType { .URIAttributeType }
}

extension NSNull: PropertyType {
    public typealias RuntimeValue = NSNull
    public typealias ManagedValue = NSNull
    public typealias PredicateValue = NSNull

    @inlinable public static var defaultRuntimeValue: NSNull { NSNull() }
    @inlinable public static var defaultManagedValue: NSNull { NSNull() }
}


// MARK: - Predicatable

public protocol Predicatable {
    associatedtype PredicateType: CVarArg = NSObject
    var predicateValue: PredicateType { get }
}

public protocol PredicateExpressibleByString: Predicatable { }

public protocol PredicateComputable: Predicatable { }

public protocol PredicateEquatable: Predicatable { }

public protocol PredicateComparable: PredicateEquatable { }

extension Int: PredicateComparable, PredicateComputable, PredicateExpressibleByString {
    @inlinable public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int64: PredicateComparable, PredicateComputable, PredicateExpressibleByString {
    @inlinable public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int32: PredicateComparable, PredicateComputable, PredicateExpressibleByString {
    @inlinable public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int16: PredicateComparable, PredicateComputable, PredicateExpressibleByString {
    @inlinable public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Double: PredicateComparable, PredicateComputable, PredicateExpressibleByString {
    @inlinable public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Float: PredicateComparable, PredicateComputable, PredicateExpressibleByString {
    @inlinable public var predicateValue: NSObject { NSNumber(value: self) }
}

extension String: PredicateComparable {
    @inlinable public var predicateValue: NSObject { NSString(string: self) }
}

extension Bool: PredicateEquatable, PredicateExpressibleByString {
    @inlinable public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Data: PredicateEquatable {
    @inlinable public var predicateValue: NSObject { self as NSData }
}

extension Date: PredicateComparable, PredicateExpressibleByString {
    @inlinable public var predicateValue: NSObject { self as NSDate }
}

extension Decimal: PredicateComparable, PredicateComputable, PredicateExpressibleByString {
    @inlinable public var predicateValue: NSObject { self as NSDecimalNumber }
}

extension UUID: PredicateEquatable, PredicateExpressibleByString {
    @inlinable public var predicateValue: NSObject { self as NSUUID }
}

public protocol EntityEquatableType: PredicateEquatable { }

extension ReadOnly: EntityEquatableType {
    public var predicateValue: NSObject { managedObject }
}

extension NSManagedObject: EntityEquatableType {
    @inlinable public var predicateValue: NSObject { self }
}

extension NSManagedObjectID: EntityEquatableType {
    @inlinable public var predicateValue: NSObject { self }
}
