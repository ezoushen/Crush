//
//  Property.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - Entity Property

public protocol PropertyProtocol: AnyObject {
    var name: String { get }
    func createPropertyDescription() -> NSPropertyDescription
}

public protocol ValuedProperty: PropertyProtocol
where FieldConvertor.RuntimeObjectValue == PropertyValue {
    associatedtype PropertyValue
    associatedtype PredicateValue
    associatedtype Description: NSPropertyDescription
    associatedtype FieldConvertor: FieldConvertible

    var isAttribute: Bool { get }

    func createDescription() -> Description
}

extension ValuedProperty {
    @inlinable
    public func createPropertyDescription() -> NSPropertyDescription {
        createDescription()
    }
}
