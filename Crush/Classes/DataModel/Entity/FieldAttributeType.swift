//
//  FieldAttributeType.swift
//  Crush
//
//  Created by ezou on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData
import UIKit
import Foundation

public protocol SavableTypeProtocol {
    static var nativeType: NSAttributeType { get }
    static var nativeTypeName: String { get }
    var presentedAsString: String { get }
}

public protocol PredicateEquatable {
    var predicateValue: NSObject { get }
}

public protocol PredicateComparable: PredicateEquatable { }

public protocol FieldAttributeType: SavableTypeProtocol, FieldTypeProtocol where Self == RuntimeObjectValue, ManagedObjectValue: FieldAttributeType {
}

extension SavableTypeProtocol {
    public static var nativeTypeName: String { String(describing: Self.self) }
    public var presentedAsString: String { "\(self)" }
}

extension FieldAttributeType where RuntimeObjectValue == Self, RuntimeObjectValue == ManagedObjectValue {
    public static func convert(value: Self) -> Self {
        value
    }
}

extension Int64: FieldAttributeType, PredicateComparable {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    
    public static var nativeType: NSAttributeType { .integer64AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int32: FieldAttributeType, PredicateComparable {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    
    public static var nativeType: NSAttributeType { .integer32AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int16: FieldAttributeType, PredicateComparable {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    
    public static var nativeType: NSAttributeType { .integer16AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension NSDecimalNumber: FieldAttributeType, PredicateComparable {
    public typealias RuntimeObjectValue = NSDecimalNumber
    public typealias ManagedObjectValue = NSDecimalNumber
    
    public static var nativeTypeName: String { "DenimalNumber" }
    public static var nativeType: NSAttributeType { .decimalAttributeType }
    public var predicateValue: NSObject { self }
    public var presentedAsString: String { "NSDecimalNumber(decimal: \(self.decimalValue)" }
}

extension Double: FieldAttributeType, PredicateComparable {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    
    public static var nativeType: NSAttributeType { .doubleAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Float: FieldAttributeType, PredicateComparable {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    
    public static var nativeType: NSAttributeType { .floatAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension String: FieldAttributeType, PredicateEquatable {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    
    public static var nativeType: NSAttributeType { .stringAttributeType }
    public var predicateValue: NSObject { NSString(string: self) }
    public var presentedAsString: String { "\\\"\(self)\\\"" }
}

extension Bool: FieldAttributeType, PredicateEquatable {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    
    public static var nativeType: NSAttributeType { .booleanAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Date: FieldAttributeType, PredicateComparable {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    
    public static var nativeType: NSAttributeType { .dateAttributeType }
    public var predicateValue: NSObject { self as NSDate }
    public var presentedAsString: String { "Date(timeIntervalSince1970: \(timeIntervalSince1970))" }
}

extension Data: FieldAttributeType, PredicateEquatable {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    
    public static var nativeType: NSAttributeType { .binaryDataAttributeType }
    public var predicateValue: NSObject { self as NSData }
    public var presentedAsString: String { "Data(base64Encoded: \\\"\(base64EncodedString())\\\")" }
}

extension UUID: FieldAttributeType, PredicateEquatable {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    
    public static var nativeType: NSAttributeType { .UUIDAttributeType }
    public var predicateValue: NSObject { self as NSUUID }
    public var presentedAsString: String { "UUID()" }
}

extension NSCoding where Self: FieldAttributeType {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
    public typealias RawType = Self
    public typealias PresentingType = Self
    public static var nativeType: NSAttributeType { .transformableAttributeType }
}

extension UIImage: FieldAttributeType, PredicateEquatable {
    public var predicateValue: NSObject { self }
}

extension Swift.Optional: FieldTypeProtocol where Wrapped: FieldTypeProtocol {
    public static func convert(value: Swift.Optional<Wrapped.ManagedObjectValue>) -> Swift.Optional<Wrapped.RuntimeObjectValue> {
        guard let value = value else { return nil }
        return Wrapped.convert(value: value)
    }
    
    public static func convert(value: Swift.Optional<Wrapped.RuntimeObjectValue>) -> Swift.Optional<Wrapped.ManagedObjectValue> {
        guard let value = value else { return nil }
        return Wrapped.convert(value: value)
    }
    
    public typealias RuntimeObjectValue = Swift.Optional<Wrapped.RuntimeObjectValue>
    public typealias ManagedObjectValue = Swift.Optional<Wrapped.ManagedObjectValue>
}

extension Swift.Optional: SavableTypeProtocol where Wrapped: SavableTypeProtocol {
    public static var nativeType: NSAttributeType {
        return Wrapped.nativeType
    }
    public var presentedAsString: String {
        guard case let .some(wrapped) = self else { return "nil" }
        return wrapped.presentedAsString
    }
}

extension Swift.Optional: FieldAttributeType where Wrapped: FieldAttributeType {
    public static var nativeTypeName: String {
        return Wrapped.nativeTypeName
    }
}

extension Swift.Optional: PredicateEquatable where Wrapped: PredicateEquatable {
    public var predicateValue: NSObject {
        guard case let .some(value) = self else { return NSNull() }
        return value.predicateValue
    }
}

extension Swift.Optional: PredicateComparable where Wrapped: PredicateComparable {
    public var predicateValue: NSObject {
        guard case let .some(value) = self else { return NSNull() }
        return value.predicateValue
    }
}

public protocol Enumerator: RawRepresentable, FieldAttributeType, PredicateComparable where RawValue: SavableTypeProtocol & PredicateEquatable, ManagedObjectValue: SavableTypeProtocol & PredicateEquatable { }

extension Enumerator {
    public static func convert(value: RawValue) -> Self {
        Self.init(rawValue: value)!
    }
    
    public static func convert(value: Self) -> RawValue {
        value.rawValue
    }
    
    public static var nativeType: NSAttributeType { .integer16AttributeType }
    public var predicateValue: NSObject { self.rawValue.predicateValue }
}

extension RawRepresentable where Self: FieldAttributeType {
    public typealias ManagedObjectValue = RawValue
    public typealias RuntimeObjectValue = Self
}

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
