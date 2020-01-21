//
//  Transaction.swift
//  Crush
//
//  Created by ezou on 2019/9/27.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation

internal protocol TransactionContextProviderProtocol {
    var serialContext: _ReadWriteSerialTransactionContext { get }
    var asyncContext: _ReadWriteAsyncTransactionContext { get }
}

public protocol TransactionProtocol {
    typealias Context = ReadWriteTransactionContext
}

public protocol AsyncTransactionProtocol: TransactionProtocol {
    func startAsyncTransaction(_ block: @escaping (Context) -> Void)
    func startAsyncTransaction<T: EntityProtocol>(_ object: T, block: @escaping (Context, T) -> Void)
    func startAsyncTransaction<T: EntityProtocol>(_ objects: T... , block: @escaping (Context, [T]) -> Void)
}

public protocol SerialTransactionProtocol: TransactionProtocol {
    func startSerialTransaction<T>(_ block: @escaping (Context) -> T) -> T
    func startSerialTransaction<T: EntityProtocol>(_ block: @escaping (Context) -> T) -> T
    func startSerialTransaction<T: EntityProtocol, O>(_ object: T, block: @escaping (Context, T) -> O) -> O
    func startSerialTransaction<T: EntityProtocol, O>(_ objects: T... , block: @escaping (Context, [T]) -> O) -> O
    func startSerialTransaction<T: EntityProtocol>(_ object: T, block: @escaping (Context, T) -> Void)
    func startSerialTransaction<T: EntityProtocol>(_ objects: T... , block: @escaping (Context, [T]) -> Void)
}

extension DataContainer: AsyncTransactionProtocol {
    public func store() {
        asyncContext.save()
        serialContext.save()
    }
    
    public func rollback() {
        asyncContext.abort()
        serialContext.abort()
    }
    
    public func startAsyncTransaction(_ block: @escaping (Context) -> Void) {
        let transactionContext = self.asyncContext
        
        transactionContext.context.perform {
            block(transactionContext)
            transactionContext.stash()
        }
    }
    
    public func startAsyncTransaction<T: EntityProtocol>(_ object: T, block: @escaping (Context, T) -> Void) {
        let transactionContext = self.asyncContext

        transactionContext.context.perform {
            let newObject = transactionContext.receive(object)
            block(transactionContext, newObject)
            transactionContext.stash()
        }
    }
    
    public func startAsyncTransaction<T: EntityProtocol>(_ objects: T... , block: @escaping (Context, [T]) -> Void) {
        let transactionContext = self.asyncContext

        transactionContext.context.perform {
            let newObjects = objects.map(transactionContext.receive(_:))
            block(transactionContext, newObjects)
            transactionContext.stash()
        }
    }
}

extension DataContainer: SerialTransactionProtocol {
    public func startSerialTransaction<T>(_ block: @escaping (Context) -> T) -> T {
        let transactionContext = self.serialContext
        
        var result: T!

        transactionContext.context.performAndWait {
            result = block(transactionContext)
            transactionContext.stash()
        }
        
        return result
    }
    
    public func startSerialTransaction<T: EntityProtocol>(_ block: @escaping (Context) -> T) -> T {
        let transactionContext = self.serialContext
        
        var result: T!
        
        transactionContext.context.performAndWait {
            result = block(transactionContext)
            transactionContext.stash()
        }
        
        let readOnlyObject = transactionContext.readerContext.receive(runtimeObject: result)
        
        return T.init(readOnlyObject, proxyType: ReadOnlyValueMapper.self)
    }
    
    public func startSerialTransaction<T: EntityProtocol, S: Sequence>(_ block: @escaping (Context) -> S) -> S where S.Element == T {
        let transactionContext = self.serialContext

        var result: S!

        transactionContext.context.performAndWait {
            result = block(transactionContext)
            transactionContext.stash()
        }

        return result.compactMap { object -> T in
            let readOnlyObject = transactionContext.readerContext.receive(runtimeObject: object)
            return T.init(readOnlyObject, proxyType: ReadOnlyValueMapper.self)
        } as! S
    }
    
    public func startSerialTransaction<T: EntityProtocol>(_ objects: T... , block: @escaping (Context, [T]) -> Void) {
        let transactionContext = self.serialContext

        transactionContext.context.performAndWait {
            let newObjects = objects.map(transactionContext.receive(_:))
            block(transactionContext, newObjects)
            transactionContext.stash()
        }
    }
    
    public func startSerialTransaction<T: EntityProtocol>(_ object: T, block: @escaping (Context, T) -> Void) {
        let transactionContext = self.serialContext

        transactionContext.context.performAndWait {
            let newObject = transactionContext.receive(object)
            block(transactionContext, newObject)
            transactionContext.stash()
        }
    }
    
    public func startSerialTransaction<T: EntityProtocol, O>(_ objects: T... , block: @escaping (Context, [T]) -> O) -> O {
        let transactionContext = self.serialContext

        var result: O!
        
        transactionContext.context.performAndWait {
            let newObjects = objects.map(transactionContext.receive(_:))
            result = block(transactionContext, newObjects)
            transactionContext.stash()
        }
        
        return result
    }
    
    public func startSerialTransaction<T: EntityProtocol, O>(_ object: T, block: @escaping (Context, T) -> O) -> O {
        let transactionContext = self.serialContext

        var result: O!

        transactionContext.context.performAndWait {
            let newObject = transactionContext.receive(object)
            result = block(transactionContext, newObject)
            transactionContext.stash()
        }
        
        return result
    }
    
    public func startSerialTransaction<T: EntityProtocol, O: EntityProtocol>(_ objects: T... , block: @escaping (Context, [T]) -> O) -> O {
        let transactionContext = self.serialContext

        var result: O!
        
        transactionContext.context.performAndWait {
            let newObjects = objects.map(transactionContext.receive(_:))
            result = block(transactionContext, newObjects)
            transactionContext.stash()
        }
        
        return O.init(result, proxyType: ReadOnlyValueMapper.self)
    }
    
    public func startSerialTransaction<T: EntityProtocol, S: Sequence, O: EntityProtocol>(_ object: T, block: @escaping (Context, T) -> S) -> S where S.Element == O {
        let transactionContext = self.serialContext

        var result: S!

        transactionContext.context.performAndWait {
            let newObject = transactionContext.receive(object)
            result = block(transactionContext, newObject)
            transactionContext.stash()
        }
        
        return result.compactMap {
            O.init($0, proxyType: ReadOnlyValueMapper.self)
        } as! S
    }
}
