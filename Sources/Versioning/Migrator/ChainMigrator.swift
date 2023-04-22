//
//  ChainMigrator.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

internal final class ChainMigrator: Migrator {
    internal let migrationChain: MigrationChain

    internal init(storage: ConcreteStorage, migrationChain: MigrationChain, dataModel: DataModel) {
        self.migrationChain = migrationChain
        super.init(storage: storage, dataModel: dataModel)
    }

    @discardableResult
    internal override func migrate() throws -> Bool {
        guard var currentManagedObjectModel =
                try findCompatibleModel(in: migrationChain)
        else {
            throw MigrationError.incompatible
        }
        let iterator = MigrationChainIterator(migrationChain)
        iterator.setActiveVersion(
            managedObjectModel: currentManagedObjectModel)

        while let node = iterator.next() {
            try migrateStore(
                name: node.name,
                from: currentManagedObjectModel,
                to: node.destinationManagedObjectModel,
                mappingModel: node.mappingModel)

            currentManagedObjectModel = node.destinationManagedObjectModel
        }

        return true
    }

    internal func findCompatibleModel(in chain: MigrationChain) throws -> NSManagedObjectModel? {
        try chain.managedObjectModels().first(where: isStoreCompatible(with:))
    }

    internal func isStoreCompatible(
        with managedObjectModel: NSManagedObjectModel) throws -> Bool
    {
        let metadata = try NSPersistentStoreCoordinator
            .metadataForPersistentStore(ofType: storage.storeType, at: storage.storageUrl)
        return managedObjectModel.isConfiguration(
            withName: storage.configuration, compatibleWithStoreMetadata: metadata)
    }
}

public struct ChainMigratorIncompatibleModelError: Error {
    public let incrementalModel: NSManagedObjectModel
    public let targetModel: NSManagedObjectModel
}

extension ChainMigratorIncompatibleModelError: CustomStringConvertible {
    public enum DiffType: Equatable {
        case add, remove, incompatible
        case modifier(from: AnyHashable?, to: AnyHashable?)
        case incompatibleAndModifier(from: AnyHashable?, to: AnyHashable?)
    }

    public struct ModelDiff: Equatable, CustomStringConvertible {
        public let diff: DiffType
        public let entityDiff: [EntityDiff]

        init(incrementalModel: NSManagedObjectModel, targetModel: NSManagedObjectModel) {
            let incrementalModelEntitiesByName = incrementalModel.entitiesByName
            let targetModelEntitiesByName = targetModel.entitiesByName
            let increamentalEntityNames = Set(incrementalModelEntitiesByName.keys)
            let targetEntityNames = Set(targetModelEntitiesByName.keys)
            let addedEntityDiffs = targetEntityNames.subtracting(increamentalEntityNames)
                .compactMap { targetModelEntitiesByName[$0] }
                .map { EntityDiff.added(description: $0) }
            let removedEntityDiffs = increamentalEntityNames.subtracting(targetEntityNames)
                .compactMap { incrementalModelEntitiesByName[$0] }
                .map { EntityDiff.removed(description: $0) }
            let incompatibleEntityDiffs = increamentalEntityNames.intersection(targetEntityNames)
                .compactMap { name -> EntityDiff? in
                    guard let incrementalEntity = incrementalModelEntitiesByName[name],
                          let targetEntity = targetModelEntitiesByName[name],
                          incrementalEntity.versionHash != targetEntity.versionHash
                    else { return nil }
                    return .incompatible(from: incrementalEntity, to: targetEntity)
                }
            let diffs = addedEntityDiffs + removedEntityDiffs + incompatibleEntityDiffs
            self.entityDiff = diffs
            self.diff = incrementalModel.versionIdentifiers != targetModel.versionIdentifiers
                ? diffs.isEmpty
                    ? .modifier(
                        from: incrementalModel.versionIdentifiers,
                        to: targetModel.versionIdentifiers)
                    : .incompatibleAndModifier(
                        from: incrementalModel.versionIdentifiers,
                        to: targetModel.versionIdentifiers)
                : .incompatible
        }

        public var description: String {
            switch diff {
            case .add, .remove:
                return "Migration chain is incompatible with data model, but failed to resolve error messages. Possible entity diffs: \(entityDiffDescription)"
            case .incompatible:
                return "Migration chain is incompatible with data model, resolved entity diffs: \(entityDiffDescription)"
            case let .modifier(from, to):
                return "Migration chain is incompatible with data model, model version modifier has been changed from \(String(describing: from)) to \(String(describing: to))"
            case let .incompatibleAndModifier(from, to):
                return "Migration chain is incompatible with data model,and version modifier has been changed from \(String(describing: from)) to \(String(describing: to)). Resolved entity diffs: \(entityDiffDescription)"
            }
        }

        private var entityDiffDescription: String {
            "[\n\t\(entityDiff.map(\.description).joined(separator: "\n\t"))\n]"
        }
    }

    public struct EntityDiff: Equatable, CustomStringConvertible {
        public let name: String
        public let diff: DiffType
        public let propertyDiffs: [PropertyDiff]

        static func added(description: NSEntityDescription) -> EntityDiff {
            EntityDiff(name: description.name!, diff: .add, propertyDiffs: [])
        }

        static func removed(description: NSEntityDescription) -> EntityDiff {
            EntityDiff(name: description.name!, diff: .remove, propertyDiffs: [])
        }

        static func incompatible(from: NSEntityDescription, to: NSEntityDescription) -> EntityDiff {
            let fromPropertiesByName = from.propertiesByName
            let fromPropertyNames = Set(fromPropertiesByName.keys)
            let toPropertiesByName = to.propertiesByName
            let toPropertyNames = Set(toPropertiesByName.keys)
            let addedPropertyDiff: [PropertyDiff] = toPropertyNames
                .subtracting(fromPropertyNames)
                .compactMap { toPropertiesByName[$0] }
                .map { .added(description: $0) }
            let removedPropertyDiff: [PropertyDiff] = fromPropertyNames
                .subtracting(toPropertyNames)
                .compactMap { fromPropertiesByName[$0] }
                .map { .removed(description: $0) }
            let incompatiblePropertyDiffs: [PropertyDiff] = fromPropertyNames
                .intersection(toPropertyNames)
                .compactMap {
                    guard let fromProperty = fromPropertiesByName[$0],
                          let toProperty = toPropertiesByName[$0],
                          fromProperty.versionHash != toProperty.versionHash
                    else { return nil }
                    return .incompatible(from: fromProperty, to: toProperty)
                }
            let diffs = addedPropertyDiff + removedPropertyDiff + incompatiblePropertyDiffs
            return EntityDiff(
                name: from.name!,
                diff: from.versionHashModifier != to.versionHashModifier
                    ? diffs.isEmpty
                        ? .modifier(from: from.versionHashModifier, to: to.versionHashModifier)
                        : .incompatibleAndModifier(
                            from: from.versionHashModifier, to: to.versionHashModifier)
                    : .incompatible,
                propertyDiffs: diffs)
        }

        public var description: String {
            switch diff {
            case .add:
                return "Entity \"\(name)\" is added in the target model"
            case .remove:
                return "Entity \"\(name)\" is removed in the target model"
            case .incompatible:
                return "Entity \"\(name)\" is incompatible, resolved property diffs: \(propertyDiffsDescription)"
            default:
                return "Entity \"\(name)\" is incompatible but failed to resolve error messages. Possible property diffs: \(propertyDiffsDescription)"
            }
        }

        private var propertyDiffsDescription: String {
            "[\n\t\t\(propertyDiffs.map(\.description).joined(separator: ",\n\t\t"))\n\t]"
        }
    }

    public struct PropertyDiff: Equatable, CustomStringConvertible {
        public let name: String
        public let diff: DiffType
        public let from: NSPropertyDescription?
        public let to: NSPropertyDescription?

        static func added(description: NSPropertyDescription) -> PropertyDiff {
            PropertyDiff(
                name: description.name, diff: .add, from: nil, to: description)
        }

        static func removed(description: NSPropertyDescription) -> PropertyDiff {
            PropertyDiff(
                name: description.name, diff: .remove, from: description, to: nil)
        }

        static func incompatible(from: NSPropertyDescription, to: NSPropertyDescription) -> PropertyDiff {
            PropertyDiff(name: from.name, diff: .incompatible, from: from, to: to)
        }

        public var description: String {
            switch diff {
            case .add:
                return "Property \"\(name)\" is added in the target model"
            case .remove:
                return "Property \"\(name)\" is removed in the target model"
            case .incompatible:
                return "Property \"\(name)\" is incompatible, from: \(String(describing: from).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")), to: \(String(describing: to).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: ""))"
            default:
                return "Property \"\(name)\" is incompatible but failed to resolve error messages. From: \(String(describing: from).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")), to: \(String(describing: to).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: ""))"
            }
        }
    }

    public var description: String {
        ModelDiff(incrementalModel: incrementalModel, targetModel: targetModel).description
    }
}
