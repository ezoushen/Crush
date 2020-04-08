//
//  ReadWriteTransactionContext.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

internal struct _ReadWriteTransactionContext: ReadWriteTransactionContext, RawContextProviderProtocol {
    internal let context: NSManagedObjectContext
    internal let targetContext: NSManagedObjectContext
    internal let readOnlyContext: NSManagedObjectContext
    
    internal init(context: NSManagedObjectContext, targetContext: NSManagedObjectContext, readOnlyContext: NSManagedObjectContext) {
        self.context = context
        self.targetContext = targetContext
        self.readOnlyContext = readOnlyContext
    }
    
}

extension _ReadWriteTransactionContext {
    public var proxyType: PropertyProxyType {
        return .readWrite
    }
    
    public func create<T: Entity>(entiy: T.Type) -> T {
        var object: T!
        
        context.performAndWait {
            object = entiy.init(context: context, proxyType: proxyType)
        }
        
        return object
    }
    
    public func delete<T: Entity>(_ object: T) {
        context.performAndWait {
            context.delete(object.rawObject)
        }
    }
    
    public func stash() {
        guard context.hasChanges else {
            return
        }
        withExtendedLifetime(self) { transactionContext in
            transactionContext.context.performAndWait {
                do {
                    try transactionContext.context.save()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
                                
                transactionContext.readOnlyContext.performAndWait {
                    transactionContext.readOnlyContext.refreshAllObjects()
                }
            }
        }
    }
    
    public func commit() {
        guard context.hasChanges else {
            return
        }
        withExtendedLifetime(self) { transactionContext in
            transactionContext.context.performAndWait {
                do {
                    try transactionContext.context.save()
                } catch {
                    assertionFailure(error.localizedDescription)
                }

                transactionContext.targetContext.perform {
                    do {
                        try transactionContext.targetContext.save()
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
                                
                transactionContext.readOnlyContext.performAndWait {
                    transactionContext.readOnlyContext.refreshAllObjects()
                }
            }
        }
    }
}
