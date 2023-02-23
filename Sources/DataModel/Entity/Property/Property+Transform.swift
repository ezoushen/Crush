//
//  Property+Transform.swift
//  
//
//  Created by EZOU on 2023/2/23.
//

import CoreData
import Foundation

public class TransformAttribute<Attribute: AttributeProtocol>: AttributeProtocol, AnyPropertyAdaptor
where Attribute.FieldConvertor: TransformableAttributeType {
    public typealias Description = NSAttributeDescription
    public typealias PredicateValue = Attribute.PredicateValue
    public typealias FieldConvertor = Attribute.FieldConvertor
    
    public var name: String { attribute.name }
    
    public let attribute: Attribute
    
    init(attribute: Attribute) {
        self.attribute = attribute
    }
    
    public func createDescription() -> NSAttributeDescription {
        let description = attribute.createDescription()
        description.valueTransformerName = Attribute.FieldConvertor.valueTransformerName
        description.attributeValueClassName = Attribute.FieldConvertor.attributeValueClassName
        return description
    }
}

extension TransformAttribute: ConcreteAttriuteProcotol
where Attribute: ConcreteAttriuteProcotol { }

extension TransformAttribute: TransientProperty
where Attribute: TransientProperty { }

extension TransformAttribute where Attribute: TransformAttributeProtocol {
    public convenience init(_ name: String) {
        self.init(attribute: Attribute(name))
    }
}

extension TransformAttribute where Attribute: DerivedAttributeProtocol {
    public convenience init<T: Entity>(
        _ name: String, from keyPath: KeyPath<T, Crush.Attribute<FieldConvertor>>)
    {
        self.init(attribute: Attribute(name, from: keyPath))
    }
    
    public convenience init<T: Entity, S: Entity> (
        _ name: String,
        from keyPath: KeyPath<T, Relationship<ToOne<S>>>,
        property extensionKeyPath: KeyPath<S, Crush.Attribute<FieldConvertor>>)
    {
        self.init(attribute: Attribute(name, from: keyPath, property: extensionKeyPath))
    }
}
