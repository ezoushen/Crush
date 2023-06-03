//
//  Property+DerivedAttribute.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

/// An enumeration of derived attribute derivation expressions.
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public enum DerivedStringMapping: String {
    /// A canonical mapping that converts the property string value to canonical (case and diacritics removed) form.
    case canonical = "canonical:"
    /// An uppercase mapping that converts the property string value to uppercase.
    case uppercase = "uppercase:"
    /// A lowercase mapping that converts the property string value to lowercase.
    case lowercase = "lowercase:"
    /// A plain mapping that returns the property string value as is.
    case plain = ""
}

/// An enumeration of derived aggregations that can be used to calculate a property's value.
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public enum DerivedAggregation: String {
    /// The count aggregation calculates the number of non-nil values for a property.
    case count
    /// The sum aggregation calculates the sum of all non-nil values for a property.
    case sum
}

/**
 A class representing a derived attribute for an entity.

 A derived attribute is an attribute whose value is calculated from other attributes. This class provides a way to define a derived attribute using a closure that returns an `NSExpression`.
 */
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public final class DerivedAttribute<PropertyType: AttributeType>:
    AttributeProtocol,
    TransformableDerivedAttributeInitProtocol
{
    /// The type of the attribute description.
    public typealias Description = NSDerivedAttributeDescription
    /// The type of the runtime value of the attribute.
    public typealias PropertyValue = PropertyType.RuntimeValue
    /// The type of the predicate value of the attribute.
    public typealias PredicateValue = PropertyType.PredicateValue

    /// The default value of the attribute.
    public let defaultValue: PropertyValue
    /// The name of the attribute.
    public let name: String
    /// The closure that returns the `NSExpression` used to calculate the attribute value.
    private let expressionBlock: () -> NSExpression
    /// The `NSExpression` used to calculate the attribute value.
    public private(set) lazy var expression: NSExpression? = expressionBlock()

    /**
     Initializes a derived attribute with a name and a key path.

     - Parameters:
        - name: The name of the attribute.
        - keyPath: The key path used to calculate the attribute value.
     */
    public required init(_ name: String, from keyPath: @autoclosure @escaping () -> String)
    {
        self.name = name
        self.defaultValue = .null
        self.expressionBlock = { NSExpression(forKeyPath: keyPath()) }
    }

    /**
     Initializes a derived attribute with a name and a key path.

     - Parameters:
        - name: The name of the attribute.
        - keyPath: The key path used to calculate the attribute value.
     */
    public convenience init<T: Entity>(
        _ name: String, from keyPath: KeyPath<T, Attribute<PropertyType>>)
    {
        self.init(name, from: keyPath.propertyName)
    }

    /**
     Initializes a derived attribute with a name and a key path.

     - Parameters:
        - name: The name of the attribute.
        - keyPath: The key path used to calculate the attribute value.
     */
    public convenience init<T: Entity>(
        _ name: String, from keyPath: KeyPath<T, TransformableAttribute<Attribute<PropertyType>>>)
    {
        self.init(name, from: keyPath.propertyName)
    }

    /**
     Initializes a derived attribute with a name, a key path, and an extension key path.

     - Parameters:
        - name: The name of the attribute.
        - keyPath: The key path used to calculate the attribute value.
        - extensionKeyPath: The extension key path used to calculate the attribute value.
     */
    public convenience init<T: Entity, S: Entity> (
        _ name: String,
        from keyPath: KeyPath<T, Relationship<ToOne<S>>>,
        property extensionKeyPath: KeyPath<S, Attribute<PropertyType>>)
    {
        self.init(name, from: "\(keyPath.propertyName).\(extensionKeyPath.propertyName)")
    }

    /**
     Initializes a derived attribute with a name and a derivation closure.

     - Parameters:
        - name: The name of the attribute.
        - derivation: The closure used to calculate the attribute value.
     */
    internal init(name: String, derivation: @autoclosure @escaping () -> NSExpression) {
        self.name = name
        self.defaultValue = .null
        self.expressionBlock = derivation
    }

    /**
     Creates an `NSDerivedAttributeDescription` for the derived attribute.

     - Returns: An `NSDerivedAttributeDescription` for the derived attribute.
     */
    public func createPropertyDescription() -> NSDerivedAttributeDescription {
        let description = NSDerivedAttributeDescription()
        description.name = name
        description.attributeType = attributeType
        description.derivationExpression = expression
        return description
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension DerivedAttribute where PropertyType == StringAttributeType {
    /**
     Initializes a derived string attribute with a name, a key path, and a mapping.

     - Parameters:
        - name: The name of the attribute.
        - keyPath: The key path used to calculate the attribute value.
        - mapping: The mapping used to calculate the attribute value.
     */
    public convenience init<T: Entity, S: AttributeProtocol>(
        _ name: String,
        from keyPath: KeyPath<T, S>,
        mapping: DerivedStringMapping)
    where
        S.ManagedValue == String?
    {
        self.init(
            name: name,
            derivation: .stringMapping(propertyName: keyPath.propertyName, mapping: mapping))
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension DerivedAttribute where PropertyType == DateAttributeType {
    /**
     Initializes a derived date attribute with a name.

     - Parameters:
        - name: The name of the attribute.
     */
    public convenience init(_ name: String) {
        self.init(name: name, derivation: .dateNow())
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension DerivedAttribute where PropertyType: IntAttributeType {
    /**
     Initializes a derived integer attribute with a name, a key path, and an aggregation.

     - Parameters:
        - name: The name of the attribute.
        - keyPath: The key path used to calculate the attribute value.
        - aggregation: The aggregation used to calculate the attribute value.
     */
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
