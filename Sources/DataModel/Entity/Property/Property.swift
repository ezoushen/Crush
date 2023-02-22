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
where FieldConvertor.RuntimeObjectValue == Value {
    typealias Value = FieldConvertor.RuntimeObjectValue
    typealias RawValue = FieldConvertor.ManagedObjectValue

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

public protocol WritableValuedProperty: ValuedProperty { }

extension AnyFieldConvertible where Self: ValuedProperty {
    public func managedToRuntime(_ managedValue: Any?) -> Any? {
        guard let managedValue = managedValue as? FieldConvertor.ManagedObjectValue else {
            return nil
        }
        return FieldConvertor.convert(value: managedValue)
    }

    public func runtimeToManaged(_ runtimeValue: Any?) -> Any? {
        guard let runtimeValue = runtimeValue as? FieldConvertor.RuntimeObjectValue else {
            return nil
        }
        return FieldConvertor.convert(value: runtimeValue)
    }
}
