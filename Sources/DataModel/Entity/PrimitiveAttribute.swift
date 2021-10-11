//
//  PrimitiveAttribute.swift
//  Crush
//
//  Created by ezou on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData
import Foundation

public protocol Field { }

public protocol FieldProtocol: Field {
    static var nativeType: NSAttributeType { get }
}

public protocol FieldConvertible {
    associatedtype RuntimeObjectValue
    associatedtype ManagedObjectValue
    
    static func convert(value: ManagedObjectValue) -> RuntimeObjectValue
    static func convert(value: RuntimeObjectValue) -> ManagedObjectValue
}

public protocol PredicateExpressedByString { }

public protocol PredicateEquatable {
    var predicateValue: NSObject { get }
}

public protocol PredicateComparable: PredicateEquatable { }

public protocol FieldAttribute: FieldProtocol, FieldConvertible
where RuntimeObjectValue == Self? { }

public protocol PrimitiveAttribute: FieldAttribute
where ManagedObjectValue == Self? { }

public protocol CodableProperty: FieldAttribute, PredicateEquatable, Codable, Hashable {
    
    associatedtype ManagedObjectValue = Data?
    
    var data: Data { get set }
    
    static var encoder: JSONEncoder { get }
    static var decoder: JSONDecoder { get }
}

extension CodableProperty {
    @inline(__always)
    public static func convert(value: Data?) -> Self? {
        guard let value = value else { return nil }
        return try! Self.decoder.decode(Self.self, from: value)
    }
    
    @inline(__always)
    public static func convert(value: Self?) -> Data? {
        guard let value = value else { return nil }
        return try! Self.encoder.encode(value)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }
    
    public static var encoder: JSONEncoder { JSONEncoder() }
    
    public static var decoder: JSONDecoder { JSONDecoder() }
    
    public static var nativeType: NSAttributeType { .binaryDataAttributeType }
    
    public var predicateValue: NSObject { data as NSData }
    
    public var data: Data {
        get {
            try! Self.encoder.encode(self)
        }
        mutating set {
            self = try! Self.decoder.decode(Self.self, from: newValue)
        }
    }
}

extension FieldAttribute
where
    RuntimeObjectValue == Self?,
    RuntimeObjectValue == ManagedObjectValue
{
    @inline(__always)
    public static func convert(value: Self?) -> Self? {
        value
    }
}

public typealias PredicateComparableAttribute = PrimitiveAttribute & PredicateComparable
public typealias PredicateEquatableAttribute = PrimitiveAttribute & PredicateEquatable

extension Int64: PredicateComparableAttribute, PredicateExpressedByString {
    public static var nativeType: NSAttributeType { .integer64AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int32: PredicateComparableAttribute, PredicateExpressedByString {
    public static var nativeType: NSAttributeType { .integer32AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int16: PredicateComparableAttribute, PredicateExpressedByString {
    public static var nativeType: NSAttributeType { .integer16AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension NSDecimalNumber: PredicateComparableAttribute, PredicateExpressedByString {
    public static var nativeType: NSAttributeType { .decimalAttributeType }
    public var predicateValue: NSObject { self }
}

extension Double: PredicateComparableAttribute, PredicateExpressedByString {
    public static var nativeType: NSAttributeType { .doubleAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Float: PredicateComparableAttribute, PredicateExpressedByString {
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

extension Date: PredicateEquatableAttribute, PredicateExpressedByString {
    public static var nativeType: NSAttributeType { .dateAttributeType }
    public var predicateValue: NSObject { self as NSDate }
}

extension Data: PrimitiveAttribute, PredicateEquatable {
    public static var nativeType: NSAttributeType { .binaryDataAttributeType }
    public var predicateValue: NSObject { self as NSData }
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

public protocol Enumerator:
    RawRepresentable,
    FieldAttribute,
    PredicateComparable,
    Hashable
where
	RawValue: FieldProtocol & PredicateEquatable & Hashable { }

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

extension RawRepresentable where Self: FieldAttribute {
    public typealias ManagedObjectValue = RawValue?
    public typealias RuntimeObjectValue = Self?
}

extension Swift.Optional: Field where Wrapped: Field { }

extension Set: Field where Element: Field { }

extension OrderedSet: Field where Element: Field { }

#if os(iOS) || os(watchOS)
import UIKit.UIImage
extension UIImage: PrimitiveAttribute, PredicateEquatable {
    public var predicateValue: NSObject { self }
}
#endif

@objc(DefaultTransformer)
class DefaultTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    override open func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let value = value as? Data else {
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(with: value)
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value else {
            return nil
        }
        return NSKeyedArchiver.archivedData(withRootObject: value)
    }
}
