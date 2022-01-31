//
//  PrimitiveAttribute.swift
//  Crush
//
//  Created by ezou on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData
import Foundation

public protocol FieldConvertible {
    associatedtype RuntimeObjectValue
    associatedtype ManagedObjectValue
    
    static func convert(value: ManagedObjectValue) -> RuntimeObjectValue
    static func convert(value: RuntimeObjectValue) -> ManagedObjectValue
}

public protocol PredicateExpressedByString { }

public protocol PredicateAggregatable { }

public protocol PredicateEquatable {
    var predicateValue: NSObject { get }
}

public protocol PredicateComparable: PredicateEquatable { }

public protocol FieldAttributeProtocol {
    static var nativeType: NSAttributeType { get }
}

public protocol FieldAttribute: FieldAttributeProtocol, FieldConvertible
where
    RuntimeObjectValue == Self?,
    ManagedObjectValue: OptionalProtocol { }

public protocol PrimitiveAttribute: FieldAttribute
where ManagedObjectValue == Self? { }

extension FieldAttribute
where
    RuntimeObjectValue == Self?,
    RuntimeObjectValue == ManagedObjectValue
{
    @inline(__always)
    public static func convert(value: Self?) -> Self? { value }
}

public typealias PredicateComparableAttribute = PrimitiveAttribute & PredicateComparable
public typealias PredicateEquatableAttribute = PrimitiveAttribute & PredicateEquatable

extension Int64: PredicateComparableAttribute, PredicateExpressedByString, PredicateAggregatable {
    public static var nativeType: NSAttributeType { .integer64AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int32: PredicateComparableAttribute, PredicateExpressedByString, PredicateAggregatable {
    public static var nativeType: NSAttributeType { .integer32AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int16: PredicateComparableAttribute, PredicateExpressedByString, PredicateAggregatable {
    public static var nativeType: NSAttributeType { .integer16AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension NSDecimalNumber: PredicateComparableAttribute, PredicateExpressedByString, PredicateAggregatable {
    public static var nativeType: NSAttributeType { .decimalAttributeType }
    public var predicateValue: NSObject { self }
}

extension Double: PredicateComparableAttribute, PredicateExpressedByString, PredicateAggregatable {
    public static var nativeType: NSAttributeType { .doubleAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Float: PredicateComparableAttribute, PredicateExpressedByString, PredicateAggregatable {
    public static var nativeType: NSAttributeType { .floatAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension String: PrimitiveAttribute, PredicateEquatable {
    public static var nativeType: NSAttributeType { .stringAttributeType }
    public var predicateValue: NSObject { NSString(string: self) }
}

extension Bool: PredicateEquatableAttribute, PredicateExpressedByString {
    public static var nativeType: NSAttributeType { .booleanAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Date: PredicateComparableAttribute, PredicateExpressedByString {
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
}

extension UUID: PredicateEquatableAttribute, PredicateExpressedByString {
    public static var nativeType: NSAttributeType { .UUIDAttributeType }
    public var predicateValue: NSObject { self as NSUUID }
}

extension NSCoding where Self: PrimitiveAttribute {
    public typealias RawType = Self
    public typealias PresentingType = Self
    public static var nativeType: NSAttributeType { .transformableAttributeType }
}

extension RawRepresentable where Self: FieldAttribute {
    public typealias ManagedObjectValue = RawValue?
    public typealias RuntimeObjectValue = Self?
}
