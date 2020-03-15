//
//  Transaction.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/2/11.
//

import CoreData

public struct Transaction {
    public typealias ReadOnlyContext = ReadOnlyTransactionContext
    public typealias ReadWriteContext = ReadWriteTransactionContext
    
    internal let readOnlyContext: NSManagedObjectContext
    internal let asyncContext: ReadWriteAsyncTransactionContext
    internal let serialContext: ReadWriteSerialTransactionContext
}

extension Transaction {
    public func async(_ block: @escaping (ReadWriteContext) -> Void) {
        let transactionContext = asyncContext

        transactionContext.context.perform {
            block(transactionContext)
            transactionContext.stash()
        }
    }
    
    public func sync<T>(_ block: @escaping (ReadWriteContext) -> T) -> T {
        let transactionContext = serialContext

        var result: T!

        transactionContext.context.performAndWait {
            result = block(transactionContext)
            transactionContext.stash()
        }

        return result
    }
    
    public func sync<T: Entity>(_ block: @escaping (ReadWriteContext) -> T?) -> T? {
        let transactionContext = serialContext

        var result: T?

        transactionContext.context.performAndWait {
            result = block(transactionContext)
            transactionContext.stash()
        }
        guard let object = result else { return nil }
        
        let readOnlyObject = readOnlyContext.receive(runtimeObject: object)

        return T.init(readOnlyObject, proxyType: ReadOnlyValueMapper.self)
    }
    
    public func sync<T: Entity>(_ block: @escaping (ReadWriteContext) -> T) -> T {
        let transactionContext = serialContext

        var result: T!

        transactionContext.context.performAndWait {
            result = block(transactionContext)
            transactionContext.stash()
        }

        let readOnlyObject = readOnlyContext.receive(runtimeObject: result)

        return T.init(readOnlyObject, proxyType: ReadOnlyValueMapper.self)
    }

    public func sync<T: Entity, S: Sequence>(_ block: @escaping (ReadWriteContext) -> S) -> S where S.Element == T {
        let transactionContext = serialContext

        var result: S!

        transactionContext.context.performAndWait {
            result = block(transactionContext)
            transactionContext.stash()
        }

        return result.compactMap { object -> T in
            let readOnlyObject = readOnlyContext.receive(runtimeObject: object)
            return T.init(readOnlyObject, proxyType: ReadOnlyValueMapper.self)
        } as! S
    }
}

extension Transaction {
    public struct SingularEditor<T: Entity> {
        
        private let _value: T
        
        let transaction: Transaction
        
        init(_ value: T, transaction: Transaction) {
            self._value = value
            self.transaction = transaction
        }
    }
}
    
extension Transaction.SingularEditor {
    public func async(_ block: @escaping (Transaction.ReadWriteContext, T) -> Void) {
        let context = transaction.asyncContext

        context.context.perform {
            let value = context.receive(self._value)
            block(context, value)
            context.stash()
        }
    }
    
    public func sync(_ block: @escaping (Transaction.ReadWriteContext, T) -> Void) {
        let context = transaction.serialContext
        
        context.context.performAndWait {
            let value = context.receive(self._value)
            block(context, value)
            context.stash()
        }
    }
    
    public func sync<V>(_ block: @escaping (Transaction.ReadWriteContext, T) -> V) -> V {
        let context = transaction.serialContext
        var result: V!
        context.context.performAndWait {
            let value = context.receive(self._value)
            result = block(context, value)
            context.stash()
        }
        return result
    }
    
    public func sync<V: Entity>(_ block: @escaping (Transaction.ReadWriteContext, T) -> V) -> V {
        let context = transaction.serialContext
        var result: V!
        context.context.performAndWait {
            let value = context.receive(self._value)
            result = block(context, value)
            context.stash()
        }
        return V.init(transaction.readOnlyContext.receive(runtimeObject: result),
                      proxyType: ReadOnlyValueMapper.self)
    }
    
    public func sync<V: Entity, S: Sequence>(_ block: @escaping (Transaction.ReadWriteContext, T) -> S) -> S where S.Element == V {
        let context = transaction.serialContext
        var result: S!
        context.context.performAndWait {
            let value = context.receive(self._value)
            result = block(context, value)
            context.stash()
        }
        return result.compactMap {
            V.init(transaction.readOnlyContext.receive(runtimeObject: $0),
                   proxyType: ReadOnlyValueMapper.self)
        } as! S
    }
}

extension Transaction {
    public struct PluralEditor<T: Entity> {
    
        private let _values: [T]
        
        let transaction: Transaction
        
        init(_ values: [T], transaction: Transaction) {
            self._values = values
            self.transaction = transaction
        }
    }
}
    
extension Transaction.PluralEditor {
    public func async(_ block: @escaping (ReadWriteAsyncTransactionContext, [T]) -> Void) {
        let context = transaction.asyncContext
        
        context.context.perform {
            let values = self._values.map(context.receive(_:))
            block(context, values)
            context.stash()
        }
    }
    
    public func sync(_ block: @escaping (Transaction.ReadWriteContext, [T]) -> Void) {
        let context = transaction.serialContext
        
        context.context.performAndWait {
            let values = self._values.map(context.receive(_:))
            block(context, values)
            context.stash()
        }
    }
    
    public func sync<V>(_ block: @escaping (Transaction.ReadWriteContext, [T]) -> V) -> V {
        let context = transaction.serialContext
        var result: V!
        context.context.performAndWait {
            let values = self._values.map(context.receive(_:))
            result = block(context, values)
            context.stash()
        }
        return result
    }
    
    public func sync<V: Entity>(_ block: @escaping (Transaction.ReadWriteContext, [T]) -> V) -> V {
        let context = transaction.serialContext
        var result: V!
        context.context.performAndWait {
            let values = self._values.map(context.receive(_:))
            result = block(context, values)
            context.stash()
        }
        return V.init(transaction.readOnlyContext.receive(runtimeObject: result),
                      proxyType: ReadOnlyValueMapper.self)
    }
    
    public func sync<V: Entity, S: Sequence>(_ block: @escaping (Transaction.ReadWriteContext, [T]) -> S) -> S where S.Element == V {
        let context = transaction.serialContext
        var result: S!
        context.context.performAndWait {
            let values = self._values.map(context.receive(_:))
            result = block(context, values)
            context.stash()
        }
        return result.compactMap {
            V.init(transaction.readOnlyContext.receive(runtimeObject: $0),
                   proxyType: ReadOnlyValueMapper.self)
        } as! S
    }
}
