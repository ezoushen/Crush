//
//  DataContainer.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

extension Notification.Name {
    public static let DataContainerDidRefreshUiContext: Notification.Name = .init("Notification.Name.DataContainerDidRefreshUiContext")
}

public class DataContainer {
    internal var writerContext: NSManagedObjectContext!
    internal var uiContext: NSManagedObjectContext!
    
    let connection: Connection
    
    let mergePolicy: NSMergePolicy
        
    public init(
        connection: Connection,
        mergePolicy: NSMergePolicy = .error,
        completion: @escaping () -> Void = {}
    ) throws {
        self.connection = connection
        self.mergePolicy = mergePolicy
        
        let block = { [weak self] in
            guard let `self` = self else { return }
            self.initializeAllContext()
            DispatchQueue.main.async(execute: completion)
        }
        
        connection.isConnected
            ? block()
            : try connection.connect(completion: block)
    }
    
    private func initializeAllContext() {
        writerContext = createWriterContext()
        uiContext = createUiContext(parent: writerContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(writerContextDidSave), name: Notification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    @objc private func writerContextDidSave(notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext,
                  context == writerContext else { return }
        
        let block: () -> Void =  {
            self.uiContext.refreshAllObjects()
            
            let ids = (notification.userInfo?[NSUpdatedObjectsKey] as? NSSet)?.allObjects.compactMap {
                ($0 as? NSManagedObject)?.objectID
            } ?? []
            
            NotificationCenter.default.post(
                name: .DataContainerDidRefreshUiContext,
                object: self,
                userInfo: ["objectIDs": ids]
            )
        }
        
        if Thread.current == .main {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
    
    private func createWriterContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = connection.persistentStoreCoordinator
        context.mergePolicy = mergePolicy
        context.shouldDeleteInaccessibleFaults = true
        context.automaticallyMergesChangesFromParent = false
        context.retainsRegisteredObjects = false
        return context
    }
    
    private func createUiContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parent
        context.stalenessInterval = 0.0
        context.automaticallyMergesChangesFromParent = false
        context.shouldDeleteInaccessibleFaults = true
        context.retainsRegisteredObjects = false
        return context
    }
    
    private func createContext(parent: NSManagedObjectContext, concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        autoreleasepool {
            let context = NSManagedObjectContext(concurrencyType: concurrencyType)
            context.parent = parent
            context.stalenessInterval = 0.0
            context.retainsRegisteredObjects = false
            context.automaticallyMergesChangesFromParent = false
            return context
        }
    }
    
    private func createBackgroundContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        createContext(parent: parent, concurrencyType: .privateQueueConcurrencyType)
    }
    
    private func createMainThreadContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        createContext(parent: parent, concurrencyType: .mainQueueConcurrencyType)
    }
    
    public func reduceMemoryUsage() {
        uiContext.reset()
        writerContext.reset()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension DataContainer {
    internal func backgroundTransactionContext() -> _TransactionContext {
        _TransactionContext(executionContext: createBackgroundContext(parent: writerContext),
                            rootContext: writerContext,
                            uiContext: uiContext)
    }
    
    internal func uiTransactionContext() -> _TransactionContext {
        let context = createMainThreadContext(parent: writerContext)
        return _TransactionContext(executionContext: context,
                                   rootContext: writerContext,
                                   uiContext: context)
    }
}

extension DataContainer: MutableQueryerProtocol, ReadOnlyQueryerProtocol {
    public func fetch<T: HashableEntity>(for type: T.Type) -> FetchBuilder<T, T, T.ReadOnly> {
        .init(config: .init(), context: startTransaction().context, onUiContext: true)
    }
    
    public func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T> {
        .init(config: .init(), context: backgroundTransactionContext())
    }
    
    public func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T> {
        .init(config: .init(), context: backgroundTransactionContext())
    }
    
    public func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T> {
        .init(config: .init(), context: backgroundTransactionContext())
    }
}

extension DataContainer {
    public func startTransaction() -> Transaction {
        Transaction(context: backgroundTransactionContext(), mergePolicy: mergePolicy)
    }
    
    public func startUiTransaction() -> Transaction {
        Transaction(context: uiTransactionContext(), mergePolicy: mergePolicy)
    }
    
    public func load<T: HashableEntity>(objectID: NSManagedObjectID) -> T.ReadOnly? {
        guard let object = uiContext.object(with: objectID) as? T else { return nil }
        return T.ReadOnly(object)
    }
    
    public func load<T: HashableEntity>(objectIDs: [NSManagedObjectID]) -> [T.ReadOnly?] {
        objectIDs.map(load(objectID:))
    }
    
    public func load<T: HashableEntity>(_ object: T.ReadOnly) -> T.ReadOnly {
        guard uiContext != object.value.rawObject.managedObjectContext else { return object }
        let newObject = uiContext.receive(runtimeObject: object.value) as! T
        return T.ReadOnly(newObject)
    }
}
