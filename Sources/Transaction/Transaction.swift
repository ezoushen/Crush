//
//  Transaction.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/2/11.
//

import CoreData

@inline(__always)
fileprivate func warning(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String) {
    #if DEBUG
    if condition() { return }
    print(message(), "to resolve this warning, you can set breakpoint at \(#file.split(separator: "/").last ?? "") \(#line)")
    #endif
}

public struct Transaction {
    internal let context: _TransactionContext
    public var enabledWarningForUnsavedChanges: Bool = true
    public var mergePolicy: NSMergePolicy {
        didSet {
            context.executionContext.mergePolicy = mergePolicy
        }
    }
    
    public func enableUndoManager() {
        context.executionContext.undoManager = UndoManager()
    }
    
    public func disableUndoManager() {
        context.executionContext.undoManager = nil
    }
    
    public func undo() {
        checkUndoManager()
        context.executionContext.undoManager?.undo()
    }
    
    public func redo() {
        checkUndoManager()
        context.executionContext.undoManager?.redo()
    }
    
    internal func checkUndoManager() {
        #if DEBUG
        if context.executionContext.undoManager == nil {
            context.logger.log(.warning, "Please enable undo manager first.")
        }
        #endif
    }
}

extension Transaction {
    public func load<T: Entity>(_ entity: T.ReadOnly) -> T.ReadOnly {
        present(entity.value)
    }

    public func load<T: Entity>(objectID: NSManagedObjectID) -> T.ReadOnly? {
        guard let object = context.uiContext.object(with: objectID) as? ManagedObject<T> else { return nil }
        return T.ReadOnly(object)
    }

    public func load<T: Entity>(objectIDs: [NSManagedObjectID]) -> [T.ReadOnly?] {
        objectIDs.map(load(objectID:))
    }

    public func edit<T: Entity>(_ entity: T.ReadOnly) -> SingularEditor<T> {
        .init(entity.value, transaction: self)
    }

    public func edit<T: Entity>(_ entities: [T.ReadOnly]) -> PluralEditor<T> {
        .init(entities.map(\.value), transaction: self)
    }

    public func edit<T: Entity, S: Entity>(_ entities: [T.ReadOnly], _ entity: S.ReadOnly) -> ArrayPairEditor<T, S> {
        .init(entities.map(\.value), entity.value, transaction: self)
    }

    public func edit<T: Entity, S: Entity>(_ entity1: T.ReadOnly, _ entity2: S.ReadOnly) -> DualEditor<T, S> {
        .init(entity1.value, entity2.value, transaction: self)
    }

    public func commit() throws {
        try context.commit()
    }

    public func commitAndWait() throws {
        try context.commitAndWait()
    }

    func present<T: Entity>(_ entity: ManagedObject<T>) -> T.ReadOnly {
        T.ReadOnly(context.present(entity))
    }
}

extension Transaction {

    // MARK: throwable

    public func async(_ block: @escaping (TransactionContext) throws -> Void, catch: ((Error) -> Void)? = nil) {
        let transactionContext = context

        transactionContext.executionContext.performAsync {
            do {
                try block(transactionContext)
            } catch {
                guard let catchBlock = `catch` else {
                    transactionContext.logger.log(.critical, "unhandled error occured", error: error)
                    return
                }
                catchBlock(error)
            }
        }
    }

    public func sync<T>(_ block: (TransactionContext) throws -> T) throws -> T {
        let transactionContext = context
        let result = try transactionContext.executionContext.performSync {
            try block(transactionContext)
        }

        warning(enabledWarningForUnsavedChanges == false || !(result is EntityObject), "Return an EntityObject is not recommended")

        return result
    }

    public func sync<T: Entity>(_ block: (TransactionContext) throws -> ManagedObject<T>?) throws -> T.ReadOnly? {
        let transactionContext = context
        let optionalResult: ManagedObject<T>? = try transactionContext.executionContext.performSync {
            try block(transactionContext)
        }

        guard let result = optionalResult else {
            return nil
        }

        warning(enabledWarningForUnsavedChanges == false || transactionContext.executionContext.performSync {
            transactionContext.executionContext.hasChanges == false || transactionContext.executionContext.concurrencyType == .mainQueueConcurrencyType
        },
               "You should commit changes in transaction before return")

        return present(result)
    }

    public func sync<T: Entity>(_ block: (TransactionContext) throws -> ManagedObject<T>) throws -> T.ReadOnly {
        let result: T.ReadOnly? = try sync {
            let value: ManagedObject<T>? = try block($0)
            return value
        }
        return result!
    }

    public func sync<T: Entity>(_ block: (TransactionContext) throws -> [ManagedObject<T>]) throws -> [T.ReadOnly]{
        let transactionContext = context

        let result: [ManagedObject<T>] = try transactionContext.executionContext.performSync {
            try block(transactionContext)
        }
        warning(enabledWarningForUnsavedChanges == false || transactionContext.executionContext.performSync {
            transactionContext.executionContext.hasChanges == false || transactionContext.executionContext.concurrencyType == .mainQueueConcurrencyType
        },
               "You should commit changes in transaction before return")

        return result.map(present(_:))
    }

    // MARK: non-throwable

    public func async(_ block: @escaping (TransactionContext) -> Void) {
        let transactionContext = context

        transactionContext.executionContext.performAsync {
            block(transactionContext)
        }
    }

    public func sync<T>(_ block: (TransactionContext) -> T) -> T {
        let transactionContext = context
        let result = transactionContext.executionContext.performSync {
            block(transactionContext)
        }

        warning(enabledWarningForUnsavedChanges == false || !(result is EntityObject), "Return an EntityObject is not recommended")

        return result
    }

    public func sync<T: Entity>(_ block: (TransactionContext) -> ManagedObject<T>?) -> T.ReadOnly? {
        let transactionContext = context
        let optionalResult: ManagedObject<T>? = transactionContext.executionContext.performSync {
            block(transactionContext)
        }

        guard let result = optionalResult else {
            return nil
        }

        warning(enabledWarningForUnsavedChanges == false || transactionContext.executionContext.performSync {
            transactionContext.executionContext.hasChanges == false || transactionContext.executionContext.concurrencyType == .mainQueueConcurrencyType
        },
               "You should commit changes in transaction before return")

        return present(result)
    }

    public func sync<T: Entity>(_ block: (TransactionContext) -> ManagedObject<T>) -> T.ReadOnly {
        let result: T.ReadOnly? = sync {
            let value: ManagedObject<T>? = block($0)
            return value
        }
        return result!
    }

    public func sync<T: Entity>(_ block: (TransactionContext) -> [ManagedObject<T>]) -> [T.ReadOnly]{
        let transactionContext = context

        let result: [ManagedObject<T>] = transactionContext.executionContext.performSync {
            block(transactionContext)
        }
        warning(enabledWarningForUnsavedChanges == false || transactionContext.executionContext.performSync {
            transactionContext.executionContext.hasChanges == false || transactionContext.executionContext.concurrencyType == .mainQueueConcurrencyType
        },
               "You should commit changes in transaction before return")

        return result.map(present(_:))
    }
}

extension Transaction {
    public struct ArrayPairEditor<T: Entity, S: Entity> {
        private let array: [ManagedObject<T>]
        private let value: ManagedObject<S>
        private let transaction: Transaction

        init(_ array: [ManagedObject<T>], _ value: ManagedObject<S>, transaction: Transaction) {
            self.array = array
            self.value = value
            self.transaction = transaction
        }
    }
}

extension Transaction.ArrayPairEditor {

    // MARK: - throwable ArrayPairEditor

    public func async(_ block: @escaping (TransactionContext, [ManagedObject<T>], ManagedObject<S>) throws -> Void, catch: ((Error) -> Void)? = nil) {
        let context = transaction.context

        context.executionContext.performAsync {
            let array = self.array.map(context.receive)
            let value = context.receive(self.value)
            do {
                try block(context, array, value)
            } catch {
                guard let catchBlock = `catch` else {
                    context.logger.log(.critical, "unhandled error occured", error: error)
                    return
                }
                catchBlock(error)
            }
        }
    }

    public func sync(_ block: (TransactionContext, [ManagedObject<T>], ManagedObject<S>) throws -> Void) throws {
        let context = transaction.context

        try context.executionContext.performSync {
            let array = self.array.map(context.receive)
            let value = context.receive(self.value)
            try block(context, array, value)
        }
    }

    public func sync<V>(_ block: (TransactionContext, [ManagedObject<T>], ManagedObject<S>) throws -> V) throws -> V {
        let context = transaction.context
        let result: V = try context.executionContext.performSync {
            try block(context, self.array.map(context.receive), context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || !(result is EntityObject), "Return an EntityObject is not recommended")

        return result
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>], ManagedObject<S>) throws -> ManagedObject<V>) throws -> V.ReadOnly {
        let context = transaction.context
        let result: ManagedObject<V> = try context.executionContext.performSync {
            return try block(context, self.array.map(context.receive), context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return transaction.present(result)
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>], ManagedObject<S>) throws -> ManagedObject<V>) throws -> V.ReadOnly? {
        let result: V.ReadOnly = try sync(block)
        return result
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>], ManagedObject<S>) throws -> [ManagedObject<V>]) throws -> [V.ReadOnly]  {
        let context = transaction.context
        let result: [ManagedObject<V>] = try context.executionContext.performSync {
            try block(context, self.array.map(context.receive), context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return result.map(transaction.present(_:))
    }

    // MARK: - non-throwable ArrayPairEditor

    public func async(_ block: @escaping (TransactionContext, [ManagedObject<T>], ManagedObject<S>) -> Void) {
        let context = transaction.context

        context.executionContext.performAsync {
            let array = self.array.map(context.receive)
            let value = context.receive(self.value)
            block(context, array, value)
        }
    }

    public func sync(_ block: (TransactionContext, [ManagedObject<T>], ManagedObject<S>) -> Void) {
        let context = transaction.context

        context.executionContext.performAndWait {
            let array = self.array.map(context.receive)
            let value = context.receive(self.value)
            block(context, array, value)
        }
    }

    public func sync<V>(_ block: (TransactionContext, [ManagedObject<T>], ManagedObject<S>) -> V) -> V {
        let context = transaction.context
        let result: V = context.executionContext.performSync {
            block(context, self.array.map(context.receive), context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || !(result is EntityObject), "Return an EntityObject is not recommended")

        return result
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>], ManagedObject<S>) -> ManagedObject<V>) -> V.ReadOnly {
        let context = transaction.context
        let result: ManagedObject<V> = context.executionContext.performSync {
            return block(context, self.array.map(context.receive), context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false ||  context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return transaction.present(result)
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>], ManagedObject<S>) -> ManagedObject<V>) -> V.ReadOnly? {
        let result: V.ReadOnly = sync(block)
        return result
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>], ManagedObject<S>) -> [ManagedObject<V>]) -> [V.ReadOnly]  {
        let context = transaction.context
        let result: [ManagedObject<V>] = context.executionContext.performSync {
            block(context, self.array.map(context.receive), context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false ||  context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return result.map(transaction.present(_:))
    }
}


extension Transaction {
    public struct SingularEditor<T: Entity> {

        private let value: ManagedObject<T>
        private let transaction: Transaction

        init(_ value: ManagedObject<T>, transaction: Transaction) {
            self.value = value
            self.transaction = transaction
        }
    }
}

extension Transaction.SingularEditor {

    // MARK: - throwable SigularEditor

    public func async(_ block: @escaping (TransactionContext, ManagedObject<T>) throws -> Void, catch: ((Error) -> Void)? = nil) {
        let context = transaction.context

        context.executionContext.performAsync {
            let value = context.receive(self.value)
            do {
                try block(context, value)
            } catch {
                guard let catchBlock = `catch` else {
                    context.logger.log(.critical, "unhandled error occured", error: error)
                    return
                }
                catchBlock(error)
            }
        }
    }

    public func sync(_ block: (TransactionContext, ManagedObject<T>) throws -> Void) throws {
        let context = transaction.context

        try context.executionContext.performSync {
            let value = context.receive(self.value)
            try block(context, value)
        }
    }

    public func sync<V>(_ block: (TransactionContext, ManagedObject<T>) throws -> V) throws -> V {
        let context = transaction.context
        let result: V = try context.executionContext.performSync {
            try block(context, context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || !(result is EntityObject), "Return an EntityObject is not recommended")

        return result
    }

    public func sync<V: Entity>(_ block: (TransactionContext, ManagedObject<T>) throws -> ManagedObject<V>) throws -> V.ReadOnly {
        let context = transaction.context
        let result: ManagedObject<V> = try context.executionContext.performSync {
            return try block(context, context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return transaction.present(result)
    }

    public func sync<V: Entity>(_ block: (TransactionContext, ManagedObject<T>) throws -> ManagedObject<V>) throws -> V.ReadOnly? {
        let result: V.ReadOnly = try sync(block)
        return result
    }

    public func sync<V: Entity>(_ block: (TransactionContext, ManagedObject<T>) throws -> [ManagedObject<V>]) throws -> [V.ReadOnly]  {
        let context = transaction.context
        let result: [ManagedObject<V>] = try context.executionContext.performSync {
            try block(context, context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return result.map(transaction.present(_:))
    }

    // MARK: - non-throwable SingularEditor

    public func async(_ block: @escaping (TransactionContext, ManagedObject<T>) -> Void) {
        let context = transaction.context

        context.executionContext.performAsync {
            let value = context.receive(self.value)
            block(context, value)
        }
    }

    public func sync(_ block: (TransactionContext, ManagedObject<T>) -> Void) {
        let context = transaction.context

        context.executionContext.performAndWait {
            let value = context.receive(self.value)
            block(context, value)
        }
    }

    public func sync<V>(_ block: (TransactionContext, ManagedObject<T>) -> V) -> V {
        let context = transaction.context
        let result: V = context.executionContext.performSync {
            block(context, context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || !(result is EntityObject), "Return an EntityObject is not recommended")

        return result
    }

    public func sync<V: Entity>(_ block: (TransactionContext, ManagedObject<T>) -> ManagedObject<V>) -> V.ReadOnly {
        let context = transaction.context
        let result: ManagedObject<V> = context.executionContext.performSync {
            return block(context, context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return transaction.present(result)
    }

    public func sync<V: Entity>(_ block: (TransactionContext, ManagedObject<T>) -> ManagedObject<V>) -> V.ReadOnly? {
        let result: V.ReadOnly = sync(block)
        return result
    }

    public func sync<V: Entity>(_ block: (TransactionContext, ManagedObject<T>) -> [ManagedObject<V>]) -> [V.ReadOnly]  {
        let context = transaction.context
        let result: [ManagedObject<V>] = context.executionContext.performSync {
            block(context, context.receive(self.value))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return result.map(transaction.present(_:))
    }
}

extension Transaction {
    public struct PluralEditor<T: Entity> {

        private let values: [ManagedObject<T>]
        private let transaction: Transaction

        init(_ values: [ManagedObject<T>], transaction: Transaction) {
            self.values = values
            self.transaction = transaction
        }
    }
}

extension Transaction.PluralEditor {

    // MARK: - throwable PluralEditor

    public func async(_ block: @escaping (TransactionContext, [ManagedObject<T>]) throws -> Void, catch: ((Error) -> Void)? = nil) {
        let context = transaction.context

        context.executionContext.performAsync {
            let values = self.values.map(context.receive(_:))
            do {
                try block(context, values)
            } catch {
                guard let catchBlock = `catch` else {
                    context.logger.log(.critical, "unhandled error occured", error: error)
                    return
                }
                catchBlock(error)
            }
        }
    }

    public func sync(_ block: (TransactionContext, [ManagedObject<T>]) throws -> Void) throws {
        let context = transaction.context

        try context.executionContext.performSync {
            let values = self.values.map(context.receive(_:))
            try block(context, values)
        }
    }

    public func sync<V>(_ block: (TransactionContext, [ManagedObject<T>]) throws -> V) throws -> V {
        let value = try transaction.context.executionContext.performSync {
            try block(self.transaction.context, self.values.map(self.transaction.context.receive(_:)))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || !(value is EntityObject), "Return an EntityObject is not recommended")

        return value
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>]) throws -> ManagedObject<V>) throws -> V.ReadOnly {
        let context = transaction.context
        let result: ManagedObject<V> = try context.executionContext.performSync {
            let values = self.values.map(context.receive(_:))
            return try block(context, values)
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return transaction.present(result)
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>]) throws -> ManagedObject<V>) throws -> V.ReadOnly? {
        let result: V.ReadOnly = try sync(block)
        return result
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>]) throws -> [ManagedObject<V>]) throws -> [V.ReadOnly] {
        let context = transaction.context
        let result: [ManagedObject<V>] = try context.executionContext.performSync {
            let values = self.values.map(context.receive(_:))
            return try block(context, values)
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return result.map(transaction.present(_:))
    }

    // MARK: - Non-throwable PluralEditor

    public func async(_ block: @escaping (TransactionContext, [ManagedObject<T>]) -> Void) {
        let context = transaction.context

        context.executionContext.performAsync {
            let values = self.values.map(context.receive(_:))
            block(context, values)
        }
    }

    public func sync(_ block: (TransactionContext, [ManagedObject<T>]) -> Void) {
        let context = transaction.context

        context.executionContext.performAndWait {
            let values = self.values.map(context.receive(_:))
            block(context, values)
        }
    }

    public func sync<V>(_ block: (TransactionContext, [ManagedObject<T>]) -> V) -> V {
        let value = transaction.context.executionContext.performSync {
            block(self.transaction.context, self.values.map(self.transaction.context.receive(_:)))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || !(value is EntityObject), "Return an EntityObject is not recommended")

        return value
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>])  -> ManagedObject<V>) -> V.ReadOnly {
        let context = transaction.context
        let result: ManagedObject<V> = context.executionContext.performSync {
            let values = self.values.map(context.receive(_:))
            return block(context, values)
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return transaction.present(result)
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>]) -> ManagedObject<V>) -> V.ReadOnly? {
        let result: V.ReadOnly = sync(block)
        return result
    }

    public func sync<V: Entity>(_ block: (TransactionContext, [ManagedObject<T>]) -> [ManagedObject<V>]) -> [V.ReadOnly] {
        let context = transaction.context
        let result: [ManagedObject<V>] = context.executionContext.performSync {
            let values = self.values.map(context.receive(_:))
            return block(context, values)
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return result.map(transaction.present(_:))
    }
}

extension Transaction {
    public struct DualEditor<T: Entity, S: Entity> {

        private let value1: ManagedObject<T>
        private let value2: ManagedObject<S>
        private let transaction: Transaction

        init(_ value1: ManagedObject<T>, _ value2: ManagedObject<S>, transaction: Transaction) {
            self.value1 = value1
            self.value2 = value2
            self.transaction = transaction
        }
    }
}

extension Transaction.DualEditor {

    // MARK: - throwable DualEditor

    public func async(_ block: @escaping (TransactionContext, ManagedObject<T>, ManagedObject<S>) throws -> Void, catch: ((Error) -> Void)? = nil) {
        let context = transaction.context

        context.executionContext.performAsync {
            do {
                try block(context, context.receive(self.value1), context.receive(self.value2))
            } catch {
               guard let catchBlock = `catch` else {
                context.logger.log(.critical, "unhandled error occured", error: error)
                    return
               }
               catchBlock(error)
           }
        }
    }

    public func sync(_ block: (TransactionContext, ManagedObject<T>, ManagedObject<S>) throws -> Void) throws {
        let context = transaction.context

        try context.executionContext.performSync {
            try block(context, context.receive(self.value1), context.receive(self.value2))
        }
    }

    public func sync<V>(_ block: (TransactionContext, ManagedObject<T>, ManagedObject<S>) throws -> V) throws -> V {
        let context = transaction.context
        let value = try transaction.context.executionContext.performSync {
            try block(self.transaction.context, context.receive(self.value1), context.receive(self.value2))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || !(value is EntityObject), "Return an EntityObject is not recommended")

        return value
    }

    public func sync<V: Entity>(_ block: (TransactionContext, ManagedObject<T>, ManagedObject<S>) throws -> ManagedObject<V>) throws -> V.ReadOnly {
        let context = transaction.context
        let result: ManagedObject<V> = try context.executionContext.performSync {
            try block(context, context.receive(self.value1), context.receive(self.value2))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return transaction.present(result)
    }

    public func sync<V: Entity>(_ block: (TransactionContext, ManagedObject<T>, ManagedObject<S>) throws -> [ManagedObject<V>]) throws -> [V.ReadOnly] {
        let context = transaction.context
        let result: [ManagedObject<V>] = try context.executionContext.performSync {
            try block(context, context.receive(self.value1), context.receive(self.value2))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return result.map(transaction.present(_:))
    }

    // MARK: - non-throwable DualEditor

    public func async(_ block: @escaping (TransactionContext, ManagedObject<T>, ManagedObject<S>) -> Void) {
        let context = transaction.context

        context.executionContext.performAsync {
            block(context, context.receive(self.value1), context.receive(self.value2))
        }
    }

    public func sync(_ block: (TransactionContext, ManagedObject<T>, ManagedObject<S>) -> Void) {
        let context = transaction.context

        context.executionContext.performAndWait {
            block(context, context.receive(self.value1), context.receive(self.value2))
        }
    }

    public func sync<V>(_ block: (TransactionContext, ManagedObject<T>, ManagedObject<S>) -> V) -> V {
        let context = transaction.context
        let value = transaction.context.executionContext.performSync {
            block(self.transaction.context, context.receive(self.value1), context.receive(self.value2))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || !(value is EntityObject), "Return an EntityObject is not recommended")

        return value
    }

    public func sync<V: Entity>(_ block: (TransactionContext, ManagedObject<T>, ManagedObject<S>) -> ManagedObject<V>) -> V.ReadOnly {
        let context = transaction.context
        let result: ManagedObject<V> = context.executionContext.performSync {
            block(context, context.receive(self.value1), context.receive(self.value2))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return transaction.present(result)
    }

    public func sync<V: Entity>(_ block: (TransactionContext, ManagedObject<T>, ManagedObject<S>) -> [ManagedObject<V>]) -> [V.ReadOnly] {
        let context = transaction.context
        let result: [ManagedObject<V>] = context.executionContext.performSync {
            block(context, context.receive(self.value1), context.receive(self.value2))
        }

        warning(transaction.enabledWarningForUnsavedChanges == false || context.executionContext.hasChanges == false || context.executionContext.concurrencyType == .mainQueueConcurrencyType,
               "You should commit changes in transaction before return")

        return result.map(transaction.present(_:))
    }
}

extension NSManagedObjectContext {
    func performAsync(_ block: @escaping () -> Void) {
        perform {
            self.undoManager?.beginUndoGrouping()
            defer {
                self.undoManager?.endUndoGrouping()
            }
            block()
        }
    }

    func performSync<T>(_ block: () throws -> T) throws -> T {
        var result: T!
        var error: Error?
        performAndWait {
            undoManager?.beginUndoGrouping()
            defer {
                undoManager?.endUndoGrouping()
            }
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

    func performSync<T>(_ block: () -> T) -> T {
        var result: T!
        performAndWait {
            undoManager?.beginUndoGrouping()
            defer {
                undoManager?.endUndoGrouping()
            }
            result = block()
        }
        return result
    }
}
