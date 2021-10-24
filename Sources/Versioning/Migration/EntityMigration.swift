//
//  EntityMigration.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public typealias EntityMigrationCallback = ([String: NSEntityDescription]) throws -> Void

public protocol EntityMigration {
    var originEntityName: String? { get }
    var name: String? { get }

    func migrateEntity(
        _ entity: NSEntityDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSEntityDescription?

    func createEntityMapping(
        from sourceEntity: NSEntityDescription?,
        to destinationEntity: NSEntityDescription?) throws -> NSEntityMapping
}

public struct AddEntity: EntityMigration {
    public let name: String?
    public let parent: String?
    public let isAbstract: Bool
    public let properties: [AddPropertyMigration]

    public var originEntityName: String? { nil }

    public init(
        _ name: String,
        parent: String? = nil,
        isAbstract: Bool = false,
        properties: [AddPropertyMigration]
    ) {
        self.name = name
        self.parent = parent
        self.isAbstract = isAbstract
        self.properties = properties
    }

    public init(
        _ name: String,
        parent: String? = nil,
        isAbstract: Bool = false,
        @CollectionBuilder<AddPropertyMigration>
        properties: () -> [AddPropertyMigration]
    ) {
        self.name = name
        self.parent = parent
        self.isAbstract = isAbstract
        self.properties = properties()
    }

    internal init(
        _ name: String,
        parent: String? = nil,
        isAbstract: Bool = false
    ) {
        self.name = name
        self.parent = parent
        self.isAbstract = isAbstract
        self.properties = []
    }

    public func migrateEntity(
        _ entity: NSEntityDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSEntityDescription?
    {
        let entityDescription = NSEntityDescription()
        entityDescription.isAbstract = isAbstract
        entityDescription.name = name
        entityDescription.properties = properties
            .map { $0.createProperty(callbackStore: &callbackStore) }
        if let parent = parent {
            callbackStore.append {
                guard let parentEntityDescription = $0[parent] else { return }
                parentEntityDescription.subentities.append(entityDescription)
            }
        }
        return entityDescription
    }

    public func createEntityMapping(
        from sourceEntity: NSEntityDescription?,
        to destinationEntity: NSEntityDescription?) -> NSEntityMapping
    {
        let entityMapping = NSEntityMapping()
        entityMapping.mappingType = .addEntityMappingType
        entityMapping.destinationEntityName = name
        entityMapping.destinationEntityVersionHash = destinationEntity?.versionHash
        entityMapping.name = "CEM_Add_\(name!)"
        return entityMapping
    }
}

public struct RemoveEntity: EntityMigration {

    public let originEntityName: String?
    public let name: String? = nil

    public init(_ name: String) {
        self.originEntityName = name
    }

    public func migrateEntity(
        _ entity: NSEntityDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSEntityDescription?
    {
        return nil
    }

    public func createEntityMapping(
        from sourceEntity: NSEntityDescription?,
        to destinationEntity: NSEntityDescription?) -> NSEntityMapping
    {
        let entityMapping = NSEntityMapping()
        entityMapping.sourceEntityName = sourceEntity?.name
        entityMapping.sourceEntityVersionHash = sourceEntity?.versionHash
        entityMapping.mappingType = .removeEntityMappingType
        entityMapping.name = "CEM_Remove_\(originEntityName!)"
        return entityMapping
    }
}

public struct CopyEntity: EntityMigration {
    public let originEntityName: String?
    public let name: String?

    public init(_ name: String) {
        self.originEntityName = name
        self.name = name
    }

    public func migrateEntity(
        _ entity: NSEntityDescription?,
        callbackStore: inout [EntityMigrationCallback]) -> NSEntityDescription?
    {
        return entity
    }

    public func createEntityMapping(
        from sourceEntity: NSEntityDescription?,
        to destinationEntity: NSEntityDescription?) throws -> NSEntityMapping
    {
        guard let sourceEntity = sourceEntity,
              let destinationEntity = destinationEntity
        else {
            throw MigrationModelingError
                .migrationTargetNotFound("neither sourceEntity nor destinationEntity should be nil")
        }
        return createEntityMapping(from: sourceEntity, to: destinationEntity)
    }

    @inlinable
    func createEntityMapping(
        from sourceEntity: NSEntityDescription,
        to destinationEntity: NSEntityDescription) -> NSEntityMapping
    {
        let entityMapping = NSEntityMapping()
        entityMapping.name = "CEM_Copy_\(destinationEntity.name!)"
        entityMapping.mappingType = .copyEntityMappingType
        entityMapping.sourceEntityName = destinationEntity.name
        entityMapping.destinationEntityName = destinationEntity.name
        entityMapping.sourceEntityVersionHash = destinationEntity.versionHash
        entityMapping.destinationEntityVersionHash = destinationEntity.versionHash
        entityMapping.sourceExpression = .allSource(name: destinationEntity.name!)
        entityMapping.attributeMappings = destinationEntity
            .attributesByName.keys.map(propertyMapping(forCopyingAttribute:))
        entityMapping.relationshipMappings = destinationEntity
            .relationshipsByName.keys.map(propertyMapping(forCopyingRelationship:))
        return entityMapping
    }

    @inlinable
    func propertyMapping(forCopyingAttribute name: String) -> NSPropertyMapping {
        let propertyMapping = NSPropertyMapping()
        propertyMapping.name = name
        propertyMapping.valueExpression = .attributeMapping(from: name)
        return propertyMapping
    }

    @inlinable
    func propertyMapping(forCopyingRelationship name: String) -> NSPropertyMapping {
        let propertyMapping = NSPropertyMapping()
        propertyMapping.name = name
        propertyMapping.valueExpression = .relationshipMapping(from: name, to: name)
        return propertyMapping
    }
}

public struct UpdateEntity: EntityMigration {
    public let originEntityName: String?
    public let name: String?

    public let parent: String?
    public let isAbstract: Bool?
    public let properties: [PropertyMigration]

    public init(
        _ originName: String,
        name: String? = nil,
        parent: String? = nil,
        isAbstract: Bool? = nil,
        properties: [PropertyMigration] = []
    ) {
        self.originEntityName = originName
        self.name = name
        self.parent = parent
        self.isAbstract = isAbstract
        self.properties = properties
    }

    public init(
        _ originName: String,
        name: String? = nil,
        parent: String? = nil,
        isAbstract: Bool? = nil,
        @CollectionBuilder<PropertyMigration>
        properties: () -> [PropertyMigration]
    ) {
        self.originEntityName = originName
        self.name = name
        self.parent = parent
        self.isAbstract = isAbstract
        self.properties = properties()
    }

    public func migrateEntity(
        _ entity: NSEntityDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSEntityDescription?
    {
        guard let entity = entity else {
            throw MigrationModelingError
                .migrationTargetNotFound("entity \(originEntityName.contentDescription) not found")
        }

        if let name = name {
            entity.name = name
        }
        if let isAbstract = isAbstract {
            entity.isAbstract = isAbstract
        }
        if let parent = parent {
            callbackStore.append {
                guard let parentDescription = $0[parent]
                else { return }
                parentDescription.subentities.append(entity)
            }
        }
        if properties.isEmpty == false {
            var propertiesByName = entity.propertiesByName
            for migration in properties {
                guard let propertyName = migration.originPropertyName
                else {
                    // Create property
                    if let property = try migration
                        .migrateProperty(nil, callbackStore: &callbackStore)
                    {
                        propertiesByName[property.name] = property
                    }
                    continue
                }

                if let property = try migration
                    .migrateProperty(
                        propertiesByName[propertyName],
                        callbackStore: &callbackStore)
                {
                    // Update property
                    propertiesByName[propertyName] = property
                } else {
                    // Remove property
                    propertiesByName.removeValue(forKey: propertyName)
                }
            }
            entity.properties = Array(propertiesByName.values)
        }

        return entity
    }

    public func createEntityMapping(
        from sourceEntity: NSEntityDescription?,
        to destinationEntity: NSEntityDescription?) throws -> NSEntityMapping
    {
        guard let sourceEntity = sourceEntity,
              let destinationEntity = destinationEntity
        else {
            throw MigrationModelingError.migrationTargetNotFound(
                "neither sourceEntity nor destinationEntity should be nil")
        }
        return try createEntityMapping(from: sourceEntity, to: destinationEntity)
    }

    func createEntityMapping(
        from sourceEntity: NSEntityDescription,
        to destinationEntity: NSEntityDescription) throws -> NSEntityMapping
    {
        let entityMapping = NSEntityMapping()
        entityMapping.name = "CEM_Transform_\(originEntityName!)"
        entityMapping.sourceEntityName = sourceEntity.name
        entityMapping.destinationEntityName = destinationEntity.name
        entityMapping.sourceEntityVersionHash = sourceEntity.versionHash
        entityMapping.destinationEntityVersionHash = destinationEntity.versionHash
        entityMapping.mappingType = .customEntityMappingType
        entityMapping.entityMigrationPolicyClassName = NSStringFromClass(CrushEntityMigrationPolicy.self)
        entityMapping.sourceExpression = .allSource(name: originEntityName!)
        var attributeMappings: [NSPropertyMapping] = []
        var relationshipMappings: [NSPropertyMapping] = []
        var sourcePropertiesByName = sourceEntity.propertiesByName
        var destinationPropertiesByName = destinationEntity.propertiesByName
        // Executing defined property migrations
        for property in properties {
            let sourceName = property.originPropertyName
            let destinationName = property.name ?? property.originPropertyName
            guard let mapping = try property.createPropertyMapping(
                from: sourceName == nil ? nil : sourcePropertiesByName.removeValue(forKey: sourceName!),
                to: destinationName == nil ? nil : destinationPropertiesByName.removeValue(forKey: destinationName!),
                of: sourceEntity) else { continue }
            switch property {
            case _ as AttributeMigration:
                attributeMappings.append(mapping)
            case _ as RelationshipMigration:
                relationshipMappings.append(mapping)
            default:
                throw MigrationModelingError.unknownMigrationType
            }
        }
        // Inferring property mapping for unprocessed properties
        for destinationProperty in destinationPropertiesByName.values {
            let propertyMapping = NSPropertyMapping()
            propertyMapping.name = destinationProperty.name
            switch destinationProperty {
            case let attribute as NSAttributeDescription:
                if sourcePropertiesByName[attribute.name] != nil {
                    propertyMapping.valueExpression = .attributeMapping(from: attribute.name)
                }
                attributeMappings.append(propertyMapping)
            case let relationship as NSRelationshipDescription:
                if let sourceProperty = sourcePropertiesByName[relationship.name] {
                    propertyMapping.valueExpression = .relationshipMapping(from: sourceProperty.name, to: relationship.name)
                }
                relationshipMappings.append(propertyMapping)
            default:
                throw MigrationModelingError.unknownDescriptionType
            }
        }
        entityMapping.attributeMappings = attributeMappings
        entityMapping.relationshipMappings = relationshipMappings
        return entityMapping
    }
}

class CrushEntityMigrationPolicy: NSEntityMigrationPolicy {
    @objc(performCustomAttributeMappingOfPropertyMapping:entityMapping:manager:sourceValue:)
    func performCustomAttributeMapping(of propertyMapping: NSPropertyMapping, entityMapping: NSEntityMapping, manager: NSMigrationManager, sourceValue: Any?) -> Any? {
        guard let mappingFuction = propertyMapping
                .userInfo?[UserInfoKey.attributeMappingFunc] as? (Any?) -> Any? else {
            return nil
        }
        let result: Any? = mappingFuction(sourceValue)
        return (result.isNil ? nil : result) ?? manager.destinationEntity(for: entityMapping)?.attributesByName[propertyMapping.name!]?.defaultValue
    }
}
