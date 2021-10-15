//
//  Version.swift
//
//
//  Created by ezou on 2021/10/12.
//

import CoreData
import Foundation

public struct ModelMigration {
    public let name: String
    public let entityMigrations: [EntityMigration]

    public init(_ name: String, entityMigrations: [EntityMigration]) {
        self.name = name
        self.entityMigrations = entityMigrations
    }

    public init(
        _ name: String,
        @EntityMigrationBuilder entityMigrations: () -> [EntityMigration])
    {
        self.name = name
        self.entityMigrations = entityMigrations()
    }

    public func createMappingModel(
        from sourceModel: NSManagedObjectModel,
        to destinationModel: NSManagedObjectModel) throws -> NSMappingModel
    {
        let mappingModel = NSMappingModel()
        var sourceEntitiesByName = sourceModel.entitiesByName
        var destinationEntitiesByName = destinationModel.entitiesByName
        // Executing defined entity migrations
        var entityMappings: [NSEntityMapping] = []
        for migration in entityMigrations {
            let source: NSEntityDescription? = {
                guard let sourceName = migration.originEntityName else { return nil }
                defer { sourceEntitiesByName.removeValue(forKey: sourceName) }
                return sourceEntitiesByName[sourceName]
            }()
            let destination: NSEntityDescription? = {
                guard let name = migration.name ?? migration.originEntityName else { return nil }
                defer { destinationEntitiesByName.removeValue(forKey: name) }
                return destinationEntitiesByName[name]
            }()
            entityMappings.append(try migration
                .createEntityMapping(from: source, to: destination))
        }
        // Inferring entity mapping for unprocessed entities
        for destinationEntity in destinationEntitiesByName.values {
            guard let sourceEntity = sourceEntitiesByName[destinationEntity.name!]
            else {
                let entityMigration = AddEntity(destinationEntity.name!)
                entityMappings.append(entityMigration
                    .createEntityMapping(from: nil, to: destinationEntity))
                continue
            }
            let isCopy = sourceEntity.versionHash == destinationEntity.versionHash
            let entityMigration: EntityMigration = isCopy
                ? CopyEntity(destinationEntity.name!)
                : UpdateEntity(destinationEntity.name!)
            entityMappings.append(try entityMigration
                .createEntityMapping(from: sourceEntity, to: destinationEntity))
        }
        mappingModel.entityMappings = entityMappings
        return mappingModel
    }

    public func migrateModel(
        _ model: NSManagedObjectModel) throws -> NSManagedObjectModel
    {
        let newModel = NSManagedObjectModel()
        var entitiesByName = deepCopyEntitiesByName(model.entities)
        var callbackStore: [EntityMigrationCallback] = []
        // Executing migration
        for migration in entityMigrations {
            guard let entityName = migration.originEntityName
            else {
                if let description = try migration
                    .migrateEntity(nil, callbackStore: &callbackStore),
                   let name = description.name
                {
                    entitiesByName[name] = description
                }
                continue
            }
            if let migratedDescription = try migration
                .migrateEntity(entitiesByName[entityName], callbackStore: &callbackStore)
            {
                entitiesByName[entityName] = migratedDescription
            } else {
                entitiesByName.removeValue(forKey: entityName)
            }
        }

        for callback in callbackStore {
            try callback(entitiesByName)
        }

        newModel.entities = Array(entitiesByName.values)

        return newModel
    }

    @inline(__always)
    private func deepCopyEntitiesByName(
        _ entities: [NSEntityDescription]) -> [String: NSEntityDescription]
    {
        var subentityNamesByName: [String: [String]] = [:]
        var clonedEntitiesByName: [String: NSEntityDescription] = [:]
        clonedEntitiesByName.reserveCapacity(entities.capacity)
        // Shallow cloning
        for description in entities {
            guard let name = description.name else { continue }
            let cloned = description.copy() as! NSEntityDescription
            subentityNamesByName[name] = cloned.subentities.compactMap { $0.name }
            clonedEntitiesByName[name] = cloned
        }
        // Cloning children
        for (parentName, childrenNames) in subentityNamesByName {
            guard let description = clonedEntitiesByName[parentName],
                    !description.subentities.isEmpty else { continue }
            description.subentities = childrenNames
                .compactMap { clonedEntitiesByName[$0] }
        }

        return clonedEntitiesByName
    }
}
