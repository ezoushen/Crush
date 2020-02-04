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
    internal let writerContext: NSManagedObjectContext
    internal let readerContext: NSManagedObjectContext
    
    internal init(context: NSManagedObjectContext, readOnlyContext readerContext: NSManagedObjectContext, writerContext: NSManagedObjectContext) {
        self.context = context
        self.writerContext = writerContext
        self.readerContext = readerContext
    }
}

internal struct _ReadWriteAsyncTransactionContext: ReadWriteAsyncTransactionContext {
    internal let context: NSManagedObjectContext
    internal let writerContext: NSManagedObjectContext
    internal let readerContext: NSManagedObjectContext

    internal init(context: NSManagedObjectContext, readOnlyContext readerContext: NSManagedObjectContext, writerContext: NSManagedObjectContext) {
        self.context = context
        self.writerContext = writerContext
        self.readerContext = readerContext
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
