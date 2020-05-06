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
    func create<T: Entity>(entiy: T.Type) -> T
    func delete<T: Entity>(_ object: T)
    
    func commit()
}

extension TransactionContext where Self: RawContextProviderProtocol {
    func receive<T: Entity>(_ object: T) -> T {
        guard executionContext != object.rawObject.managedObjectContext else { return object }
        let newObject = executionContext.receive(runtimeObject: object)
        return T.init(newObject)
    }
    
    func receive<T: NSManagedObject>(_ object: T) -> T {
        guard executionContext != object.managedObjectContext else { return object }
        return executionContext.receive(runtimeObject: object) as! T
    }
    
    func present<T: Entity>(_ object: T) -> T {
        guard uiContext != object.rawObject.managedObjectContext else { return object }
        let newObject = uiContext.receive(runtimeObject: object)
        return T.init(newObject)
    }
    
    func present<T: NSManagedObject>(_ object: T) -> T {
        guard uiContext != object.managedObjectContext else { return object }
        return uiContext.receive(runtimeObject: object) as! T
    }
}

extension TransactionContext where Self: RawContextProviderProtocol {
    public func fetch<T: Entity>(for type: T.Type) -> FetchBuilder<T, ManagedObject, T> {
        .init(config: .init(), context: self)
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
    func count(request: NSFetchRequest<NSFetchRequestResult>) -> Int {
        var result: Int? = nil
        
        rootContext.performAndWait {
            do {
                result = try rootContext.count(for: request)
            } catch {
                print("Unabled to count the records, error:", error.localizedDescription)
            }
        }
        
        return result ?? 0
    }
    
    func execute<T>(request: NSFetchRequest<NSFetchRequestResult>) throws -> [T] {
        rootContext.processPendingChanges()

        return try rootContext.performAndWait {
            return try self.rootContext.fetch(request) as! [T]
        }
    }
    
    func execute<T: NSPersistentStoreResult>(request: NSPersistentStoreRequest) throws -> T {
        rootContext.processPendingChanges()

        return try rootContext.performAndWait {
            return try self.rootContext.execute(request) as! T
        }
    }
}

extension TransactionContext where Self: RawContextProviderProtocol {
    public func create<T: Entity>(entiy: T.Type) -> T {
        var object: T!
        
        executionContext.performAndWait {
            object = entiy.init(context: executionContext)
        }
        
        return object
    }
    
    public func delete<T: Entity>(_ object: T) {
        executionContext.performAndWait {
            executionContext.delete(object.rawObject)
        }
    }
    
    public func commit() {
        guard executionContext.hasChanges else {
            return
        }
        withExtendedLifetime(self) { transactionContext in
            transactionContext.executionContext.performAndWait {
                do {
                    try transactionContext.executionContext.save()
                } catch {
                    assertionFailure(error.localizedDescription)
                }

                transactionContext.rootContext.perform {
                    do {
                        try transactionContext.rootContext.save()
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
                                
                transactionContext.uiContext.performAndWait {
                    transactionContext.uiContext.refreshAllObjects()
                }
            }
        }
    }
}
