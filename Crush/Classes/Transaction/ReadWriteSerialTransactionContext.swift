//
//  ReadWriteTransactionContext.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public typealias ReadWriteSerialTransactionContext = ReadWriteTransactionContext & RawContextProviderProtocol
public typealias ReadWriteAsyncTransactionContext = ReadWriteSerialTransactionContext & AsynchronousContextProtocol

internal struct _ReadWriteSerialTransactionContext: ReadWriteSerialTransactionContext {
    internal let context: NSManagedObjectContext
    internal let targetContext: NSManagedObjectContext
    internal let readOnlyContext: NSManagedObjectContext
    
    internal init(context: NSManagedObjectContext, targetContext: NSManagedObjectContext, readOnlyContext: NSManagedObjectContext) {
        self.context = context
        self.targetContext = targetContext
        self.readOnlyContext = readOnlyContext
    }
    
    
    public func stash() {
        guard context.hasChanges else {
            return
        }
        
        withExtendedLifetime(self) { object in
            object.context.performAndWait {
                try? object.context.save()
                
                object.readOnlyContext.performAndWait {
                    object.readOnlyContext.refreshAllObjects()
                }
            }
        }
    }
    
    public func commit() {
        guard context.hasChanges else {
            return
        }
        
        withExtendedLifetime(self) { object in
            object.context.performAndWait {
                try? object.context.save()

                object.targetContext.perform {
                    try? object.targetContext.save()
                }
                
                object.readOnlyContext.performAndWait {
                    object.readOnlyContext.refreshAllObjects()
                }
            }
        }
    }
}

internal struct _ReadWriteAsyncTransactionContext: ReadWriteAsyncTransactionContext {
    internal let context: NSManagedObjectContext
    internal let targetContext: NSManagedObjectContext
    internal let readOnlyContext: NSManagedObjectContext
    
    internal init(context: NSManagedObjectContext, targetContext: NSManagedObjectContext, readOnlyContext: NSManagedObjectContext) {
        self.context = context
        self.targetContext = targetContext
        self.readOnlyContext = readOnlyContext
    }
    
    public func stash() {
        guard context.hasChanges else {
            return
        }
        
        withExtendedLifetime(self) { object in
            object.context.perform {
                try? object.context.save()
                
                object.readOnlyContext.perform {
                    object.readOnlyContext.refreshAllObjects()
                }
            }
        }
    }
    
    public func commit() {
        guard context.hasChanges else {
            return
        }
        
        withExtendedLifetime(self) { object in
            object.context.perform {
                try? object.context.save()

                object.targetContext.perform {
                    try? object.targetContext.save()
                }
                
                object.readOnlyContext.perform {
                    object.readOnlyContext.refreshAllObjects()
                }
            }
        }
    }
}

extension ReadWriteTransactionContext where Self: RawContextProviderProtocol{
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
}
