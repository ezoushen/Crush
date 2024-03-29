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
    @inlinable public static var valueTransformerName: String? { nil }
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

extension UIColor: PrimitiveAttributeType {
    public typealias PrimitiveType = UIColor
}
#endif

extension NSCoding where Self: PrimitiveAttributeType & NSObject {
    @inlinable public static var nativeType: NSAttributeType { .transformableAttributeType }
    @inlinable public var predicateValue: NSObject { self }
}
