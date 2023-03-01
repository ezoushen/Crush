//
//  SessionContext.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol RawContextProviderProtocol {
    var executionContext: NSManagedObjectContext { get }
    var rootContext: NSManagedObjectContext { get }
    var uiContext: NSManagedObjectContext { get }
    var logger: DataContainer.LogHandler { get }
    
    func context(for fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> NSManagedObjectContext
    func context(for persistentStoreRequest: NSPersistentStoreRequest) -> NSManagedObjectContext
}

extension RawContextProviderProtocol {
    func context(for asyncFetchRequest: NSAsynchronousFetchRequest<NSFetchRequestResult>) -> NSManagedObjectContext {
        context(for: asyncFetchRequest.fetchRequest)
    }
}

/**
 A protocol for a session context that conforms to QueryerProtocol and MutableQueryerProtocol.
 */
public protocol SessionContext: QueryerProtocol, MutableQueryerProtocol {

    /**
     Creates a managed object of the given entity type.

     - Parameter entity: The type of entity to create a managed object for.

     - Returns: The created managed object.
     */
    func create<T: Entity>(entity: T.Type) -> ManagedObject<T>

    /**
     Deletes the given managed object.

     - Parameter object: The managed object to delete.
     */
    func delete<T: Entity>(_ object: ManagedObject<T>)

    /**
     Loads a managed object of the given entity type with the given object ID.

     - Parameter objectID: The object ID of the managed object to load.
     - Parameter isFault: A boolean indicating whether the object should be returned as a fault.

     - Returns: The loaded managed object, or nil if it could not be loaded.
     */
    func load<T: Entity>(objectID: NSManagedObjectID, isFault: Bool) -> ManagedObject<T>?

    /**
     Edits the given read-only object and returns a new managed object with the changes applied.

     - Parameter object: The read-only object to edit.

     - Returns: The edited managed object.
     */
    func edit<T: Entity>(object: T.ReadOnly) -> ManagedObject<T>

    /**
     Edits the given array of read-only objects and returns an array of new managed objects with the changes applied.

     - Parameter objects: The read-only objects to edit.

     - Returns: The edited managed objects.
     */
    func edit<T: Entity>(objects: [T.ReadOnly]) -> [ManagedObject<T>]

    /**
     Obtains the object IDs of the given objects to make them permanent. After this operation, `isTemporary` will return false for each object.

     - Parameter objects: The objects to make permanent.

     - Throws: An error if the permanent IDs could not be obtained.
     */
    func obtainPermanentIDs(for objects: [NSManagedObject]) throws

    /**
     Updates in-memory object graphs with any pending changes.
     */
    func processPendingChanges()

    /**
     Saves any changes made to the context.

     - Throws: An error if the changes could not be saved.
     */
    func commit() throws
}

extension SessionContext {
    /**
     Loads a managed object of the given entity type with the given object ID and returns it as a fault.

     - Parameter objectID: The object ID of the managed object to load.

     - Returns: The loaded managed object as a fault, or nil if it could not be loaded.
     */
    @inlinable
    public func load<T: Entity>(objectID: NSManagedObjectID) -> ManagedObject<T>? {
        load(objectID: objectID, isFault: true)
    }
}

extension SessionContext where Self: RawContextProviderProtocol {
    func receive<T: NSManagedObject>(_ object: T) -> T {
        guard executionContext !== object.managedObjectContext else { return object }
        return executionContext.performSync {
            executionContext.receive(runtimeObject: object)
        }
    }
    
    func present<T: NSManagedObject>(_ object: T) -> T {
        guard uiContext !== object.managedObjectContext else { return object }
        return uiContext.performSync {
            uiContext.receive(runtimeObject: object)
        }
    }
}

// MARK: Implementation of QueryProtocol

extension SessionContext where Self: RawContextProviderProtocol {
    private func canUseBatchRequest() -> Bool {
        rootContext
            .persistentStoreCoordinator?
            .checkRequirement([.sqliteStore]) ?? false
    }

    public func fetch<T: Entity>(for type: T.Type) -> ManagedFetchBuilder<T> {
        .init(config: .init(), context: self)
    }
    
    public func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T> {
        .init(
            config: .init(batch: canUseBatchRequest()),
            context: self)
    }
    
    public func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T> {
        .init(config: .init(batch: canUseBatchRequest()), context: self)
    }
    
    public func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T> {
        .init(config: .init(batch: canUseBatchRequest()), context: self)
    }
}

extension SessionContext where Self: RawContextProviderProtocol {
    /**
    A public function to load a managed object of the specified entity type with the specified object ID.
    - Parameter objectID: The object ID of the managed object to load.
    - Parameter isFault: A boolean value indicating whether the loaded object should be turned into a fault object.
    - Returns: A `ManagedObject` instance of the specified entity type.
    */
   public func load<T: Entity>(objectID: NSManagedObjectID, isFault: Bool = true) -> ManagedObject<T>? {
       executionContext.load(objectID: objectID, isFault: isFault) as? ManagedObject<T>
   }

   /**
    A public function to load a managed object of the specified entity type with the specified URI representation.
    - Parameter uri: The URI representation of the managed object to load.
    - Parameter isFault: A boolean value indicating whether the loaded object should be turned into a fault object.
    - Returns: A `ManagedObject` instance of the specified entity type.
    */
    public func assign(object: NSManagedObject, to storage: Storage) {
        guard let store = rootContext.persistentStoreCoordinator!
                .persistentStore(of: storage) else {
            logger.log(.error, "Persistent store for \(storage) not found")
            return
        }
        executionContext.assign(object, to: store)
    }

    /**
    A function that obtains permanent IDs for the given objects in the context's execution context.

    - Parameters objects: An array of NSManagedObject instances for which to obtain permanent IDs.
    */
    public func obtainPermanentIDs(for objects: [NSManagedObject]) throws {
        try executionContext.obtainPermanentIDs(for: objects)
    }

    /// A function that processes any pending changes in the context's execution context.
    public func processPendingChanges() {
        executionContext.processPendingChanges()
    }
}

internal struct DummyContext: SessionContext, RawContextProviderProtocol {
    internal var logger: DataContainer.LogHandler = .default
    internal var executionContext: NSManagedObjectContext { fatalError() }
    internal var rootContext: NSManagedObjectContext { fatalError() }
    internal var uiContext: NSManagedObjectContext { fatalError() }
    internal func commit() throws { fatalError() }
    internal func context(for persistentStoreRequest: NSPersistentStoreRequest) -> NSManagedObjectContext { fatalError() }
    internal func context(for fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> NSManagedObjectContext { fatalError() }
}

internal struct _DetachedSessionContext: SessionContext, RawContextProviderProtocol {
    internal let executionContext: NSManagedObjectContext
    internal let rootContext: NSManagedObjectContext
    internal let uiContext: NSManagedObjectContext
    internal let logger: DataContainer.LogHandler

    internal func commit() throws {
        let result = try saveExecutionContext(executionContext)
        refreshObjects(result, contexts: rootContext)
    }
    
    internal func context(for persistentStoreRequest: NSPersistentStoreRequest) -> NSManagedObjectContext {
        executionContext
    }
    
    internal func context(for fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> NSManagedObjectContext {
        executionContext
    }
}

internal struct _SessionContext: SessionContext, RawContextProviderProtocol {
    internal let executionContext: NSManagedObjectContext
    internal let rootContext: NSManagedObjectContext
    internal let uiContext: NSManagedObjectContext
    internal let logger: DataContainer.LogHandler

    internal func commit() throws {
        let author = executionContext.transactionAuthor
        _ = try saveExecutionContext(executionContext)
        try rootContext.performSync {
            rootContext.transactionAuthor = author
            try saveRootContext(rootContext)
            rootContext.transactionAuthor = nil
        }
    }
    
    internal func context(for persistentStoreRequest: NSPersistentStoreRequest) -> NSManagedObjectContext {
        rootContext
    }
    
    internal func context(for fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> NSManagedObjectContext {
        executionContext
    }
}

extension SessionContext {
    typealias ExecutionResult = (
        inserted: [NSManagedObjectID], updated: [NSManagedObjectID], deleted: [NSManagedObjectID])
    typealias ExecutionResultHandler = (ExecutionResult, [NSManagedObjectContext]) -> Void
}

extension SessionContext where Self: RawContextProviderProtocol {
    func count(request: NSFetchRequest<NSFetchRequestResult>) -> Int {
        var result: Int? = nil
        let context = context(for: request)
        context.performAndWait {
            do {
                result = try context.count(for: request)
            } catch {
                logger.log(.error, "Unabled to count the records", error: error)
            }
        }
        
        return result ?? 0
    }
    
    func execute<T>(request: NSFetchRequest<NSFetchRequestResult>) throws -> [T] {
        let context = context(for: request)
        return try context.performSync {
            let result = try context.fetch(request) as! [T]
            return result
        }
    }
    
    func execute<T: NSPersistentStoreResult>(request: NSPersistentStoreRequest) throws -> T {
        let context = context(for: request)
        let result: T = try context.performSync {
            context.processPendingChanges()
            return try context.execute(request) as! T
        }
        if let changes: [AnyHashable: Any] = {
            if let result = result as? NSBatchDeleteResult {
                return [
                    NSDeletedObjectsKey: result.result ?? []
                ]
            } else if let result = result as? NSBatchUpdateResult {
                return [
                    NSUpdatedObjectsKey: result.result ?? []
                ]
            } else if #available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *), let result = result as? NSBatchInsertResult {
                return [
                    NSInsertedObjectsKey: result.result ?? []
                ]
            }
            return nil
        }() {
            let contexts = [
                self.rootContext,
                self.uiContext,
                self.executionContext
            ]

            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: contexts)
        }
        return result
    }
}

extension SessionContext where Self: RawContextProviderProtocol {
    public func edit<T: Entity>(object: T.ReadOnly) -> ManagedObject<T> {
        executionContext.performSync {
            executionContext.receive(runtimeObject: object.managedObject as! T.Managed)
        }
    }

    public func edit<T: Entity>(objects: [T.ReadOnly]) -> [ManagedObject<T>] {
        objects.map { object in
            executionContext.performSync {
                executionContext.receive(runtimeObject: object.managedObject as! T.Managed)
            }
        }
    }

    public func create<T: Entity>(entity: T.Type) -> ManagedObject<T> {
        executionContext.performSync {
            ManagedObject<T>(context: executionContext)
        }
    }
    
    public func delete<T: Entity>(_ object: ManagedObject<T>) {
        executionContext.performSync {
            executionContext.delete(object)
        }
    }
    
    internal func saveExecutionContext(
        _ executionContext: NSManagedObjectContext) throws -> ExecutionResult
    {
        guard executionContext.hasChanges else {
            return ([], [], [])
        }
        let deletedObjectIDs = executionContext.deletedObjects.map(\.objectID)
        let updatedObjectIDs = executionContext.updatedObjects.map(\.objectID)
        let insertedObjectIDs = executionContext.insertedObjects.map(\.objectID)
        
        do {
            try executionContext.save()
        } catch let _error as NSError {
            let error: Error = CoreDataError(nsError: _error) ?? _error
            logger.log(.error, "Merge changes from execution context ended with error", error: error)
            throw error
        }
        return (inserted: insertedObjectIDs, updated: updatedObjectIDs, deleted: deletedObjectIDs)
    }

    internal func refreshObjects(
        _ executionResult: ExecutionResult, contexts: NSManagedObjectContext...)
    {
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [
                NSInsertedObjectsKey: executionResult.inserted,
                NSUpdatedObjectsKey: executionResult.updated,
                NSDeletedObjectsKey: executionResult.deleted,
            ],
            into: contexts)
    }
    
    internal func saveRootContext(_ rootContext: NSManagedObjectContext) throws {
        do {
            try rootContext.save()
        } catch let _error as NSError {
            let error: Error = CoreDataError(nsError: _error) ?? _error
            logger.log(.error, "Merge changes from root context ended with error", error: error)
            rootContext.rollback()
            throw error
        }
    }
}
