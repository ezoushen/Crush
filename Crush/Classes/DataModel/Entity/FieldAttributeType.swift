//
//  FieldAttributeType.swift
//  Crush
//
//  Created by ezou on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData
import UIKit

public protocol SavableTypeProtocol {
    static var nativeType: NSAttributeType { get }
    static var nativeTypeName: String { get }
    var presentedAsString: String { get }
}

public protocol PredicateEquatable {
    var predicateValue: NSObject { get }
}

public protocol PredicateComparable: PredicateEquatable { }

extension SavableTypeProtocol where Self: FieldTypeProtocol {
    public typealias RuntimeObjectValue = Self
    public typealias ManagedObjectValue = Self
}

public protocol FieldAttributeType: SavableTypeProtocol, FieldTypeProtocol where Self == RuntimeObjectValue, Self == ManagedObjectValue { }

extension SavableTypeProtocol {
    public static var nativeTypeName: String { String(describing: Self.self) }
    public var presentedAsString: String { "\(self)" }
}

extension Int64: FieldAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .integer64AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int32: FieldAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .integer32AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int16: FieldAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .integer16AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension NSDecimalNumber: FieldAttributeType, PredicateComparable {
    public static var nativeTypeName: String { "DenimalNumber" }
    public static var nativeType: NSAttributeType { .decimalAttributeType }
    public var predicateValue: NSObject { self }
    public var presentedAsString: String { "NSDecimalNumber(decimal: \(self.decimalValue)" }
}

extension Double: FieldAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .doubleAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Float: FieldAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .floatAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension String: FieldAttributeType, PredicateEquatable {
    public static var nativeType: NSAttributeType { .stringAttributeType }
    public var predicateValue: NSObject { NSString(string: self) }
    public var presentedAsString: String { "\\\"\(self)\\\"" }
}

extension Bool: FieldAttributeType, PredicateEquatable {
    public static var nativeType: NSAttributeType { .booleanAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Date: FieldAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .dateAttributeType }
    public var predicateValue: NSObject { self as NSDate }
    public var presentedAsString: String { "Date(timeIntervalSince1970: \(timeIntervalSince1970))" }
}

extension Data: FieldAttributeType, PredicateEquatable {
    public static var nativeType: NSAttributeType { .binaryDataAttributeType }
    public var predicateValue: NSObject { self as NSData }
    public var presentedAsString: String { "Data(base64Encoded: \\\"\(base64EncodedString())\\\")" }
}

extension UUID: FieldAttributeType, PredicateEquatable {
    public static var nativeType: NSAttributeType { .UUIDAttributeType }
    public var predicateValue: NSObject { self as NSUUID }
    public var presentedAsString: String { "UUID()" }
}

extension NSCoding where Self: FieldAttributeType {
    public typealias RawType = Self
    public typealias PresentingType = Self
    public static var nativeType: NSAttributeType { .transformableAttributeType }
}

extension UIImage: FieldAttributeType, PredicateEquatable {
    public static var nativeType: NSAttributeType { .transformableAttributeType }
    public var predicateValue: NSObject { self }
}

extension Swift.Optional: FieldTypeProtocol where Wrapped: FieldTypeProtocol { }

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
