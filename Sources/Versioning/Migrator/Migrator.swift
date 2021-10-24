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
    open func migrate() throws -> Bool {
        return false
    }

    internal func migrateStore(
        name: String,
        from sourceModel: NSManagedObjectModel,
        to destinationModel: NSManagedObjectModel,
        mappingModel: NSMappingModel) throws
    {
        processModel(sourceModel)
        processModel(destinationModel)
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
            ofType: storage.storeType)
        if let store = coordinator.persistentStore(for: storage.storageUrl) {
            coordinator.updateLastActiveVersionName(name, in: store)
        }
    }
    
    func processModel(_ model: NSManagedObjectModel) {
        model.entities.forEach {
            $0.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        }
    }
}
