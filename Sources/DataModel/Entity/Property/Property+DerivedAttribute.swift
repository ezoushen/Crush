//
//  Property+DerivedAttribute.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public enum DerivedStringMapping: String {
    case canonical = "canonical:"
    case uppercase = "uppercase:"
    case lowercase = "lowercase:"
    case plain = ""
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public enum DerivedAggregation: String {
    case count
    case sum
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public final class DerivedAttribute<PropertyType: AttributeType>:
    AttributeProtocol,
    AnyPropertyType,
    TransformableDerivedAttributeInitProtocol
{
    public typealias Description = NSDerivedAttributeDescription
    public typealias PropertyValue = PropertyType.RuntimeValue
    public typealias PredicateValue = PropertyType

    public let defaultValue: PropertyValue
    public let name: String
    private let expressionBlock: () -> NSExpression
    public private(set) lazy var expression: NSExpression? = expressionBlock()

    public required init<T: Entity>(
        _ name: String, from keyPath: KeyPath<T, Attribute<PropertyType>>)
    {
        self.name = name
        self.defaultValue = .null
        self.expressionBlock = { NSExpression(forKeyPath: keyPath.propertyName) }
    }

    public required init<T: Entity, S: Entity> (
        _ name: String,
        from keyPath: KeyPath<T, Relationship<ToOne<S>>>,
        property extensionKeyPath: KeyPath<S, Attribute<PropertyType>>)
    {
        self.name = name
        self.defaultValue = .null
        self.expressionBlock = {
            let keyPath = "\(keyPath.propertyName).\(extensionKeyPath.propertyName)"
            return NSExpression(forKeyPath: keyPath)
        }
    }

    internal init(name: String, derivation: @autoclosure @escaping () -> NSExpression) {
        self.name = name
        self.defaultValue = .null
        self.expressionBlock = derivation
    }

    public func createPropertyDescription() -> NSDerivedAttributeDescription {
        let description = NSDerivedAttributeDescription()
        description.name = name
        description.attributeType = attributeType
        description.derivationExpression = expression
        return description
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension DerivedAttribute where PropertyType == String {
    public convenience init<T: Entity, S: AttributeProtocol>(
        _ name: String,
        from keyPath: KeyPath<T, S>,
        mapping: DerivedStringMapping)
    where
        S.PropertyType == String
    {
        self.init(
            name: name,
            derivation: .stringMapping(propertyName: keyPath.propertyName, mapping: mapping))
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension DerivedAttribute where PropertyType == Date {
    public convenience init(_ name: String) {
        self.init(name: name, derivation: .dateNow())
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension DerivedAttribute where PropertyType: CoreDataInteger {
    public convenience init<T: Entity, S: RelationshipProtocol>(
        _ name: String,
        from keyPath: KeyPath<T, S>,
        aggregation: DerivedAggregation)
    where
        S.Mapping: ToManyRelationMappingProtocol
    {
        self.init(
            name: name,
            derivation: .aggregate(
                toManyRelationship: keyPath.propertyName,
                aggregation: aggregation))
    }
}

