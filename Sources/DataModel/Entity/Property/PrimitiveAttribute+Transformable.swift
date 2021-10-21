//
//  PrimitiveAttribute+Transformable.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import Foundation

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
