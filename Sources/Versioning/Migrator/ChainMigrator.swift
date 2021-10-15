//
//  ChainMigrator.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public enum ChainMigratorError: Error {
    case migrationChainIncompatibleWithDataModel
}

internal final class ChainMigrator: Migrator {
    internal let migrationChain: MigrationChain

    internal init(storage: ConcreteStorage, migrationChain: MigrationChain, dataModel: DataModel) {
        self.migrationChain = migrationChain
        super.init(storage: storage, dataModel: dataModel)
    }

    @discardableResult
    internal override func migrate() throws -> Bool {
        try validateMigrationChainAndDataModel(chain: migrationChain, model: dataModel)

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

    internal func validateMigrationChainAndDataModel(
        chain: MigrationChain, model: DataModel) throws
    {
        guard let managedObjectModel = try chain.managedObjectModels().last else {
            throw MigrationError.incompatible
        }
        if managedObjectModel.entityVersionHashesByName !=
            dataModel.managedObjectModel.entityVersionHashesByName
        {
            throw ChainMigratorError.migrationChainIncompatibleWithDataModel
        }
    }
}
