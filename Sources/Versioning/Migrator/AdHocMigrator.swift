//
//  AdHocMigrator.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

internal final class AdHocMigrator: Migrator {
    internal let lastActiveModel: NSManagedObjectModel?
    internal let migration: ModelMigration

    internal init(
        storage: ConcreteStorage,
        sourceModelName: String,
        migration: ModelMigration,
        dataModel: DataModel)
    {
        self.migration = migration
        self.lastActiveModel = .load(name: sourceModelName)
        super.init(storage: storage, dataModel: dataModel)
    }

    @discardableResult
    internal override func migrate() throws -> Bool {
        guard let sourceModel = lastActiveModel else { return false }

        let currentModel = dataModel.managedObjectModel
        let destinationModel = try migration.migrateModel(sourceModel)
        let isCompatible = currentModel.isCompactible(with: destinationModel)

        guard isCompatible else {
            throw MigrationError.incompatible
        }

        let mappingModel = try migration
            .createMappingModel(from: sourceModel, to: destinationModel)

        try migrateStore(
            name: dataModel.name,
            from: sourceModel,
            to: destinationModel,
            mappingModel: mappingModel)

        return true
    }
}
