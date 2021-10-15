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
    case noAvailableMigration
}

internal final class ChainMigrator: Migrator {
    internal let migrationChain: MigrationChain

    internal init(storage: ConcreteStorage, migrationChain: MigrationChain, dataModel: DataModel) {
        self.migrationChain = migrationChain
        super.init(storage: storage, dataModel: dataModel)
    }

    internal override func migrate() throws {
        if try isStoreCompatible(with: dataModel.managedObjectModel) {
            return // No need to migrate data
        }

        try validateMigrationChainAndDataModel(chain: migrationChain, model: dataModel)

        guard var currentManagedObjectModel =
                try findCompatibleModel(in: migrationChain)
        else {
            throw ChainMigratorError.noAvailableMigration
        }
        let iterator = MigrationChainIterator(migrationChain)
        iterator.setActiveVersion(
            managedObjectModel: currentManagedObjectModel)

        delegate?.migrator(self, willProcessStoreAt: storage.storageUrl)

        while let node = iterator.next() {
            try migrateStore(
                name: node.name,
                from: currentManagedObjectModel,
                to: node.destinationManagedObjectModel,
                mappingModel: node.mappingModel)

            currentManagedObjectModel = node.destinationManagedObjectModel
        }
    }

    internal func findCompatibleModel(in chain: MigrationChain) throws -> NSManagedObjectModel? {
        try chain.managedObjectModels().first(where: isStoreCompatible(with:))
    }

    internal func validateMigrationChainAndDataModel(
        chain: MigrationChain, model: DataModel) throws
    {
        guard let managedObjectModel = try chain.managedObjectModels().last else {
            throw ChainMigratorError.noAvailableMigration
        }
        if managedObjectModel.entityVersionHashesByName !=
            dataModel.managedObjectModel.entityVersionHashesByName
        {
            throw ChainMigratorError.migrationChainIncompatibleWithDataModel
        }
    }
}
