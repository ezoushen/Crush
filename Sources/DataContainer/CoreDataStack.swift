//
//  CoreDataStack.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

internal let DefaultContextPrefix: String = "DefaultContext."
internal let UiContextName: String = "DefaultContext.ui"

public class CoreDataStack {
    public let dataModel: DataModel
    public let mergePolicy: NSMergePolicy
    public let migrationPolicy: MigrationPolicy
    
    public var storages: [Storage] {
        Array(persistentStoreDescriptions.keys)
    }

    internal let coordinator: NSPersistentStoreCoordinator!

    internal var persistentStoreDescriptions: [Storage: NSPersistentStoreDescription] = [:]

    init(
        dataModel: DataModel,
        mergePolicy: NSMergePolicy,
        migrationPolicy: MigrationPolicy)
    {
        self.dataModel = dataModel
        self.mergePolicy = mergePolicy
        self.migrationPolicy = migrationPolicy
        self.coordinator = NSPersistentStoreCoordinator(
            managedObjectModel: dataModel.managedObjectModel)
    }

    internal func removePersistentStore(storage: Storage) throws {
        try coordinator.performSync {
            try _removePersistentStore(storage: storage)
        }
    }

    internal func loadPersistentStore(storage: Storage) throws {
        var error: Error?

        try _loadPersistentStore(storage: storage, async: false) { error = $0 }

        if let error = error {
            throw error
        }
    }

    private func _removePersistentStore(storage: Storage) throws {
        if let storage = storage as? ConcreteStorage {
            try coordinator.destroyPersistentStore(
                at: storage.storageUrl, ofType: storage.storeType)
            try storage.destroy()
        } else if let store = coordinator.persistentStore(of: storage) {
            try coordinator.remove(store)
        }
        persistentStoreDescriptions.removeValue(forKey: storage)
    }

    private func _loadPersistentStore(
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

    internal func createUiContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.automaticallyMergesChangesFromParent = false
        context.name = UiContextName
        return context
    }

    internal func createBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.mergePolicy = mergePolicy
        context.automaticallyMergesChangesFromParent = false
        return context
    }

    internal func createMainThreadContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.mergePolicy = mergePolicy
        context.automaticallyMergesChangesFromParent = false
        return context
    }

    internal func checkRequirement(_ requirement: CoreDataFeatureRequirement, storage: Storage) -> Bool {
        guard let store = coordinator.persistentStore(of: storage) else { return false }
        return requirement.validate(persistentStore: store)
    }
}

// MARK: Async API (callback)

extension CoreDataStack {
    internal func loadPersistentStoreAsync(
        storage: Storage, _ completion: @escaping (Error?) -> Void)
    {
        do {
            try _loadPersistentStore(storage: storage, async: true, completion: completion)
        } catch {
            completion(error)
        }
    }

    internal func removePersistentStoreAsync(storage: Storage, completion: ((Error?) -> Void)? = nil) { 
        coordinator.performAsync {
            do {
                try self._removePersistentStore(storage: storage)
            } catch {
                completion?(error)
                return
            }
            completion?(nil)
        }
    }
}

// MARK: Async API (Swift Concurrency)

#if canImport(_Concurrency) && compiler(>=5.5.2)
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension CoreDataStack {
    internal func loadPersistentStoreAsync(storage: Storage) async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            self.loadPersistentStoreAsync(storage: storage) { error in
                if let error = error {
                    return continuation.resume(throwing: error)
                }
                return continuation.resume()
            }
        }
    }

    internal func removePersistentStoreAsync(storage: Storage) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            coordinator.performAsync {
                do {
                    try self._removePersistentStore(storage: storage)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
#endif

extension NSPersistentStoreCoordinator: TaskPerformable { }
