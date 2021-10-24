//
//  Migrator.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public enum MigrationError: Error {
    case incompatible
    case notMigrated
}

open /*abstract*/ class Migrator {

    internal let storage: ConcreteStorage
    internal let dataModel: DataModel

    internal init(storage: ConcreteStorage, dataModel: DataModel) {
        self.storage = storage
        self.dataModel = dataModel
    }

    @discardableResult
    open /*abstract*/ func migrate() throws -> Bool {
        return false
    }

    internal func migrateStore(
        name: String,
        from sourceModel: NSManagedObjectModel,
        to destinationModel: NSManagedObjectModel,
        mappingModel: NSMappingModel) throws
    {
        let fileManager = FileManager.default
        var destinationURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        
        if !fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.createDirectory(
                at: destinationURL,
                withIntermediateDirectories: true,
                attributes: nil)
        }
        
        destinationURL.appendPathComponent(name)

        var options: [AnyHashable: Any] = [:]
        if storage.storeType == NSSQLiteStoreType {
            options = Storage.defaultSQLiteOptions()
            options[NSSQLitePragmasOption] = ["journal_mode": "DELETE"]
        }

        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        try manager.migrateStore(
            from: storage.storageUrl,
            sourceType: storage.storeType,
            options: options,
            with: mappingModel,
            toDestinationURL: destinationURL,
            destinationType: storage.storeType,
            destinationOptions: options
        )
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: destinationModel)
        try coordinator.replacePersistentStore(
            at: storage.storageUrl,
            destinationOptions: options,
            withPersistentStoreFrom: destinationURL,
            sourceOptions: options,
            ofType: storage.storeType)
        
        coordinator.updateLastActiveModel(
            name: name, managedObjectModel: destinationModel, in: storage)
    }
}
