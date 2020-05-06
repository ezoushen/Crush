//
//  Transaction.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/2/11.
//

import CoreData

public struct Transaction {
    internal let context: _TransactionContext
}

extension Transaction {
    public func load<T: HashableEntity>(_ entity: T.ReadOnly) -> T.ReadOnly {
        present(entity.value)
    }
    
    public func edit<T: HashableEntity>(_ entity: T.ReadOnly) -> SingularEditor<T> {
        .init(entity.value, transaction: self)
    }
    
    public func edit<T: HashableEntity>(_ entities: [T.ReadOnly]) -> PluralEditor<T> {
        .init(entities.map(\.value), transaction: self)
    }
    
    public func edit<T: HashableEntity, S: HashableEntity>(_ entity1: T.ReadOnly, _ entity2: S.ReadOnly) -> DualEditor<T, S> {
        .init(entity1.value, entity2.value, transaction: self)
    }
    
    public func commit() {
        context.commit()
    }
    
    func present<T: HashableEntity>(_ entity: T) -> T.ReadOnly {
        T.ReadOnly(context.present(entity))
    }
}

extension Transaction {
    public func async(_ block: @escaping (TransactionContext) -> Void) {
        let transactionContext = context
        
        transactionContext.executionContext.perform {
            block(transactionContext)
        }
    }
    
    public func sync<T>(_ block: @escaping (TransactionContext) throws -> T) throws -> T {
        let transactionContext = context
        let result = try transactionContext.executionContext.performAndWait {
            try block(transactionContext)
        }
        
        assert(!(result is EntityObject), "Return an EntityObject is not recommended")
        
        return result
    }
    
    public func sync<T: HashableEntity>(_ block: @escaping (TransactionContext) throws -> T) throws -> T.ReadOnly {
        let transactionContext = context
        let result: T = try transactionContext.executionContext.performAndWait {
            try block(transactionContext)
        }
        
        assert(transactionContext.executionContext.hasChanges == false || transactionContext.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return present(result)
    }

    public func sync<T: HashableEntity>(_ block: @escaping (TransactionContext) throws -> [T]) throws -> [T.ReadOnly]{
        let transactionContext = context

        let result: [T] = try transactionContext.executionContext.performAndWait {
            try block(transactionContext)
        }
        assert(transactionContext.executionContext.hasChanges == false || transactionContext.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")
        
        return result.map(present(_:))
    }
}

extension Transaction {
    public struct SingularEditor<T: Entity> {
        
        private let value: T
        private let transaction: Transaction
        
        init(_ value: T, transaction: Transaction) {
            self.value = value
            self.transaction = transaction
        }
    }
}
    
extension Transaction.SingularEditor {
    public func async(_ block: @escaping (TransactionContext, T) -> Void) {
        let context = transaction.context

        context.executionContext.perform {
            let value = context.receive(self.value)
            block(context, value)
        }
    }
    
    public func sync(_ block: @escaping (TransactionContext, T) throws -> Void) throws {
        let context = transaction.context
        
        try context.executionContext.performAndWait {
            let value = context.receive(self.value)
            try block(context, value)
        }
    }
    
    public func sync<V>(_ block: @escaping (TransactionContext, T) throws -> V) throws -> V {
        let context = transaction.context
        let result: V = try context.executionContext.performAndWait {
            try block(context, context.receive(self.value))
        }
        
        assert(!(result is EntityObject), "Return an EntityObject is not recommended")
        
        return result
    }
    
    public func sync<V: HashableEntity>(_ block: @escaping (TransactionContext, T) throws -> V) throws -> V.ReadOnly {
        let context = transaction.context
        let result: V = try context.executionContext.performAndWait {
            return try block(context, context.receive(self.value))
        }
        
        assert(context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")
        
        return transaction.present(result)
    }
    
    public func sync<V: HashableEntity>(_ block: @escaping (TransactionContext, T) throws -> [V]) throws -> [V.ReadOnly]  {
        let context = transaction.context
        let result: [V] = try context.executionContext.performAndWait {
            try block(context, context.receive(self.value))
        }
        
        assert(context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")
        
        return result.map(transaction.present(_:))
    }
}

extension Transaction {
    public struct PluralEditor<T: Entity> {
    
        private let values: [T]
        private let transaction: Transaction
        
        init(_ values: [T], transaction: Transaction) {
            self.values = values
            self.transaction = transaction
        }
    }
}
    
extension Transaction.PluralEditor {
    public func async(_ block: @escaping (TransactionContext, [T]) -> Void) {
        let context = transaction.context
        
        context.executionContext.perform {
            let values = self.values.map(context.receive(_:))
            block(context, values)
        }
    }
    
    public func sync(_ block: @escaping (TransactionContext, [T]) throws -> Void) throws {
        let context = transaction.context
        
        try context.executionContext.performAndWait {
            let values = self.values.map(context.receive(_:))
            try block(context, values)
        }
    }
    
    public func sync<V>(_ block: @escaping (TransactionContext, [T]) throws -> V) throws -> V {
        let value = try transaction.context.executionContext.performAndWait {
            try block(self.transaction.context, self.values.map(self.transaction.context.receive(_:)))
        }
        
        assert(!(value is EntityObject), "Return an EntityObject is not recommended")
        
        return value
    }
    
    public func sync<V: HashableEntity>(_ block: @escaping (TransactionContext, [T]) throws -> V) throws -> V.ReadOnly {
        let context = transaction.context
        let result: V = try context.executionContext.performAndWait {
            let values = self.values.map(context.receive(_:))
            return try block(context, values)
        }
        
        assert(context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")
        
        return transaction.present(result)
    }
    
    public func sync<V: HashableEntity>(_ block: @escaping (TransactionContext, [T]) throws -> [V]) throws -> [V.ReadOnly] {
        let context = transaction.context
        let result: [V] = try context.executionContext.performAndWait {
            let values = self.values.map(context.receive(_:))
            return try block(context, values)
        }
        
        assert(context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")
        
        return result.map(transaction.present(_:))
    }
}

extension Transaction {
    public struct DualEditor<T: Entity, S: Entity> {
    
        private let value1: T
        private let value2: S
        private let transaction: Transaction
        
        init(_ value1: T, _ value2: S, transaction: Transaction) {
            self.value1 = value1
            self.value2 = value2
            self.transaction = transaction
        }
    }
}
    
extension Transaction.DualEditor {
    public func async(_ block: @escaping (TransactionContext, T, S) -> Void) {
        let context = transaction.context
        
        context.executionContext.perform {
            block(context, context.receive(self.value1), context.receive(self.value2))
        }
    }
    
    public func sync(_ block: @escaping (TransactionContext, T, S) throws -> Void) throws {
        let context = transaction.context
        
        try context.executionContext.performAndWait {
            try block(context, context.receive(self.value1), context.receive(self.value2))
        }
    }
    
    public func sync<V>(_ block: @escaping (TransactionContext, T, S) throws -> V) throws -> V {
        let context = transaction.context
        let value = try transaction.context.executionContext.performAndWait {
            try block(self.transaction.context, context.receive(self.value1), context.receive(self.value2))
        }
        
        assert(!(value is EntityObject), "Return an EntityObject is not recommended")
        
        return value
    }
    
    public func sync<V: HashableEntity>(_ block: @escaping (TransactionContext, T, S) throws -> V) throws -> V.ReadOnly {
        let context = transaction.context
        let result: V = try context.executionContext.performAndWait {
            try block(context, context.receive(self.value1), context.receive(self.value2))
        }
        
        assert(context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")
        
        return transaction.present(result)
    }
    
    public func sync<V: HashableEntity>(_ block: @escaping (TransactionContext, T, S) throws -> [V]) throws -> [V.ReadOnly] {
        let context = transaction.context
        let result: [V] = try context.executionContext.performAndWait {
            try block(context, context.receive(self.value1), context.receive(self.value2))
        }
        
        assert(context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")
        
        return result.map(transaction.present(_:))
    }
}

extension NSManagedObjectContext {
    func performAndWait<T>(_ block: @escaping () throws -> T) throws -> T {
        var result: T!
        var error: Error?
        performAndWait {
            do {
                result = try block()
            } catch(let err) {
                error = err
            }
        }
        if let error = error {
            throw error
        }
        return result
    }
}
