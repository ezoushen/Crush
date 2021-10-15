//
//  Migrator.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

open /*abstract*/ class Migrator {

    internal let storage: ConcreteStorage
    internal let dataModel: DataModel

    internal weak var delegate: MigratorDelegate?

    internal init(storage: ConcreteStorage, dataModel: DataModel) {
        self.storage = storage
        self.dataModel = dataModel
    }

    open func migrate() throws {

    }

    internal func isStoreCompatible(
        with managedObjectModel: NSManagedObjectModel) throws -> Bool
    {
        let metadata = try NSPersistentStoreCoordinator
            .metadataForPersistentStore(ofType: storage.storeType, at: storage.storageUrl)
        return managedObjectModel.isConfiguration(
            withName: storage.configuration, compatibleWithStoreMetadata: metadata)
    }

    internal func migrateStore(
        name: String,
        from sourceModel: NSManagedObjectModel,
        to destinationModel: NSManagedObjectModel,
        mappingModel: NSMappingModel) throws
    {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(name)
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        try manager.migrateStore(
            from: storage.storageUrl,
            sourceType: storage.storeType,
            options: nil,
            with: mappingModel,
            toDestinationURL: destinationURL,
            destinationType: storage.storeType,
            destinationOptions: nil
        )
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: destinationModel)
        try coordinator.replacePersistentStore(
            at: storage.storageUrl,
            destinationOptions: nil,
            withPersistentStoreFrom: destinationURL,
            sourceOptions: nil,
            ofType: storage.storeType
        )
    }
}

extension Migrator {
    public static func create(
        storage: Storage,
        migrationChain: MigrationChain?,
        dataModel: DataModel) -> Migrator?
    {
        guard let migrationChain = migrationChain,
              let storage = storage as? ConcreteStorage else {
                  return nil
              }
        return ChainMigrator(
            storage: storage,
            migrationChain: migrationChain,
            dataModel: dataModel)
    }
}
