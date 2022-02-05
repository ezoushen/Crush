//
//  CoreDataStack.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

internal let DefaultContextPrefix: String = "DefaultContext."
internal let WriterContextName: String = "DefaultContext.writer"
internal let UiContextName: String = "DefaultContext.ui"

public class CoreDataStack {
    public let storages: [Storage]
    public let dataModel: DataModel
    public let mergePolicy: NSMergePolicy
    public let migrationPolicy: MigrationPolicy

    internal let coordinator: NSPersistentStoreCoordinator!

    internal var persistentStoreDescriptions: [Storage: NSPersistentStoreDescription] = [:]

    init(
        storage: Storage,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy,
        migrationPolicy: MigrationPolicy)
    {
        self.storages = [storage]
        self.dataModel = dataModel
        self.mergePolicy = mergePolicy
        self.migrationPolicy = migrationPolicy
        self.coordinator = NSPersistentStoreCoordinator(
            managedObjectModel: dataModel.managedObjectModel)
    }

    internal func loadPersistentStore(storage: Storage) throws {
        var error: Error?

        try loadPersistentStore(storage: storage, async: false) { error = $0 }

        if let error = error {
            throw error
        }
    }

    internal func loadPersistentStoreAsync(storage: Storage, _ completion: @escaping (Error?) -> Void) {
        do {
            try loadPersistentStore(storage: storage, async: true, completion: completion)
        } catch {
            completion(error)
        }
    }

    private func loadPersistentStore(
        storage: Storage, async flag: Bool, completion: @escaping (Error?) -> Void) throws
    {
        // Migrate store before loading
        try migrationPolicy.process(storage: storage, with: dataModel)
        // Setup persistent store description
        let description = storage.createDescription()
        migrationPolicy.configureStoreDescription(description)
        description.shouldAddStoreAsynchronously = flag
        // Load persistent store
        coordinator.addPersistentStore(with: description) { [unowned self] in
            persistentStoreDescriptions[storage] = $0
            completion($1)
        }
        NSPersistentStoreCoordinator.updateLastActiveModel(dataModel, in: storage)
        dataModel.managedObjectModel.save()
    }

    internal func isLoaded(storage: Storage) -> Bool {
        coordinator.persistentStore(of: storage) != nil
    }

    internal func createWriterContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.mergePolicy = mergePolicy
        context.automaticallyMergesChangesFromParent = false
        context.name = WriterContextName
        return context
    }

    internal func createUiContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parent
        context.automaticallyMergesChangesFromParent = false
        context.name = UiContextName
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
