//
//  Property+DerivedAttribute.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public class DerivedAttribute<
    O: Nullability,
    F: FieldAttribute & Hashable
> :
    Attribute<O, F, NonTransient>
{
    let expression: NSExpression?

    internal init(_ name: String, derivation: String, options: PropertyConfiguration = []) {
        expression = NSExpression(format: derivation)
        super.init(name, defaultValue: nil, options: options)
    }

    private override init(_ name: String) {
        expression = nil
        super.init(name)
    }

    private override init(
        _ name: String,
        defaultValue: PropertyValue = nil,
        options: PropertyConfiguration = [])
    {
        expression = nil
        super.init(name, defaultValue: defaultValue, options: [])
    }

    public override func createPropertyDescription() -> NSPropertyDescription {
        let description = NSDerivedAttributeDescription()

        configuration.configure(description: description)

        description.isTransient = isTransient
        description.valueTransformerName = valueTransformerName
        description.name = name
        description.attributeType = attributeType
        description.isOptional = O.isOptional
        description.derivationExpression = expression

        if let className = attributeValueClassName {
            description.attributeValueClassName = className
        }

        return description
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension DerivedAttribute {
    public convenience init<
        T: Entity,
        S: AttributeProtocol
    >(
        _ name: String,
        from keyPath: KeyPath<T, S>,
        options: PropertyConfiguration = [])
    where
    S.PropertyValue == PropertyValue
    {
        self.init(name, derivation: keyPath.propertyName, options: options)
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public enum DerivedStringMapping: String {
    case canonical = "canonical:"
    case uppercase = "uppercase:"
    case lowercase = "lowercase:"
    case plain = ""
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public enum DerivedAggregation: String {
    case count
    case sum
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension DerivedAttribute where FieldType == String {
    public convenience init<
        T: Entity,
        S: AttributeProtocol
    >(
        _ name: String,
        from keyPath: KeyPath<T, S>,
        mapping: DerivedStringMapping = .plain,
        options: PropertyConfiguration = [])
    where
    S.FieldConvertor: PredicateExpressedByString
    {
        self.init(name, derivation: "\(mapping.rawValue)(\(keyPath.propertyName).stringValue", options: options)
    }

    public convenience init<
        T: Entity,
        S: AttributeProtocol
    >(
        _ name: String,
        from keyPath: KeyPath<T, S>,
        mapping: DerivedStringMapping = .plain,
        options: PropertyConfiguration = [])
    where
    S.FieldConvertor == String
    {
        self.init(name, derivation: "\(mapping.rawValue)(\(keyPath.propertyName)", options: options)
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension DerivedAttribute where FieldType == Date {
    public convenience init(
        _ name: String,
        options: PropertyConfiguration = [])
    {
        self.init(name, derivation: "now()", options: options)
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension DerivedAttribute where FieldType: CoreDataInteger {
    public convenience init<
        T: Entity,
        S: RelationshipProtocol
    >(
        _ name: String,
        from keyPath: KeyPath<T, S>,
        aggregation: DerivedAggregation,
        options: PropertyConfiguration = [])
    where
    S.Mapping: ToManyRelationMappingProtocol
    {
        self.init(
            name,
            derivation: "\(keyPath.propertyName).@\(aggregation)",
            options: options)
    }
}

