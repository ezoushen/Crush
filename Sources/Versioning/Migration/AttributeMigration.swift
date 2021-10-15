//
//  AttributeMigration.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public protocol AttributeMigration: PropertyMigration {
    func migrateAttribute(
        _ attribute: NSAttributeDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSAttributeDescription?
}

extension AttributeMigration {
    public func migrateProperty(
        _ property: NSPropertyDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSPropertyDescription?
    {
        guard property == nil || property is NSAttributeDescription else {
            throw MigrationModelingError.internalTypeMismatch
        }
        return try migrateAttribute(
            property as? NSAttributeDescription,
            callbackStore: &callbackStore)
    }
}

public struct AddAttribute: AttributeMigration, AddPropertyMigration {
    public let originPropertyName: String? = nil

    public let name: String?
    public let isOptional: Bool
    public let isTransient: Bool
    public let attributeType: NSAttributeType

    public init<T: FieldAttribute>(
        _ name: String,
        type attributeType: T.Type,
        isOptional: Bool = false,
        isTransient: Bool = false
    ) {
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = attributeType.nativeType
    }

    public init(
        _ name: String,
        attributeType: NSAttributeType,
        isOptional: Bool,
        isTransient: Bool)
    {
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = attributeType
    }

    public func createProperty(
        callbackStore: inout [EntityMigrationCallback]) -> NSPropertyDescription
    {
        let description = NSAttributeDescription()
        description.name = name!
        description.isOptional = isOptional
        description.isTransient = isTransient
        description.attributeType = attributeType
        return description
    }

    public func createPropertyMapping(
        from sourceProperty: NSPropertyDescription?,
        to destinationProperty: NSPropertyDescription?,
        of sourceEntity: NSEntityDescription) -> NSPropertyMapping?
    {
        let propertyMapping = NSPropertyMapping()
        propertyMapping.name = destinationProperty?.name
        return propertyMapping
    }
}

public typealias RemoveAttribute = RemoveProperty

public struct UpdateAttribute: AttributeMigration {

    public let originPropertyName: String?
    public let originKeyPath: String

    public let name: String?
    public let isOptional: Bool?
    public let isTransient: Bool?
    public let attributeType: NSAttributeType?

    public init<T: FieldAttribute>(
        _ originName: String,
        name: String? = nil,
        type attributeType: T.Type,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = attributeType.nativeType
    }

    public init(
        _ originName: String,
        name: String? = nil,
        type attributeType: NSAttributeType,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = attributeType
    }

    public init(
        _ originName: String,
        name: String? = nil,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = nil
    }

    public func migrateAttribute(
        _ attribute: NSAttributeDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSAttributeDescription?
    {
        guard let attribute = attribute else {
            throw MigrationModelingError
                .migrationTargetNotFound(
                    "attribute \(originPropertyName.contentDescription) not found")
        }
        if let name = name {
            attribute.name = name
        }
        if let isOptional = isOptional {
            attribute.isOptional = isOptional
        }
        if let isTransient = isTransient {
            attribute.isTransient = isTransient
        }
        if let attributeType = attributeType {
            attribute.attributeType = attributeType
        }
        return attribute
    }

    public func createPropertyMapping(
        from sourceProperty: NSPropertyDescription?,
        to destinationProperty: NSPropertyDescription?,
        of sourceEntity: NSEntityDescription) throws -> NSPropertyMapping?
    {
        guard let _ = sourceProperty,
              let destinationProperty = destinationProperty else {
                  throw MigrationModelingError.migrationTargetNotFound(
                    "sourceProperty or destinationProperty should not be nil")
              }
        let propertyMapping = NSPropertyMapping()
        propertyMapping.name = destinationProperty.name
        propertyMapping.valueExpression = .attributeMapping(from: originKeyPath)
        return propertyMapping
    }
}
