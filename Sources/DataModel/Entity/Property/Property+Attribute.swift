//
//  Property+Attribute.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - EntityAttribute

public protocol AttributeProtocol: WritableProperty
where
    PropertyType: AttributeType,
    PredicateValue == PropertyType,
    Description: NSAttributeDescription
{ }

extension AttributeProtocol {
    public var isAttribute: Bool { true }
    
    public var attributeType: NSAttributeType {
        PropertyType.nativeType
    }
}

public protocol ConcreteAttriuteProcotol: AttributeProtocol { }


// MARK: - EntityAttributeType
public class Attribute<PropertyType: AttributeType>:
    ConcreteAttriuteProcotol,
    TransformableAttributeInitProtocol,
    TransientProperty,
    AnyPropertyType
{
    public typealias PredicateValue = PropertyType
    public typealias PropertyValue = PropertyType.RuntimeValue
    
    public let name: String
    
    public required init(_ name: String) {
        self.name = name
    }
    
    public func createPropertyDescription() -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.name = name
        description.attributeType = attributeType
        return description
    }
}
