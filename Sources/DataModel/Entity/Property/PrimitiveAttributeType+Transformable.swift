//
//  PrimitiveAttributeType+Transformable.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

public protocol TransformableAttributeType: NSObject, NSCoding, PrimitiveAttributeType
where
    PrimitiveType == Self,
    RuntimeValue == PrimitiveType?,
    ManagedValue == PrimitiveType?,
    PredicateValue == PrimitiveType
{
    associatedtype PrimitiveType = Self

    associatedtype RuntimeValue = PrimitiveType?
    associatedtype ManagedValue = PrimitiveType?
    associatedtype PredicateValue = PrimitiveType

    static var attributeValueClassName: String? { get }
    static var valueTransformerName: String? { get }
}

extension TransformableAttributeType {
    public static var valueTransformerName: String? {
        NSStringFromClass(DefaultTransformer.self)
    }
}

extension TransformableAttributeType {
    @inlinable public static var nativeType: NSAttributeType { .transformableAttributeType }
    @inlinable public static var attributeValueClassName: String? { String(describing: Self.self) }
}

#if os(iOS) || os(watchOS)
import UIKit.UIImage
extension UIImage: PrimitiveAttributeType {
    public typealias PrimitiveType = UIImage
}

extension UIImage: PredicateEquatable {
    @inlinable public var predicateValue: NSObject { self }
}

extension UIColor: PrimitiveAttributeType {
    public typealias PrimitiveType = UIColor
}

extension UIColor: PredicateEquatable {
    @inlinable public var predicateValue: NSObject { self }
}
#endif

extension NSCoding where Self: PrimitiveAttributeType {
    public typealias PrimitveType = Self
    public static var nativeType: NSAttributeType { .transformableAttributeType }
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
