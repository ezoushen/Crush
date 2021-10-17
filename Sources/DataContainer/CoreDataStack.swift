//
//  CoreDataStack.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public class CoreDataStack {
    public let storage: Storage
    public let dataModel: DataModel
    public let mergePolicy: NSMergePolicy
    public let migrationPolicy: MigrationPolicy

    internal let coordinator: NSPersistentStoreCoordinator!

    init(
        storage: Storage,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy,
        migrationPolicy: MigrationPolicy) throws
    {
        self.storage = storage
        self.dataModel = dataModel
        self.mergePolicy = mergePolicy
        self.migrationPolicy = migrationPolicy
        self.coordinator = NSPersistentStoreCoordinator(
            managedObjectModel: dataModel.managedObjectModel)
    }

    internal func loadPersistentStore() throws {
        var error: Error?

        try loadPersistentStore(async: false) { error = $0 }

        if let error = error {
            throw error
        }
    }

    internal func loadPersistentStoreAsync(
        _ completion: @escaping (Error?) -> Void) throws
    {
        try loadPersistentStore(async: true, completion: completion)
    }

    private func loadPersistentStore(async flag: Bool, completion: @escaping (Error?) -> Void) throws {
        // Migrate store before reading
        try migrationPolicy.process(storage: storage, with: dataModel)
        // Setup persistent store description
        let description = storage.createDescription()
        migrationPolicy.configureStoreDescription(description)
        description.shouldAddStoreAsynchronously = flag
        // Load persistent store
        coordinator.addPersistentStore(with: description) {
            completion($1)
        }
        NSPersistentStoreCoordinator
            .updateLastActiveVersionName(dataModel.name, in: storage)
        dataModel.managedObjectModel.save(name: dataModel.name)
    }

    internal func createWriterContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.mergePolicy = mergePolicy
        context.automaticallyMergesChangesFromParent = false
        return context
    }

    internal func createUiContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parent
        context.automaticallyMergesChangesFromParent = false
        return context
    }

    internal func createBackgroundContext(parent: NSManagedObjectContext?) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = parent
        context.automaticallyMergesChangesFromParent = false
        return context
    }

    internal func createMainThreadContext(parent: NSManagedObjectContext?) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parent
        context.automaticallyMergesChangesFromParent = false
        return context
    }
}
