//
//  Transaction.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/2/11.
//

import CoreData

public struct Transaction {
    public typealias ReadOnlyContext = ReaderTransactionContext
    public typealias ReadWriteContext = ReadWriteTransactionContext
    
    internal let objectContext: NSManagedObjectContext
    internal let executionContext: _ReadWriteTransactionContext
}

extension Transaction {
    public func edit<T: Entity>(_ entity: T) -> SingularEditor<T> {
        .init(entity, transaction: self)
    }
    
    public func edit<T: Entity>(_ entities: [T]) -> PluralEditor<T> {
        .init(entities, transaction: self)
    }
    
    public func edit<T: Entity>(_ entities: T...) -> PluralEditor<T> {
        .init(entities, transaction: self)
    }
    
    public func commit() {
        executionContext.commit()
    }
}

extension Transaction {
    public func async(_ block: @escaping (ReadWriteContext) -> Void) {
        let transactionContext = executionContext

        transactionContext.context.perform {
            block(transactionContext)
        }
    }
    
    public func sync<T>(_ block: @escaping (ReadWriteContext) -> T) -> T {
        let transactionContext = executionContext

        var result: T!

        transactionContext.context.performAndWait {
            result = block(transactionContext)
        }

        return result
    }
    
    public func sync<T: Entity>(_ block: @escaping (ReadWriteContext) -> T?) -> T? {
        let transactionContext = executionContext

        var result: T?

        transactionContext.context.performAndWait {
            result = block(transactionContext)
        }
        guard let object = result else { return nil }
        
        assert(object.rawObject.hasChanges == false,
               "You should commit changes in transaction before return")
        
        let readOnlyObject = objectContext.receive(runtimeObject: object)

        return T.init(readOnlyObject, proxyType: .readOnly)
    }
    
    public func sync<T: Entity>(_ block: @escaping (ReadWriteContext) -> T) -> T {
        let transactionContext = executionContext

        var result: T!

        transactionContext.context.performAndWait {
            result = block(transactionContext)
        }
        
        assert(result.rawObject.hasChanges == false,
               "You should commit changes in transaction before return")

        let readOnlyObject = objectContext.receive(runtimeObject: result)

        return T.init(readOnlyObject, proxyType: .readOnly)
    }

    public func sync<T: Entity, S: Sequence>(_ block: @escaping (ReadWriteContext) -> S) -> S where S.Element == T {
        let transactionContext = executionContext

        var result: S!

        transactionContext.context.performAndWait {
            result = block(transactionContext)
        }

        return result.compactMap { object -> T in
            assert(object.rawObject.hasChanges == false,
                   "You should commit changes in transaction before return")
            let readOnlyObject = objectContext.receive(runtimeObject: object)
            return T.init(readOnlyObject, proxyType: .readOnly)
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
        let context = transaction.executionContext

        context.context.perform {
            let value = context.receive(self._value)
            block(context, value)
        }
    }
    
    public func sync(_ block: @escaping (Transaction.ReadWriteContext, T) -> Void) {
        let context = transaction.executionContext
        
        context.context.performAndWait {
            let value = context.receive(self._value)
            block(context, value)
        }
    }
    
    public func sync<V>(_ block: @escaping (Transaction.ReadWriteContext, T) -> V) -> V {
        let context = transaction.executionContext
        var result: V!
        context.context.performAndWait {
            let value = context.receive(self._value)
            result = block(context, value)
        }
        return result
    }
    
    public func sync<V: Entity>(_ block: @escaping (Transaction.ReadWriteContext, T) -> V) -> V {
        let context = transaction.executionContext
        var result: V!
        
        context.context.performAndWait {
            let value = context.receive(self._value)
            result = block(context, value)
        }
        
        assert(result.rawObject.hasChanges == false,
               "You should commit changes in transaction before return")
        
        return V.init(transaction.objectContext.receive(runtimeObject: result),
                        proxyType: .readOnly)
    }
    
    public func sync<V: Entity, S: Sequence>(_ block: @escaping (Transaction.ReadWriteContext, T) -> S) -> S where S.Element == V {
        let context = transaction.executionContext
        var result: S!
        context.context.performAndWait {
            let value = context.receive(self._value)
            result = block(context, value)
        }
        return result.compactMap { entity -> V in
            assert(entity.rawObject.hasChanges == false,
                   "You should commit changes in transaction before return")
            
            return V.init(transaction.objectContext.receive(runtimeObject: entity),
                            proxyType: .readOnly)
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
    public func async(_ block: @escaping (Transaction.ReadWriteContext, [T]) -> Void) {
        let context = transaction.executionContext
        
        context.context.perform {
            let values = self._values.map(context.receive(_:))
            block(context, values)
        }
    }
    
    public func sync(_ block: @escaping (Transaction.ReadWriteContext, [T]) -> Void) {
        let context = transaction.executionContext
        
        context.context.performAndWait {
            let values = self._values.map(context.receive(_:))
            block(context, values)
        }
    }
    
    public func sync<V>(_ block: @escaping (Transaction.ReadWriteContext, [T]) -> V) -> V {
        let context = transaction.executionContext
        var result: V!
        
        context.context.performAndWait {
            let values = self._values.map(context.receive(_:))
            result = block(context, values)
        }
        
        return result
    }
    
    public func sync<V: Entity>(_ block: @escaping (Transaction.ReadWriteContext, [T]) -> V) -> V {
        let context = transaction.executionContext
        var result: V!
        
        context.context.performAndWait {
            let values = self._values.map(context.receive(_:))
            result = block(context, values)
        }
        
        assert(result.rawObject.hasChanges == false,
               "You should commit changes in transaction before return")
        
        return V.init(transaction.objectContext.receive(runtimeObject: result),
                      proxyType: .readOnly)
    }
    
    public func sync<V: Entity, S: Sequence>(_ block: @escaping (Transaction.ReadWriteContext, [T]) -> S) -> S where S.Element == V {
        let context = transaction.executionContext
        var result: S!
        context.context.performAndWait {
            let values = self._values.map(context.receive(_:))
            result = block(context, values)
        }
        
        return result.compactMap { entity -> V in
            assert(entity.rawObject.hasChanges == false,
                   "You should commit changes in transaction before return")
            
            return V.init(transaction.objectContext.receive(runtimeObject: entity),
                          proxyType: .readOnly)
        } as! S
    }
}
