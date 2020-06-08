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

public protocol RuntimeField { }

public protocol FieldProtocol: Field {
    static var nativeType: NSAttributeType { get }
}

public protocol FieldConvertible {
    associatedtype RuntimeObjectValue
    associatedtype ManagedObjectValue
    
    static func convert(value: ManagedObjectValue) -> RuntimeObjectValue
    static func convert(value: RuntimeObjectValue) -> ManagedObjectValue
}

public protocol PredicateEquatable {
    var predicateValue: NSObject { get }
}

public protocol PredicateComparable: PredicateEquatable { }

public protocol FieldAttribute: FieldProtocol, FieldConvertible
where Self? == RuntimeObjectValue { }

public protocol PrimitiveAttribute: FieldAttribute
where ManagedObjectValue == Self? { }

extension FieldAttribute
where RuntimeObjectValue == Self?, RuntimeObjectValue == ManagedObjectValue {
    @inline(__always)
    public static func convert(value: Self?) -> Self? {
        value
    }
}

public protocol CodableProperty: PrimitiveAttribute, PredicateEquatable, Codable, Hashable {
    var data: Data { get set }
    var encoder: JSONEncoder { get }
    var decoder: JSONDecoder { get }
}

extension CodableProperty {
    public var encoder: JSONEncoder { JSONEncoder() }
    
    public var decoder: JSONDecoder { JSONDecoder() }
    
    public var data: Data {
        get {
            try! encoder.encode(self)
        }
        mutating set {
            self = try! decoder.decode(Self.self, from: newValue)
        }
    }
    
    public static var nativeType: NSAttributeType { .dateAttributeType }
    public var predicateValue: NSObject { data as NSData }
}

extension Int64: PrimitiveAttribute, PredicateComparable {
    public static var nativeType: NSAttributeType { .integer64AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int32: PrimitiveAttribute, PredicateComparable {
    public static var nativeType: NSAttributeType { .integer32AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int16: PrimitiveAttribute, PredicateComparable {
    public static var nativeType: NSAttributeType { .integer16AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension NSDecimalNumber: PrimitiveAttribute, PredicateComparable {
    public static var nativeType: NSAttributeType { .decimalAttributeType }
    public var predicateValue: NSObject { self }
}

extension Double: PrimitiveAttribute, PredicateComparable {
    public static var nativeType: NSAttributeType { .doubleAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Float: PrimitiveAttribute, PredicateComparable {
    public static var nativeType: NSAttributeType { .floatAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension String: PrimitiveAttribute, PredicateEquatable {
    public static var nativeType: NSAttributeType { .stringAttributeType }
    public var predicateValue: NSObject { NSString(string: self) }
}

extension Bool: PrimitiveAttribute, PredicateEquatable {
    public static var nativeType: NSAttributeType { .booleanAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Date: PrimitiveAttribute, PredicateComparable {
    public static var nativeType: NSAttributeType { .dateAttributeType }
    public var predicateValue: NSObject { self as NSDate }
}

extension Data: PrimitiveAttribute, PredicateEquatable {
    public static var nativeType: NSAttributeType { .binaryDataAttributeType }
    public var predicateValue: NSObject { self as NSData }
}

extension UUID: PrimitiveAttribute, PredicateEquatable {
    public static var nativeType: NSAttributeType { .UUIDAttributeType }
    public var predicateValue: NSObject { self as NSUUID }
}

extension NSCoding where Self: PrimitiveAttribute {
    public typealias RawType = Self
    public typealias PresentingType = Self
    
    public static var nativeType: NSAttributeType { .transformableAttributeType }
}

public protocol Enumerator: RawRepresentable, FieldAttribute, PredicateComparable, Hashable
where RawValue: FieldProtocol & PredicateEquatable { }

extension Enumerator {
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

extension Swift.Optional: RuntimeField where Wrapped: Field { }

extension Set: RuntimeField where Element: Field { }

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
