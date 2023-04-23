//
//  Property.swift
//  Crush
//
//  Created by EZOU on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - Entity Property

public protocol Property: AnyObject {
    typealias RuntimeValue = PropertyType.RuntimeValue
    typealias ManagedValue = PropertyType.ManagedValue
    typealias PredicateValue = PropertyType.PredicateValue

    associatedtype Description: NSPropertyDescription
    associatedtype PropertyType: Crush.PropertyType

    var name: String { get }
    var isAttribute: Bool { get }

    func createPropertyDescription() -> Description
}

public protocol WritableProperty: Property { }
