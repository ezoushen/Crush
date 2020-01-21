//
//  DataContainer.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

class Test: EntityObject { }
public class DataContainer {
    private(set) public var context: ReadOnlyTransactionContext!
    
    private var _defaultSerialBackgroundContext: _ReadWriteSerialTransactionContext!
    private var _defaultAsyncBackgroundContext: _ReadWriteAsyncTransactionContext!
    private var _writerContext: NSManagedObjectContext!
    private var _readOnlyContext: NSManagedObjectContext! = nil
    
    let connection: Connection
        
    public init(
        connection: Connection,
        completion: @escaping () -> Void = {}
    ) throws {
        self.connection = connection
        try self.connect(completion: completion)
    }
    
    private func connect(completion: @escaping () -> Void) throws {
        try connection.connect { [weak self] in
            guard let `self` = self else { return }
            self.initializeAllContext()
            DispatchQueue.main.async(execute: completion)
        }
    }
    
    private func initializeAllContext() {
        let writerContext = createWriterContext()
        let readOnlyContext = createReadOnlyContext(parent: writerContext)
        let privateContext = createBackgroundContext(parent: writerContext)
        
        context = _ReadOnlyTransactionContext(context: readOnlyContext,
                                            readOnlyContext: readOnlyContext,
                                            writerContext: writerContext)
        _defaultSerialBackgroundContext = _ReadWriteSerialTransactionContext(context: privateContext,
                                                                            readOnlyContext: readOnlyContext,
                                                                            writerContext: writerContext)
        
        _defaultAsyncBackgroundContext = _ReadWriteAsyncTransactionContext(context: privateContext,
                                                                          readOnlyContext: readOnlyContext,
                                                                          writerContext: writerContext)
        
        _writerContext = writerContext
        _readOnlyContext = readOnlyContext
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

extension DataContainer: TransactionContextProviderProtocol {
    @inline(__always)
    internal var serialContext: _ReadWriteSerialTransactionContext {
        return _defaultSerialBackgroundContext
    }
    
    @inline(__always)
    internal var asyncContext: _ReadWriteAsyncTransactionContext {
        return _defaultAsyncBackgroundContext
    }
}
