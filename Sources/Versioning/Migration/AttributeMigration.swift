//
//  AttributeMigration.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public protocol AttributeMigration: PropertyMigration {
    var defaultValue: Any? { get set }

    func migrateAttribute(
        _ attribute: NSAttributeDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSAttributeDescription?
}

extension AttributeMigration {
    public func `default`(_ value: Any?) -> Self {
        var migration = self
        migration.defaultValue = value
        return migration
    }

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
    // isTransient will be ignoed if derivedExpression is defined
    public let isTransient: Bool
    public let derivedExpression: NSExpression?
    public let attributeType: NSAttributeType
    public var hashModifier: String? = nil
    
    /// Static default value
    public var defaultValue: Any?
    /// Dynamic default value for existing objects
    public var defaultValueBlock: ((NSManagedObject) -> Any?)?
    
    /// Compute default value for existing object regardless static default value
    /// - parameter block: A closure returning computed default value for existing object
    public func valueForExistingObject(_ block: @escaping (NSManagedObject) -> Any?) -> AddAttribute
    {
        var newAttribute = self
        newAttribute.defaultValueBlock = { block($0) }
        return newAttribute
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    public init<T: AttributeType>(
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
    
    public init<T: AttributeType>(
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
        if #available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *),
            let derivedExpression = derivedExpression
        {
            let description = NSDerivedAttributeDescription()
            description.versionHashModifier = hashModifier
            description.name = name!
            description.isOptional = isOptional
            description.derivationExpression = derivedExpression
            return description
        }
        let description = NSAttributeDescription()
        description.versionHashModifier = hashModifier
        description.name = name!
        description.isOptional = isOptional
        description.isTransient = isTransient
        description.attributeType = attributeType
        description.defaultValue = defaultValue
        return description
    }

    public func createPropertyMapping(
        from sourceProperty: NSPropertyDescription?,
        to destinationProperty: NSPropertyDescription?,
        of sourceEntity: NSEntityDescription) -> NSPropertyMapping?
    {
        let propertyMapping = NSPropertyMapping()
        propertyMapping.name = name
        if let defaultValueBlock = defaultValueBlock {
            var userInfo = propertyMapping.userInfo ?? [:]
            userInfo[UserInfoKey.defaultValueFunc] = defaultValueBlock
            propertyMapping.userInfo = userInfo
            propertyMapping.valueExpression = .addAttribute(name: name!, customValue: true)
        } else {
            propertyMapping.valueExpression = .addAttribute(name: name!, customValue: false)
        }
        return propertyMapping
    }
}

public typealias RemoveAttribute = RemoveProperty

public struct UpdateAttribute: AttributeMigration, UpdatePropertyMigration {

    public let originPropertyName: String?
    public let originKeyPath: String

    public let name: String?
    public let isOptional: Bool?
    public let isTransient: Bool?
    public let attributeType: NSAttributeType?
    public let transform: ((Any?) -> Any?)?
    public let objectTransform: ((NSManagedObject) -> Any?)?
    public let derivedExpression: NSExpression?

    public var defaultValue: Any?
    public var hashModifier: String? = nil
    public var hashModifierUpdated: Bool = false
    
    public init(
        _ originName: String,
        name: String? = nil,
        isOptional: Bool? = nil,
        derivedExpression: NSExpression
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = false
        self.attributeType = nil
        self.transform = nil
        self.objectTransform = nil
        self.derivedExpression = derivedExpression
    }

    public init<T: AttributeType>(
        _ originName: String,
        name: String? = nil,
        type attributeType: T.Type,
        isOptional: Bool? = nil,
        derivedExpression: NSExpression,
        transform: @escaping (Any?) -> T.ManagedValue = { _ in .null }
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = false
        self.attributeType = attributeType.nativeType
        self.transform = { transform($0) }
        self.derivedExpression = derivedExpression
        self.objectTransform = nil
    }

    public init(
        _ originName: String,
        name: String? = nil,
        type attributeType: NSAttributeType,
        isOptional: Bool? = nil,
        derivedExpression: NSExpression,
        transform: @escaping (Any?) -> Any? = { _ in nil }
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = false
        self.attributeType = attributeType
        self.transform = transform
        self.derivedExpression = derivedExpression
        self.objectTransform = nil
    }

    public init<T: AttributeType>(
        _ originName: String,
        name: String? = nil,
        type attributeType: T.Type,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil,
        transform: @escaping (Any?) -> T.ManagedValue = { _ in .null }
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = attributeType.nativeType
        self.transform = { transform($0) }
        self.objectTransform = nil
        self.derivedExpression = nil
    }

    public init(
        _ originName: String,
        name: String? = nil,
        type attributeType: NSAttributeType,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil,
        transform: @escaping (Any?) -> Any? = { _ in nil }
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = attributeType
        self.transform = transform
        self.objectTransform = nil
        self.derivedExpression = nil
    }
    
    public init<T: AttributeType>(
        _ originName: String,
        name: String? = nil,
        type attributeType: T.Type,
        isOptional: Bool? = nil,
        derivedExpression: NSExpression,
        objectTransform: @escaping (NSManagedObject) -> T.ManagedValue = { _ in .null }
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = false
        self.attributeType = attributeType.nativeType
        self.transform = nil
        self.derivedExpression = derivedExpression
        self.objectTransform = { objectTransform($0) }
    }

    public init(
        _ originName: String,
        name: String? = nil,
        type attributeType: NSAttributeType,
        isOptional: Bool? = nil,
        derivedExpression: NSExpression,
        objectTransform: @escaping (NSManagedObject) -> Any? = { _ in nil }
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = false
        self.attributeType = attributeType
        self.transform = nil
        self.derivedExpression = derivedExpression
        self.objectTransform = objectTransform
    }

    public init<T: AttributeType>(
        _ originName: String,
        name: String? = nil,
        type attributeType: T.Type,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil,
        objectTransform: @escaping (NSManagedObject) -> T.ManagedValue = { _ in .null }
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = attributeType.nativeType
        self.objectTransform = { objectTransform($0) }
        self.transform = nil
        self.derivedExpression = nil
    }

    public init(
        _ originName: String,
        name: String? = nil,
        type attributeType: NSAttributeType,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil,
        objectTransform: @escaping (NSManagedObject) -> Any? = { _ in nil }
    ) {
        self.originPropertyName = String(originName.split(separator: ".")[0])
        self.originKeyPath = originName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.attributeType = attributeType
        self.transform = nil
        self.objectTransform = objectTransform
        self.derivedExpression = nil
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
        self.objectTransform = nil
        self.derivedExpression = nil
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
        
        var description: NSAttributeDescription
        
        if #available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *),
           let expression = derivedExpression {
            let derivedDescription = NSDerivedAttributeDescription()
            derivedDescription.derivationExpression = expression
            description = derivedDescription
        } else {
            description = NSAttributeDescription()

            if let defaultValue = defaultValue {
                description.defaultValue = defaultValue
            } else {
                description.defaultValue = attribute.defaultValue
            }

            if let isTransient = isTransient {
                description.isTransient = isTransient
            } else {
                description.isTransient = attribute.isTransient
            }
        }
        
        if let name = name {
            description.name = name
        } else {
            description.name = attribute.name
        }
        
        if let isOptional = isOptional {
            description.isOptional = isOptional
        } else {
            description.isOptional = attribute.isOptional
        }
        
        if let attributeType = attributeType {
            description.attributeType = attributeType
        } else {
            description.attributeType = attribute.attributeType
        }

        if hashModifierUpdated {
            description.versionHashModifier = hashModifier
        } else {
            description.versionHashModifier = attribute.versionHashModifier
        }
        
        return description
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
        
        if let objectTransform = objectTransform {
            var userInfo = propertyMapping.userInfo ?? [:]
            userInfo[UserInfoKey.attributeMappingFromObjectFunc] = objectTransform
            propertyMapping.userInfo = userInfo
            propertyMapping.valueExpression = .customAttributeMapping(objectTransform)
        } else if let transform = transform {
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
