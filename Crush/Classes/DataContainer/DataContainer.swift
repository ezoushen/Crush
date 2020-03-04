//
//  DataContainer.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public class DataContainer {
    internal var writerContext: NSManagedObjectContext!
    internal var readOnlyContext: NSManagedObjectContext!
    internal var readerContext: _ReadOnlyTransactionContext!
    
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
        self.readerContext = .init(context: writerContext, targetContext: readOnlyContext)
    }
    
    private func createWriterContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = connection.persistentStoreCoordinator
        context.automaticallyMergesChangesFromParent = false
        return context
    }
    
    private func createReadOnlyContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parent
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    private func createBackgroundContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        autoreleasepool {
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            context.parent = parent
            context.stalenessInterval = 0.0
            context.retainsRegisteredObjects = false
            context.automaticallyMergesChangesFromParent = false
            return context
        }
    }
}

extension DataContainer {
    internal var serialContext: _ReadWriteSerialTransactionContext {
        _ReadWriteSerialTransactionContext(context: createBackgroundContext(parent: writerContext),
                                           targetContext: writerContext,
                                           readOnlyContext: readOnlyContext)
    }
    
    internal var asyncContext: _ReadWriteAsyncTransactionContext {
        _ReadWriteAsyncTransactionContext(context: createBackgroundContext(parent: writerContext),
                                          targetContext: writerContext,
                                          readOnlyContext: readOnlyContext)
    }
}

extension DataContainer {
    public func save() {
        guard writerContext.hasChanges else {
            return
        }
        
        withExtendedLifetime(self) { object in
            object.writerContext.perform {
                try? object.writerContext.save()
            }
        }
    }
    
    public func rollback() {
        writerContext.rollback()
        readOnlyContext.refreshAllObjects()
    }
}

extension DataContainer: QueryerProtocol {
    public func query<T: Entity>(for type: T.Type) -> QueryBuilder<T, NSManagedObject, T> {
        return QueryBuilder<T, NSManagedObject, T>(config: .init(), context: readerContext)
    }
}

extension DataContainer {
    
    public func edit<T: Entity>(_ entity: T) -> Transaction.SingularEditor<T> {
        .init(entity, transaction: transaction)
    }
    
    public func edit<T: Entity>(_ entities: [T]) -> Transaction.PluralEditor<T> {
        .init(entities, transaction: transaction)
    }
    
    public func edit<T: Entity>(_ entities: T...) -> Transaction.PluralEditor<T> {
        .init(entities, transaction: transaction)
    }
    
    public var transaction: Transaction {
        Transaction(readOnlyContext: readOnlyContext, asyncContext: asyncContext, serialContext: serialContext)
    }
}
