//
//  FieldAttributeType.swift
//  Crush
//
//  Created by ezou on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData
import Foundation

public protocol SavableTypeProtocol {
    static var nativeType: NSAttributeType { get }
}

public protocol PredicateEquatable {
    var predicateValue: NSObject { get }
}

public protocol PredicateComparable: PredicateEquatable { }

public protocol FieldAttributeType: SavableTypeProtocol, FieldTypeProtocol
where Self? == RuntimeObjectValue {
}

public protocol PrimitiveAttributeType: FieldAttributeType
where ManagedObjectValue == Self? {
    typealias PrimitiveType = Self
}


extension FieldAttributeType
where RuntimeObjectValue == Self?, RuntimeObjectValue == ManagedObjectValue {
    @inline(__always)
    public static func convert(value: Self?, proxyType: PropertyProxyType) -> Self? {
        value
    }
}

extension Int64: PrimitiveAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .integer64AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int32: PrimitiveAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .integer32AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Int16: PrimitiveAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .integer16AttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension NSDecimalNumber: PrimitiveAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .decimalAttributeType }
    public var predicateValue: NSObject { self }
}

extension Double: PrimitiveAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .doubleAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Float: PrimitiveAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .floatAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension String: PrimitiveAttributeType, PredicateEquatable {
    public static var nativeType: NSAttributeType { .stringAttributeType }
    public var predicateValue: NSObject { NSString(string: self) }
}

extension Bool: PrimitiveAttributeType, PredicateEquatable {
    public static var nativeType: NSAttributeType { .booleanAttributeType }
    public var predicateValue: NSObject { NSNumber(value: self) }
}

extension Date: PrimitiveAttributeType, PredicateComparable {
    public static var nativeType: NSAttributeType { .dateAttributeType }
    public var predicateValue: NSObject { self as NSDate }
}

extension Data: PrimitiveAttributeType, PredicateEquatable {
    public static var nativeType: NSAttributeType { .binaryDataAttributeType }
    public var predicateValue: NSObject { self as NSData }
}

extension UUID: PrimitiveAttributeType, PredicateEquatable {
    public static var nativeType: NSAttributeType { .UUIDAttributeType }
    public var predicateValue: NSObject { self as NSUUID }
}

extension NSCoding where Self: PrimitiveAttributeType {
    public typealias RawType = Self
    public typealias PresentingType = Self
    
    public static var nativeType: NSAttributeType { .transformableAttributeType }
}

#if os(iOS) || os(watchOS)
import UIKit.UIImage
extension UIImage: PrimitiveAttributeType, PredicateEquatable {
    public var predicateValue: NSObject { self }
}
#endif

public protocol Enumerator: RawRepresentable, FieldAttributeType, PredicateComparable
where RawValue: SavableTypeProtocol & PredicateEquatable { }

extension Enumerator {
    public static func convert(value: RawValue?, proxyType: PropertyProxyType) -> Self? {
        guard let value = value else { return nil }
        return Self.init(rawValue: value)
    }
    
    public static func convert(value: Self?, proxyType: PropertyProxyType) -> RawValue? {
        value?.rawValue
    }
    
    public static var nativeType: NSAttributeType { RawValue.nativeType }
    public var predicateValue: NSObject { self.rawValue.predicateValue }
}

extension RawRepresentable where Self: FieldAttributeType {
    public typealias ManagedObjectValue = RawValue?
    public typealias RuntimeObjectValue = Self?
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
