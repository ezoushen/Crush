//
//  Property.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - Entity Property

public protocol Property: AnyObject {
    typealias RuntimeValue = PropertyType.RuntimeValue
    typealias ManagedValue = PropertyType.ManagedValue

    associatedtype PredicateValue
    associatedtype Description: NSPropertyDescription
    associatedtype PropertyType: Crush.PropertyType

    var name: String { get }
    var isAttribute: Bool { get }

    func createPropertyDescription() -> Description
}

public protocol WritableProperty: Property { }

extension AnyPropertyType where Self: Property {
    public func managedToRuntime(_ managedValue: Any?) -> Any? {
        guard let managedValue = managedValue as? PropertyType.ManagedValue else {
            return nil
        }
        return PropertyType.convert(managedValue: managedValue)
    }

    public func runtimeToManaged(_ runtimeValue: Any?) -> Any? {
        guard let runtimeValue = runtimeValue as? PropertyType.RuntimeValue else {
            return nil
        }
        return PropertyType.convert(runtimeValue: runtimeValue)
    }
}
