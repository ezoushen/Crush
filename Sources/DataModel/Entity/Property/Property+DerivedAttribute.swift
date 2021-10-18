//
//  Property+DerivedAttribute.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

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
public final class DerivedAttribute<F: FieldAttribute>: AttributeProtocol {
    public typealias Description = NSDerivedAttributeDescription
    public typealias PropertyValue = F.RuntimeObjectValue
    public typealias FieldConvertor = F

    public let defaultValue: PropertyValue
    public let name: String
    private let stringBlock: () -> String
    public private(set) lazy var expression: NSExpression? = NSExpression(format: stringBlock())

    public init<T: Entity>(
        _ name: String, from keyPath: KeyPath<T, Attribute<F>>)
    {
        self.stringBlock = { keyPath.propertyName }
        self.defaultValue = nil
        self.name = name
    }

    internal init(name: String, derivation: String) {
        self.stringBlock = { derivation }
        self.defaultValue = nil
        self.name = name
    }

    public func createDescription() -> NSDerivedAttributeDescription {
        let description = NSDerivedAttributeDescription()
        description.valueTransformerName = valueTransformerName
        description.name = name
        description.attributeType = attributeType
        description.derivationExpression = expression

        if let className = attributeValueClassName {
            description.attributeValueClassName = className
        }

        return description
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension DerivedAttribute where F == String {
    public convenience init<T: Entity, S: AttributeProtocol>(
        _ name: String,
        from keyPath: KeyPath<T, S>,
        mapping: DerivedStringMapping)
    where
        S.FieldConvertor == String
    {
        self.init(name: name, derivation: "\(mapping.rawValue)(\(keyPath.propertyName))")
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension DerivedAttribute where F == Date {
    public convenience init(_ name: String) {
        self.init(name: name, derivation: "now()")
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension DerivedAttribute where F: CoreDataInteger {
    public convenience init<T: Entity, S: RelationshipProtocol>(
        _ name: String,
        from keyPath: KeyPath<T, S>,
        aggregation: DerivedAggregation)
    where
        S.Mapping: ToManyRelationMappingProtocol
    {
        self.init(
            name: name,
            derivation: "\(keyPath.propertyName).@\(aggregation)")
    }
}

