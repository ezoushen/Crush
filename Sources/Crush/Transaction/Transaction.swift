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
    
    internal let presentContext: ReadOnlyContext & RawContextProviderProtocol
    internal let executionContext: ReadWriteContext & RawContextProviderProtocol
}

extension Transaction {
    public func receive<T: Entity>(_ entity: T) -> T {
        presentContext.receive(entity)
    }
    
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
    
    public func sync<T>(_ block: @escaping (ReadWriteContext) throws -> T) throws -> T {
        let transactionContext = executionContext
        return try transactionContext.context.performAndWait {
            try block(transactionContext)
        }
    }
    
    public func sync<T: Entity>(_ block: @escaping (ReadWriteContext) throws -> T) throws -> T {
        let transactionContext = executionContext
        let result: T = try transactionContext.context.performAndWait {
            try block(transactionContext)
        }
        
        assert(transactionContext.context.hasChanges == false || transactionContext.context == presentContext.context,
               "You should commit changes in transaction before return")

        return presentContext.receive(result)
    }

    public func sync<T: Entity>(_ block: @escaping (ReadWriteContext) throws -> [T]) throws -> [T]{
        let transactionContext = executionContext

        let result: [T] = try transactionContext.context.performAndWait {
            try block(transactionContext)
        }
        assert(transactionContext.context.hasChanges == false || transactionContext.context == presentContext.context,
               "You should commit changes in transaction before return")
        
        return result.compactMap(presentContext.receive(_:))
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
    public func async(_ block: @escaping (Transaction.ReadWriteContext, T) -> Void) {
        let context = transaction.executionContext

        context.context.perform {
            let value = context.receive(self.value)
            block(context, value)
        }
    }
    
    public func sync(_ block: @escaping (Transaction.ReadWriteContext, T) throws -> Void) throws {
        let context = transaction.executionContext
        
        try context.context.performAndWait {
            let value = context.receive(self.value)
            try block(context, value)
        }
    }
    
    public func sync<V>(_ block: @escaping (Transaction.ReadWriteContext, T) throws -> V) throws -> V {
        let context = transaction.executionContext
        let result: V = try context.context.performAndWait {
            try block(context, context.receive(self.value))
        }
        return result
    }
    
    public func sync<V: Entity>(_ block: @escaping (Transaction.ReadWriteContext, T) throws -> V) throws -> V {
        let context = transaction.executionContext
        let result: V = try context.context.performAndWait {
            return try block(context, context.receive(self.value))
        }
        
        assert(context.context.hasChanges == false || context.context == transaction.presentContext.context,
               "You should commit changes in transaction before return")
        
        return transaction.presentContext.receive(result)
    }
    
    public func sync<V: Entity>(_ block: @escaping (Transaction.ReadWriteContext, T) throws -> [V]) throws -> [V]  {
        let context = transaction.executionContext
        let result: [V] = try context.context.performAndWait {
            try block(context, context.receive(self.value))
        }
        
        assert(context.context.hasChanges == false || context.context == transaction.presentContext.context,
               "You should commit changes in transaction before return")
        
        return result.compactMap(transaction.presentContext.receive(_:))
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
    public func async(_ block: @escaping (Transaction.ReadWriteContext, [T]) -> Void) {
        let context = transaction.executionContext
        
        context.context.perform {
            let values = self.values.map(context.receive(_:))
            block(context, values)
        }
    }
    
    public func sync(_ block: @escaping (Transaction.ReadWriteContext, [T]) throws -> Void) throws {
        let context = transaction.executionContext
        
        try context.context.performAndWait {
            let values = self.values.map(context.receive(_:))
            try block(context, values)
        }
    }
    
    public func sync<V>(_ block: @escaping (Transaction.ReadWriteContext, [T]) throws -> V) throws -> V {
        try transaction.executionContext.context.performAndWait {
            try block(self.transaction.executionContext, self.values.map(self.transaction.executionContext.receive(_:)))
        }
    }
    
    public func sync<V: Entity>(_ block: @escaping (Transaction.ReadWriteContext, [T]) throws -> V) throws -> V {
        let context = transaction.executionContext
        let result: V = try context.context.performAndWait {
            let values = self.values.map(context.receive(_:))
            return try block(context, values)
        }
        
        assert(context.context.hasChanges == false || context.context == transaction.presentContext.context,
               "You should commit changes in transaction before return")
        
        return transaction.presentContext.receive(result)
    }
    
    public func sync<V: Entity>(_ block: @escaping (Transaction.ReadWriteContext, [T]) throws -> [V]) throws -> [V] {
        let context = transaction.executionContext
        let result: [V] = try context.context.performAndWait {
            let values = self.values.map(context.receive(_:))
            return try block(context, values)
        }
        
        assert(context.context.hasChanges == false || context.context == transaction.presentContext.context,
               "You should commit changes in transaction before return")
        
        return result.compactMap(transaction.presentContext.receive(_:))
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
