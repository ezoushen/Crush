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
    FieldConvertor: FieldAttribute,
    FieldConvertor == PredicateValue,
    Description: NSAttributeDescription
{
    var attributeValueClassName: String? { get }
}

extension AttributeProtocol {
    public var isAttribute: Bool { true }
    
    public var attributeType: NSAttributeType {
        FieldConvertor.nativeType
    }
    
    public var attributeValueClassName: String? {
        PredicateValue.self is NSCoding.Type
            ? String(describing: Self.self)
            : nil
    }
    
    public var valueTransformerName: String? {
        PredicateValue.self is NSCoding.Type
            ? String(describing: DefaultTransformer.self)
            : nil
    }
}

public protocol ConcreteAttriuteProcotol: AttributeProtocol { }

// MARK: - EntityAttributeType
public class Attribute<F: FieldAttribute>:
    ConcreteAttriuteProcotol,
    TransientProperty,
    AnyFieldConvertible
{
    public typealias PropertyValue = F.RuntimeObjectValue
    public typealias FieldConvertor = F
    
    public let name: String
    
    public init(_ name: String) {
        self.name = name
    }
    
    public func createDescription() -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.valueTransformerName = valueTransformerName
        description.name = name
        description.attributeType = attributeType
        
        if let className = attributeValueClassName {
            description.attributeValueClassName = className
        }
        
        return description
    }
}
