//
//  DataContainer.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

class WriterManagedObjectContext: NSManagedObjectContext {
    override func save() throws {
        try super.save()
    }
}

public class DataContainer {
    internal var writerContext: NSManagedObjectContext!
    internal var readOnlyContext: NSManagedObjectContext!
    
    private var fetchContext: _ReadOnlyTransactionContext!
    private var presentContext: _ReadOnlyTransactionContext!
    
    let connection: Connection
        
    public init(
        connection: Connection,
        completion: @escaping () -> Void = {}
    ) throws {
        self.connection = connection
        
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
        let writerContext = createWriterContext()
        let readOnlyContext = createReadOnlyContext(parent: writerContext)
        
        self.writerContext = writerContext
        self.readOnlyContext = readOnlyContext
        
        self.fetchContext = .init(context: readOnlyContext, targetContext: writerContext)
        self.presentContext = .init(context: readOnlyContext, targetContext: readOnlyContext)
    }
    
    private func createWriterContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = connection.persistentStoreCoordinator
        context.shouldDeleteInaccessibleFaults = true
        context.automaticallyMergesChangesFromParent = false
        return context
    }
    
    private func createReadOnlyContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parent
        context.stalenessInterval = 0.0
        context.automaticallyMergesChangesFromParent = true
        context.shouldDeleteInaccessibleFaults = true
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
}

extension DataContainer {
    internal var executionContext: _ReadWriteTransactionContext {
        _ReadWriteTransactionContext(context: createBackgroundContext(parent: writerContext),
                                     targetContext: writerContext,
                                     readOnlyContext: readOnlyContext)
    }
    
    internal var uiContext: _ReadWriteTransactionContext {
        _ReadWriteTransactionContext(context: createMainThreadContext(parent: writerContext),
                                     targetContext: writerContext,
                                     readOnlyContext: readOnlyContext)
    }
}

extension DataContainer: MutableQueryerProtocol {
    public func fetch<T: Entity>(for type: T.Type) -> FetchBuilder<T, ManagedObject, T> {
        .init(config: .init(), context: fetchContext)
    }
    
    public func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T> {
        .init(config: .init(), context: startTransaction().executionContext)
    }
    
    public func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T> {
        .init(config: .init(), context: startTransaction().executionContext)
    }
    
    public func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T> {
        .init(config: .init(), context: startTransaction().executionContext)
    }
}

extension DataContainer {
    public func startTransaction() -> Transaction {
        Transaction(presentContext: presentContext, executionContext: executionContext)
    }
    
    public func startUiTransaction() -> Transaction {
        let context = uiContext
        return Transaction(presentContext: context, executionContext: context)
    }
    
    public func load<T: Entity>(objectID: NSManagedObjectID) -> T {
        T.init(objectID: objectID, in: readOnlyContext, proxyType: .readOnly)
    }
    
    public func load<T: Entity>(objectIDs: [NSManagedObjectID]) -> [T] {
        objectIDs.map(load(objectID:))
    }
}
