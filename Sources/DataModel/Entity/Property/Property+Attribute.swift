//
//  Property+Attribute.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - EntityAttribute

public protocol AttributeProtocol: ValuedProperty
where
    PredicateValue: FieldAttribute & FieldConvertible,
    Description: NSAttributeDescription
{
    var defaultValue: PropertyValue { get }
    var attributeValueClassName: String? { get }
}

extension AttributeProtocol {
    public var isAttribute: Bool { true }
    
    public var attributeType: NSAttributeType {
        PredicateValue.nativeType
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
public class Attribute<F: FieldAttribute & Hashable>:
    ConcreteAttriuteProcotol,
    TransientProperty
{
    public typealias PredicateValue = F
    public typealias PropertyValue = F.RuntimeObjectValue
    public typealias FieldConvertor = F
    
    public let defaultValue: PropertyValue
    public let name: String
    
    public init(_ name: String, defaultValue: PropertyValue = nil) {
        self.name = name
        self.defaultValue = defaultValue
    }
    
    public func createDescription() -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.valueTransformerName = valueTransformerName
        description.name = name
        description.attributeType = attributeType
        
        // Make sure not setting default value to nil
        if let value = defaultValue {
            description.defaultValue = F.convert(value: value)
        }
        
        if let className = attributeValueClassName {
            description.attributeValueClassName = className
        }
        
        return description
    }
}
