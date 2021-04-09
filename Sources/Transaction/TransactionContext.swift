//
//  TransactionContext.swift
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
}

public protocol TransactionContext: QueryerProtocol, MutableQueryerProtocol {
    func create<T: Entity>(entity: T.Type) -> T
    func delete<T: Entity>(_ object: T)
    
    func commit() throws
    func commitAndWait() throws
}

extension TransactionContext where Self: RawContextProviderProtocol {
    func receive<T: NSManagedObject>(_ object: T) -> T {
        guard executionContext != object.managedObjectContext else { return object }
        return executionContext.receive(runtimeObject: object) as! T
    }
    
    func present<T: NSManagedObject>(_ object: T) -> T {
        guard uiContext != object.managedObjectContext else { return object }
        return uiContext.receive(runtimeObject: object) as! T
    }
}

extension TransactionContext where Self: RawContextProviderProtocol {
    public func fetch<T: Entity>(for type: T.Type) -> FetchBuilder<T, T, T> {
        .init(config: .init(), context: self, onUiContext: false)
    }
    
    public func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T> {
        .init(config: .init(), context: self)
    }
    
    public func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T> {
        .init(config: .init(), context: self)
    }
    
    public func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T> {
        .init(config: .init(), context: self)
    }
}

internal struct _TransactionContext: TransactionContext, RawContextProviderProtocol {
    internal let executionContext: NSManagedObjectContext
    internal let rootContext: NSManagedObjectContext
    internal let uiContext: NSManagedObjectContext
    
    internal init(executionContext: NSManagedObjectContext, rootContext: NSManagedObjectContext, uiContext: NSManagedObjectContext) {
        self.executionContext = executionContext
        self.rootContext = rootContext
        self.uiContext = uiContext
    }
}

extension TransactionContext where Self: RawContextProviderProtocol {
    func count(request: NSFetchRequest<NSFetchRequestResult>, on context: KeyPath<RawContextProviderProtocol, NSManagedObjectContext>) -> Int {
        var result: Int? = nil
        let context = self[keyPath: context]
        context.performAndWait {
            do {
                result = try context.count(for: request)
            } catch {
                print("Unabled to count the records, error:", error.localizedDescription)
            }
        }
        
        return result ?? 0
    }
    
    func execute<T>(request: NSFetchRequest<NSFetchRequestResult>, on context: KeyPath<RawContextProviderProtocol, NSManagedObjectContext>) throws -> [T] {
        let context = self[keyPath: context]
        context.processPendingChanges()
        return try context.performSync {
            return try context.fetch(request) as! [T]
        }
    }
    
    func execute<T: NSPersistentStoreResult>(request: NSPersistentStoreRequest, on context: KeyPath<RawContextProviderProtocol, NSManagedObjectContext>) throws -> T {
        let context = self[keyPath: context]
        context.processPendingChanges()
        return try context.performSync {
            let result = try context.execute(request) as! T
            
            if let changes: [AnyHashable: Any] = {
                if let result = result as? NSBatchDeleteResult {
                    return [
                        NSDeletedObjectsKey: result.result ?? []
                    ]
                } else if let result = result as? NSBatchUpdateResult {
                    return [
                        NSUpdatedObjectsKey: result.result ?? []
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
}

extension TransactionContext where Self: RawContextProviderProtocol {
    public func create<T: Entity>(entity: T.Type) -> T {
        var object: T!
        
        executionContext.performAndWait {
            object = entity.init(context: executionContext)
        }
        
        return object
    }
    
    public func delete<T: Entity>(_ object: T) {
        executionContext.performAndWait {
            executionContext.delete(object.rawObject)
        }
    }
    
    private func reset() {
        rootContext.performAndWait {
            rootContext.reset()
        }
        
        executionContext.performAndWait {
            executionContext.registeredObjects.forEach {
                executionContext.refresh($0, mergeChanges: true)
            }
        }
    }
    
    public func commit() throws {
        guard executionContext.hasChanges else {
            return
        }
        
        let err: NSError? = withExtendedLifetime(self) { transactionContext in
            var err: NSError?

            transactionContext.executionContext.performAndWait {
                do {
                    try transactionContext.executionContext.save()
                } catch let error as NSError {
                    NSLog("A saving error occurred while merging changes to the writer context.\n %@", error)
                    err = error
                }

                transactionContext.rootContext.perform {
                    do {
                        try transactionContext.rootContext.save()
                    } catch let error as NSError {
                        NSLog("A saving error occurred while merging changes to the persistent container.\n %@", error)
                        err = error
                        
                        transactionContext.reset()
                    }
                }
                                
                transactionContext.uiContext.performAndWait {
                    transactionContext.uiContext.refreshAllObjects()
                }
            }
            
            return err
        }
        
        guard let error = err else { return }
        
        throw error
    }
    
    public func commitAndWait() throws {
        guard executionContext.hasChanges else {
            return
        }
        
        let err: NSError? = withExtendedLifetime(self) { transactionContext in
            var err: NSError?

            transactionContext.executionContext.performAndWait {
                do {
                    try transactionContext.executionContext.save()
                } catch let error as NSError {
                    NSLog("A saving error occurred while merging changes to the writer context.\n %@", error)
                    err = error
                }
                
                guard err == nil else { return }

                transactionContext.rootContext.performAndWait {
                    do {
                        try transactionContext.rootContext.save()
                    } catch let error as NSError {
                        NSLog("A saving error occurred while merging changes to the persistent container.\n %@", error)
                        err = error
                    }
                }
                
                guard err == nil else {
                    return transactionContext.reset()
                }
                                
                transactionContext.uiContext.performAndWait {
                    transactionContext.uiContext.refreshAllObjects()
                }
            }
            
            return err
        }
        
        guard let error = err else { return }
        
        throw error
    }
}
