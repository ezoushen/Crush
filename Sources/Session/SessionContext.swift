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
}

public protocol SessionContext: QueryerProtocol, MutableQueryerProtocol {
    func create<T: Entity>(entity: T.Type) -> ManagedObject<T>
    func delete<T: Entity>(_ object: ManagedObject<T>)
    func load<T: Entity>(objectID: NSManagedObjectID) -> ManagedObject<T>?
    func edit<T: Entity>(object: T.ReadOnly) -> ManagedObject<T>
    func edit<T: Entity>(objects: [T.ReadOnly]) -> [ManagedObject<T>]

    func commit(_ handler: @escaping (Error?) -> Void) throws
    func commit() throws
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

extension SessionContext where Self: RawContextProviderProtocol {
    private func canUseBatchRequest() -> Bool {
        rootContext
            .persistentStoreCoordinator?
            .persistentStores.contains { $0.type != NSSQLiteStoreType } == false
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

    public func load<T: Entity>(objectID: NSManagedObjectID) -> ManagedObject<T>? {
        executionContext.object(with: objectID) as? ManagedObject<T>
    }
}

internal struct DummyContext: SessionContext, RawContextProviderProtocol {
    internal var logger: DataContainer.LogHandler = .default
    internal var executionContext: NSManagedObjectContext { fatalError() }
    internal var rootContext: NSManagedObjectContext { fatalError() }
    internal var uiContext: NSManagedObjectContext { fatalError() }
}

internal struct _SessionContext: SessionContext, RawContextProviderProtocol {
    internal let executionContext: NSManagedObjectContext
    internal let rootContext: NSManagedObjectContext
    internal let uiContext: NSManagedObjectContext
    internal let logger: DataContainer.LogHandler
    
    internal init(executionContext: NSManagedObjectContext, rootContext: NSManagedObjectContext, uiContext: NSManagedObjectContext, logger: DataContainer.LogHandler) {
        self.executionContext = executionContext
        self.rootContext = rootContext
        self.uiContext = uiContext
        self.logger = logger
    }
}

extension SessionContext where Self: RawContextProviderProtocol {
    func count(request: NSFetchRequest<NSFetchRequestResult>, on context: KeyPath<RawContextProviderProtocol, NSManagedObjectContext>) -> Int {
        var result: Int? = nil
        let context = self[keyPath: context]
        context.performAndWait {
            do {
                result = try context.count(for: request)
            } catch {
                logger.log(.error, "Unabled to count the records", error: error)
            }
        }
        
        return result ?? 0
    }
    
    func execute<T>(request: NSFetchRequest<NSFetchRequestResult>, on context: KeyPath<RawContextProviderProtocol, NSManagedObjectContext>) throws -> [T] {
        let context = self[keyPath: context]
        return try context.performSync {
            context.processPendingChanges()
            return try context.fetch(request) as! [T]
        }
    }
    
    func execute<T: NSPersistentStoreResult>(request: NSPersistentStoreRequest, on context: KeyPath<RawContextProviderProtocol, NSManagedObjectContext>) throws -> T {
        let context = self[keyPath: context]
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
            } else if #available(iOS 13.0, watchOS 6.0, macOS 10.15, *), let result = result as? NSBatchInsertResult {
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
            executionContext.receive(runtimeObject: object.managedObject)
        }
    }

    public func edit<T: Entity>(objects: [T.ReadOnly]) -> [ManagedObject<T>] {
        objects.map { object in
            executionContext.performSync {
                executionContext.receive(runtimeObject: object.managedObject)
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
    
    private static func defaultCommitCompletionHandler(_ error: Error?) {
        guard let error = error else { return }
        fatalError("Unhandled error: \(error)")
    }
    
    public func commit() throws {
        try commit(Self.defaultCommitCompletionHandler)
    }
    
    public func commit(_ handler: @escaping (Error?) -> Void) throws {
        try executionContext.performSync {
            let objectIDs = try saveExecutionContext {
                rootContext.performAsync {
                    do {
                        try saveRootContext()
                    } catch let error as NSError {
                        handler(error.customError())
                    }
                }
            }
            refreshObjects(objectIDs)
        }
    }
    
    internal func saveExecutionContext(
        _ completion: @escaping () throws -> Void) throws -> Set<NSManagedObjectID>
    {
        guard executionContext.hasChanges else {
            return []
        }
        let objectIDs = Set(
            executionContext.updatedObjects
                .union(executionContext.deletedObjects)
                .union(executionContext.insertedObjects)
                .map(\.objectID))
        do {
            try executionContext.save()
        } catch let error as NSError {
            let error = error.customError()
            logger.log(
                .error,
                "Merge changes to the writer context ended with error",
                error: error)
            throw error
        }

        try completion()

        return objectIDs
    }

    internal func refreshObjects(_ objectIDs: Set<NSManagedObjectID>) {
        DispatchQueue.performMainThreadTask {
            objectIDs
                .intersection(uiContext.registeredObjects.map(\.objectID))
                .map(uiContext.object(with:))
                .forEach {
                    uiContext.refresh(
                        $0, mergeChanges: true, preserveFaultingState: true)
                }
        }
    }
    
    internal func saveRootContext() throws {
        do {
            try rootContext.save()
        } catch let error as NSError {
            logger.log(.error, "Merge changes to the persistent container ended with error", error: error)
            rootContext.rollback()
            throw error
        }
    }
}
