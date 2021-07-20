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

    public func sync<T>(_ block: (TransactionContext) throws -> T) rethrows -> T {
        let transactionContext = context
        let result = try transactionContext.executionContext.performSync {
            try block(transactionContext)
        }

        warning(enabledWarningForUnsavedChanges == false || !(result is EntityObject), "Return an EntityObject is not recommended")

        return result
    }

    public func sync<T: Entity>(_ block: (TransactionContext) throws -> ManagedObject<T>?) rethrows -> T.ReadOnly? {
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

    public func sync<T: Entity>(_ block: (TransactionContext) throws -> ManagedObject<T>) rethrows -> T.ReadOnly {
        try sync { context -> ManagedObject<T>? in
            try block(context)
        }!
    }

    public func sync<T: Entity>(_ block: (TransactionContext) throws -> [ManagedObject<T>]) rethrows -> [T.ReadOnly] {
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

    func performSync<T>(_ block: () throws -> T) rethrows -> T {
        func execute(_ block: () throws -> T, rethrowing: (Error) throws -> Void) rethrows -> T {
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
                try rethrowing(error)
            }

            return result
        }

        return try execute(block, rethrowing: { throw $0 })
    }
}
