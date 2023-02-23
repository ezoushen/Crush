//
//  Property+Attribute.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - EntityAttribute

public protocol AttributeProtocol: WritableValuedProperty
where
    FieldConvertor: AttributeType,
    FieldConvertor == PredicateValue,
    Description: NSAttributeDescription
{ }

extension AttributeProtocol {
    public var isAttribute: Bool { true }
    
    public var attributeType: NSAttributeType {
        FieldConvertor.nativeType
    }
}

public protocol ConcreteAttriuteProcotol: AttributeProtocol { }
public protocol TransformAttributeProtocol: ConcreteAttriuteProcotol {
    init(_ name: String)
}

// MARK: - EntityAttributeType
public class Attribute<F: AttributeType>:
    TransformAttributeProtocol,
    TransientProperty,
    AnyPropertyAdaptor
{
    public typealias PropertyValue = F.RuntimeObjectValue
    public typealias FieldConvertor = F
    
    public let name: String
    
    public required init(_ name: String) {
        self.name = name
    }
    
    public func createDescription() -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.name = name
        description.attributeType = attributeType
        return description
    }
}
