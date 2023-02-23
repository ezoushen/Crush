//
//  PrimitiveAttributeType+Transformable.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

#if os(iOS) || os(watchOS)
import UIKit.UIImage
extension UIImage: PrimitiveAttributeType, PredicateEquatable {
    public var predicateValue: NSObject { self }
}
extension UIColor: PrimitiveAttributeType, PredicateEquatable {
    public var predicateValue: NSObject { self }
}
#endif

extension NSCoding where Self: AttributeType {
    public typealias ManagedValue = Self?
    public typealias RuntimeValue = Self?
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
