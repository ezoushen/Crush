//
//  Session.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/2/11.
//

import CoreData

@inline(__always)
fileprivate func warning(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String)
{
    #if DEBUG
    guard condition() else { return }
    print(message(),
          "to resolve this warning, you can set breakpoint at " +
            "\(#file.split(separator: "/").last ?? "") \(#line)")
    #endif
}

public struct Session {
    internal let context: _SessionContext
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

    @inline(__always)
    internal func checkUndoManager() {
        #if DEBUG
        if context.executionContext.undoManager == nil {
            context.logger.log(.warning, "Please enable undo manager first.")
        }
        #endif
    }
}

extension Session {
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

extension Session {

    private func shouldWarnUnsavedChangesOnPrivateContext() -> Bool {
        guard enabledWarningForUnsavedChanges else { return false }
        let executionContext = context.executionContext
        return context.performSync {
            executionContext.hasChanges &&
                executionContext.concurrencyType == .privateQueueConcurrencyType
        }
    }

    @inline(__always)
    private func warnUnsavedChangesIfNeeded() {
        warning(shouldWarnUnsavedChangesOnPrivateContext(),
                "You should commit changes in session before return")
    }

    public func async(_ block: @escaping (SessionContext) throws -> Void, completion: ((Error?) -> Void)? = nil) {
        let context = context
        context.performAsyncUndoable {
            var error: Error?
            do {
                try block(context)
            } catch let err {
                error = err
            }
            if completion == nil, let error = error {
                context.logger.log(.critical, "unhandled error occured", error: error)
            }
            completion?(error)
        }
    }

    public func sync<Property: UnsafeSessionProperty>(
        _ block: (SessionContext) throws -> Property
    ) rethrows -> Property.Safe {
        let context = context
        let result = try context.performSyncUndoable {
            try block(context)
        }
        warnUnsavedChangesIfNeeded()
        return result.wrapped(in: self)
    }

    public func sync<T>(
        _ block: (SessionContext) throws -> T
    ) rethrows -> T {
        let result = try context.performSyncUndoable {
            try block(context)
        }
        warning(
            result is UnsafeSessionPropertyProtocol,
            "Return an \(type(of: result)) is not recommended")
        return result
    }
}

extension NSManagedObjectContext {
    @inlinable
    func performAsync(_ block: @escaping () -> Void) {
        perform(block)
    }

    func performSync<T>(_ block: () throws -> T) rethrows -> T {
        func execute(
            _ block: () throws -> T,
            rethrowing: (Error) throws -> Void) rethrows -> T
        {
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
                try rethrowing(error)
            }

            return result
        }

        return try execute(block, rethrowing: { throw $0 })
    }

    private func undoable<T>(_ block: () throws -> T) rethrows -> T {
        undoManager?.beginUndoGrouping()
        defer {
            undoManager?.endUndoGrouping()
        }
        return try block()
    }

    func performAsyncUndoable(_ block: @escaping () -> Void) {
        performAsync { self.undoable(block) }
    }

    func performSyncUndoable<T>(_ block: () throws -> T) rethrows -> T {
        try performSync { try undoable(block) }
    }
}


extension _SessionContext {
    func performAsync(_ block: @escaping () -> Void) {
        executionContext.performAsync(block)
    }

    func performSync<T>(_ block: () throws -> T) rethrows -> T {
        try executionContext.performSync(block)
    }

    func performAsyncUndoable(_ block: @escaping () -> Void) {
        executionContext.performAsyncUndoable(block)
    }

    func performSyncUndoable<T>(_ block: () throws -> T) rethrows -> T {
        try executionContext.performSyncUndoable(block)
    }
}
