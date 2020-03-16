//
//  ReadWriteTransactionContext.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

internal struct _ReadWriteTransactionContext: ReadWriteTransactionContext & RawContextProviderProtocol {
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
    public var proxyType: Proxy.Type {
        return ReadWriteValueMapper.self
    }
    
    public func create<T: Entity>(entiy: T.Type) -> T {
        var object: T!
        
        context.performAndWait {
            object = entiy.create(context: context, proxyType: proxyType)
        }
        
        return object
    }
    
    public func delete<T: Entity>(_ object: T) {
        context.performAndWait {
            context.delete(object.rawObject)
        }
    }
    
    public func commit() {
        guard context.hasChanges else {
            return
        }
        
        withExtendedLifetime(self) { object in
            object.context.performAndWait {
                try! object.context.save()

                object.targetContext.perform {
                    try! object.targetContext.save()
                }
                
                object.readOnlyContext.performAndWait {
                    object.readOnlyContext.refreshAllObjects()
                }
            }
        }
    }
}
