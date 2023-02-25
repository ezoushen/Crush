//
//  Property+Transform.swift
//  
//
//  Created by EZOU on 2023/2/23.
//

import CoreData
import Foundation

public protocol TransformableAttributeInitProtocol: AttributeProtocol {
    init(_ name: String)
}

public protocol TransformableDerivedAttributeInitProtocol: AttributeProtocol {
    init(_ name: String, from keyPath: @autoclosure @escaping () -> String)
}

public class TransformableAttribute<Attribute: AttributeProtocol>: AttributeProtocol, AnyPropertyType
where Attribute.PropertyType: TransformableAttributeType {
    public typealias Description = NSAttributeDescription
    public typealias PredicateValue = Attribute.PredicateValue
    public typealias PropertyType = Attribute.PropertyType
    
    public var name: String { attribute.name }
    
    public let attribute: Attribute
    
    init(attribute: Attribute) {
        self.attribute = attribute
    }
    
    public func createPropertyDescription() -> NSAttributeDescription {
        let description = attribute.createPropertyDescription()
        description.valueTransformerName = Attribute.PropertyType.valueTransformerName
        description.attributeValueClassName = Attribute.PropertyType.attributeValueClassName
        return description
    }
}

extension TransformableAttribute: ConcreteAttriuteProcotol
where Attribute: ConcreteAttriuteProcotol { }

extension TransformableAttribute: TransientProperty
where Attribute: TransientProperty { }

extension TransformableAttribute where Attribute: TransformableAttributeInitProtocol {
    public convenience init(_ name: String) {
        self.init(attribute: Attribute(name))
    }
}

extension TransformableAttribute where Attribute: TransformableDerivedAttributeInitProtocol {
    public convenience init<T: Entity>(
        _ name: String, from keyPath: KeyPath<T, Crush.Attribute<PropertyType>>)
    {
        self.init(attribute: Attribute(name, from: keyPath.propertyName))
    }

    public convenience init<T: Entity>(
        _ name: String, from keyPath: KeyPath<T, Crush.TransformableAttribute<Crush.Attribute<PropertyType>>>)
    {
        self.init(attribute: Attribute(name, from: keyPath.propertyName))
    }
    
    public convenience init<T: Entity, S: Entity> (
        _ name: String,
        from keyPath: KeyPath<T, Relationship<ToOne<S>>>,
        property extensionKeyPath: KeyPath<S, Crush.Attribute<PropertyType>>)
    {
        self.init(attribute: Attribute(name, from: "\(keyPath.propertyName).\(extensionKeyPath.propertyName)"))
    }

    public convenience init<T: Entity, S: Entity> (
        _ name: String,
        from keyPath: KeyPath<T, Relationship<ToOne<S>>>,
        property extensionKeyPath: KeyPath<S, Crush.TransformableAttribute<Crush.Attribute<PropertyType>>>)
    {
        self.init(attribute: Attribute(name, from: "\(keyPath.propertyName).\(extensionKeyPath.propertyName)"))
    }
}
