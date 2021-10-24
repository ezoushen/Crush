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
    // isTransient will be ignoed if derivedExpression is not nil
    public let isTransient: Bool
    public let derivedExpression: NSExpression?
    public let attributeType: NSAttributeType

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    public init<T: FieldAttribute>(
        _ name: String,
        type attributeType: T.Type,
        isOptional: Bool = true,
        derivedExpression: NSExpression
    ) {
        self.name = name
        self.isOptional = isOptional
        self.isTransient = false
        self.derivedExpression = derivedExpression
        self.attributeType = attributeType.nativeType
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    public init(
        _ name: String,
        attributeType: NSAttributeType,
        isOptional: Bool = true,
        derivedExpression: NSExpression
    ) {
        self.name = name
        self.isOptional = isOptional
        self.isTransient = false
        self.derivedExpression = derivedExpression
        self.attributeType = attributeType
    }
    
    public init<T: FieldAttribute>(
        _ name: String,
        type attributeType: T.Type,
        isOptional: Bool = true,
        isTransient: Bool = false
    ) {
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.derivedExpression = nil
        self.attributeType = attributeType.nativeType
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    public init(
        _ name: String,
        attributeType: NSAttributeType,
        isOptional: Bool = true,
        isTransient: Bool = false
    ) {
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.derivedExpression = nil
        self.attributeType = attributeType
    }

    public func createProperty(
        callbackStore: inout [EntityMigrationCallback]) -> NSPropertyDescription
    {
        if #available(iOS 13.0, watchOS 6.0, macOS 10.15, *),
            let derivedExpression = derivedExpression
        {
            let description = NSDerivedAttributeDescription()
            description.name = name!
            description.isOptional = isOptional
            description.derivationExpression = derivedExpression
            return description
        }
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
        propertyMapping.name = name
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
    public let transform: ((Any?) -> Any?)?

    public init<T: FieldAttribute>(
        _ originName: String,
        name: String? = nil,
        type attributeType: T.Type,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil,
        transform: @escaping (Any?) -> T.ManagedObjectValue
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = attributeType.nativeType
        self.transform = { transform($0) }
    }

    public init(
        _ originName: String,
        name: String? = nil,
        type attributeType: NSAttributeType,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil,
        transform: @escaping (Any?) -> Any?
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = attributeType
        self.transform = transform
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
        self.transform = nil
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
        
        if let transform = transform {
            var userInfo = propertyMapping.userInfo ?? [:]
            userInfo[UserInfoKey.attributeMappingFunc] = transform
            propertyMapping.userInfo = userInfo
            propertyMapping.valueExpression = .customAttributeMapping(from: originKeyPath)
        } else {
            propertyMapping.valueExpression = .attributeMapping(from: originKeyPath)
        }
        return propertyMapping
    }
}
