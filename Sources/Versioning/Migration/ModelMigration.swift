//
//  Version.swift
//
//
//  Created by ezou on 2021/10/12.
//

import CoreData
import Foundation

/// It defined how will entities change within a model migration
///
/// There're four kinds of ``EntityMigration`` can use including ``AddEntity``, ``RemoveEntity``,
/// ``UpdateEntity``, and ``CopyEntity``.
public struct ModelMigration: Hashable {

    public let name: String
    public let entityMigrations: [EntityMigration]

    /// Create instance of `ModelMigration`
    ///
    /// Example:
    ///
    /// ```swift
    /// ModelMigration("name", entityMigrations: [
    ///     AddEntity("Entity") { ... },
    ///     RemoveEntity("ObsoleteEntity"),
    ///     .
    ///     .
    /// ])
    /// ```
    /// - Parameters:
    ///   - name: The name of the migration.
    ///   - entityMigrations: Total changes over all entities.
    public init(_ name: String, entityMigrations: [EntityMigration]) {
        self.name = name
        self.entityMigrations = entityMigrations
    }

    /// Create instance of `ModelMigration`
    ///
    /// Example:
    ///
    /// ```swift
    /// ModelMigration("name") {
    ///     AddEntity("Entity") { ... }
    ///     RemoveEntity("ObsoleteEntity")
    ///     .
    ///     .
    /// }
    /// ```
    /// - Parameters:
    ///   - name: The name of the migration.
    ///   - entityMigrations: Total changes over all entities.
    public init(
        _ name: String,
        @CollectionBuilder<EntityMigration>
        entityMigrations: () -> [EntityMigration])
    {
        self.name = name
        self.entityMigrations = entityMigrations()
    }
    
    public static func == (
        lhs: ModelMigration, rhs: ModelMigration) -> Bool
    {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    /// Create `NSMappingModel` based on ``entityMigrations`` and also provided `sourceModel` and `destinationModel`
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

    /// Update the entities of the model based on ``entityMigrations``
    public func migrateModel(
        _ model: NSManagedObjectModel) throws -> NSManagedObjectModel
    {
        let newModel = NSManagedObjectModel()
        var configurationsByEntityName = model.configurations
            .reduce(into: [String: Set<String>]()) {
                guard let entities = model.entities(forConfigurationName: $1)
                else { return }
                for entity in entities {
                    var set = $0[$1] ?? []
                    set.insert(entity.name!)
                    $0[$1] = set
                }
            }
        var entitiesByName = deepCopyEntitiesByName(model.entities)
        var callbackStore: [EntityMigrationCallback] = []
        // Executing migration
        for migration in entityMigrations {
            guard let entityName = migration.originEntityName
            else {
                /// Add entity
                if let description = try migration
                    .migrateEntity(nil, callbackStore: &callbackStore),
                   let name = description.name
                {
                    entitiesByName[name] = description
                    if let configurations = migration.configurations {
                        configurationsByEntityName[name] = Set(configurations)
                    }
                }
                continue
            }
            if let migratedDescription = try migration
                .migrateEntity(entitiesByName[entityName], callbackStore: &callbackStore)
            {
                entitiesByName[entityName] = migratedDescription

                let originalConfigurations = configurationsByEntityName
                    .removeValue(forKey: entityName)
                if let configuratios = migration.configurations {
                    configurationsByEntityName[migratedDescription.name!] = Set(configuratios)
                } else {
                    configurationsByEntityName[migratedDescription.name!] = originalConfigurations
                }
            } else {
                /// Will return nil only while removing entity
                entitiesByName.removeValue(forKey: entityName)
            }
        }

        for callback in callbackStore {
            try callback(entitiesByName)
        }

        newModel.entities = Array(entitiesByName.values)

        let descriptionsByConfiguration = newModel.entities
            .reduce(into: [String: [NSEntityDescription]]())
        {
            guard let name = $1.name,
                  let configurations = configurationsByEntityName[name] else { return }
            for configuration in configurations {
                var set = $0[configuration] ?? []
                set.append($1)
                $0[configuration] = set
            }
        }

        for (name, entities) in descriptionsByConfiguration {
            newModel.setEntities(entities, forConfigurationName: name)
        }

        return newModel
    }

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
