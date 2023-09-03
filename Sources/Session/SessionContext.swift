//
//  SessionContext.swift
//  Crush
//
//  Created by EZOU on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

/// A class that represents a session context. Wrapping structured managed object contexts and providing multiple essential methods.
public class SessionContext {
    static func dummy() -> SessionContext {
        .init()
    }

    @inline(__always) var executionContext: NSManagedObjectContext { _executionContext }
    @inline(__always) var uiContext: NSManagedObjectContext { _uiContext }

    private let _executionContext: NSManagedObjectContext!
    private let _uiContext: NSManagedObjectContext!
    private var _executionResult: ExecutionResult?

    init(executionContext: NSManagedObjectContext, uiContext: NSManagedObjectContext) {
        self._executionContext = executionContext
        self._uiContext = uiContext
    }

    private init() {
        self._executionContext = nil
        self._uiContext = nil
    }

    /// Creates a managed object of the given entity type.
    /// - Parameter entity: The type of entity to create a managed object for.
    /// - Returns: The created managed object.
    public func create<T: Entity>(entity: T.Type) -> T.Driver {
        executionContext.performSync {
            T.Driver(unsafe: EntityManagedObject(entity: entity.entity(), insertInto: executionContext))
        }
    }

    /// Deletes the given managed object.
    /// - Parameter object: The managed object to delete.
    public func delete<T: Entity>(_ object: T.Driver) {
        executionContext.performSync {
            executionContext.delete(object.managedObject)
        }
    }

    /// A public function to load a managed object of the specified entity type with the specified object ID.
    /// - Parameter objectID: The object ID of the managed object to load.
    /// - Parameter isFault: A boolean value indicating whether the loaded object should be turned into a fault object.
    /// - Returns: A `ManagedDriver` instance of the specified entity type.
    public func load<T: Entity>(objectID: NSManagedObjectID, isFault: Bool = true) -> T.Driver? {
        guard let object = executionContext.load(objectID: objectID, isFault: isFault) else { return nil }
        return T.Driver(object)
    }

    /// A public function to load a managed object of the specified entity type with the specified object ID.
    /// - Parameter objectID: The object ID of the managed object to load.
    /// - Parameter isFault: A boolean value indicating whether the loaded object should be turned into a fault object.
    /// - Returns: A `ManagedDriver` instance of the specified entity type.
    public func load<T: Entity>(objectIDs: [NSManagedObjectID], isFault: Bool = true) -> [T.Driver?] {
        objectIDs.map { load(objectID: $0, isFault: isFault) }
    }

    /// A public function to load a managed object of the specified entity type with the specified URI representation.
    /// - Parameter uri: The URI representation of the managed object to load.
    /// - Parameter isFault: A boolean value indicating whether the loaded object should be turned into a fault object.
    /// - Returns: A `ManagedDriver` instance of the specified entity type.
    public func assign(object: NSManagedObject, to storage: Storage) {
        guard let store = executionContext.persistentStoreCoordinator!
            .persistentStore(of: storage) else {
            LogHandler.current.log(.error, "Persistent store for \(storage) not found")
            return
        }
        executionContext.assign(object, to: store)
    }

    /// Edits the given read-only object and returns a new managed object with the changes applied.
    /// - Parameter object: The read-only object to edit.
    /// - Returns: The edited managed object.
    public func edit<T: Entity>(object: T.ReadOnly) -> T.Driver {
        executionContext.performSync {
            T.Driver(unsafe: executionContext.receive(runtimeObject: object.managedObject))
        }
    }

    /// Edits the given array of read-only objects and returns an array of new managed objects with the changes applied.
    /// - Parameter objects: The read-only objects to edit.
    /// - Returns: The edited managed objects.
    public func edit<T: Entity>(objects: [T.ReadOnly]) -> [T.Driver] {
        objects.map(edit(object:))
    }

    /// A function that obtains permanent IDs for the given objects in the context's execution context.
    /// - Parameters objects: An array of NSManagedObject instances for which to obtain permanent IDs.
    /// - Throws: An error if the permanent IDs could not be obtained.
    @inlinable public func obtainPermanentIDs(for objects: NSManagedObject...) throws {
        try obtainPermanentIDs(for: objects)
    }

    /// A function that obtains permanent IDs for the given objects in the context's execution context.
    /// - Parameters objects: An array of NSManagedObject instances for which to obtain permanent IDs.
    /// - Throws: An error if the permanent IDs could not be obtained.
    public func obtainPermanentIDs(for objects: [NSManagedObject]) throws {
        try executionContext.obtainPermanentIDs(for: objects)
    }

    /// A function that obtains permanent IDs for the given objects in the context's execution context.
    /// - Parameters objects: An array of ManagedDriver instances for which to obtain permanent IDs.
    /// - Throws: An error if the permanent IDs could not be obtained.
    @inlinable public func obtainPermanentIDs<T: Entity>(for objects: T.Driver...) throws {
        try obtainPermanentIDs(for: objects)
    }

    /// A function that obtains permanent IDs for the given objects in the context's execution context.
    /// - Parameters objects: An array of ManagedDriver instances for which to obtain permanent IDs.
    /// - Throws: An error if the permanent IDs could not be obtained.
    public func obtainPermanentIDs<T: Entity>(for objects: [T.Driver]) throws {
        try executionContext.obtainPermanentIDs(for: objects.map(\.managedObject))
    }

    /// A function that processes any pending changes in the context's execution context.
    public func processPendingChanges() {
        executionContext.processPendingChanges()
    }

    /// Saves any changes made to the context.
    /// - Throws: An error if the changes could not be saved.
    public func commit() throws {
        let result = try saveExecutionContext(executionContext)
        updateExecutionResult(result)
    }

    // MARK: Internal methods

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

    func count(request: NSFetchRequest<NSFetchRequestResult>) -> Int {
        var result: Int? = nil
        let context = executionContext
        context.performAndWait {
            do {
                result = try context.count(for: request)
            } catch {
                LogHandler.current.log(.error, "Unabled to count the records", error: error)
            }
        }

        return result ?? 0
    }

    func execute<T>(request: NSFetchRequest<NSFetchRequestResult>) throws -> [T] {
        let context = executionContext
        return try context.performSync {
            let result = try context.fetch(request) as! [T]
            return result
        }
    }

    func execute<T: NSPersistentStoreResult>(request: NSPersistentStoreRequest) throws -> T {
        let context = executionContext
        let result: T = try context.performSync {
            return try context.execute(request) as! T
        }
        if let changes: [AnyHashable: Any] = {
            if let result = result as? NSBatchDeleteResult {
                return [
                    NSDeletedObjectsKey: result.result ?? [NSManagedObject]()
                ]
            } else if let result = result as? NSBatchUpdateResult {
                return [
                    NSUpdatedObjectsKey: result.result ?? [NSManagedObject]()
                ]
            }
            return nil
        }() {
            let contexts: [NSManagedObjectContext] = [ uiContext ]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: contexts)
        }
        return result
    }

    func dumpExecutionResult() -> ExecutionResult? {
        executionContext.performSync {
            guard let result = _executionResult else { return nil }
            _executionResult = nil
            return result
        }
    }

    func resolveExecutionResultInUiContext() {
        guard let result = dumpExecutionResult() else { return }
        uiContext.resolveExecutionResult(result)
    }

    private func updateExecutionResult(_ patch: ExecutionResult) {
        if _executionResult != nil {
            _executionResult?.merge(patch)
        } else {
            _executionResult = patch
        }
    }
}

// MARK: Implementation of QueryProtocol

extension SessionContext: QueryerProtocol, MutableQueryerProtocol {

    private func canUseBatchRequest() -> Bool {
        executionContext
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

extension SessionContext {
    typealias ExecutionResultHandler = (ExecutionResult, [NSManagedObjectContext]) -> Void

    struct ExecutionResult {
        var inserted: [NSManagedObjectID]
        var updated: [NSManagedObjectID]
        var deleted: [NSManagedObjectID]

        mutating func merge(_ result: ExecutionResult) {
            inserted.append(contentsOf: result.inserted)
            updated.append(contentsOf: result.updated)
            deleted.append(contentsOf: result.deleted)
        }
    }

    fileprivate func saveExecutionContext(
        _ executionContext: NSManagedObjectContext) throws -> ExecutionResult
    {
        guard executionContext.hasChanges else {
            return .init(inserted: [], updated: [], deleted: [])
        }
        let deletedObjectIDs = executionContext.deletedObjects.map(\.objectID)
        let updatedObjectIDs = executionContext.updatedObjects.map(\.objectID)
        let insertedObjectIDs = executionContext.insertedObjects.map(\.objectID)
        
        do {
            try executionContext.save()
        } catch let _error as NSError {
            let error: Error = CoreDataError(nsError: _error) ?? _error
            LogHandler.current.log(.error, "Merge changes from execution context ended with error", error: error)
            throw error
        }
        return .init(inserted: insertedObjectIDs, updated: updatedObjectIDs, deleted: deletedObjectIDs)
    }
}

extension NSManagedObjectContext {
    func resolveExecutionResult(_ result: SessionContext.ExecutionResult) {
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [
                NSInsertedObjectsKey: result.inserted,
                NSUpdatedObjectsKey: result.updated,
                NSDeletedObjectsKey: result.deleted,
            ], into: [self])
    }
}
