//
//  Session.swift
//  Crush
//
//  Created by ezou on 2020/2/11.
//

import CoreData

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

public class Session {
    internal let context: SessionContext & RawContextProviderProtocol
    public var enabledWarningForUnsavedChanges: Bool = true
    public var mergePolicy: NSMergePolicy {
        didSet {
            context.executionContext.mergePolicy = mergePolicy
        }
    }

    internal init(context: SessionContext & RawContextProviderProtocol, mergePolicy: NSMergePolicy) {
        self.context = context
        self.mergePolicy = mergePolicy
        
        context.executionContext.mergePolicy = mergePolicy
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

extension Session {
    public func load<T: Entity>(_ entity: T.ReadOnly) -> T.ReadOnly {
        present(entity.managedObject)
    }

    public func load<T: Entity>(objectID: NSManagedObjectID) -> T.ReadOnly? {
        guard let object = context.uiContext.object(with: objectID) as? ManagedObject<T> else { return nil }
        return T.ReadOnly(object)
    }

    public func load<T: Entity>(objectIDs: [NSManagedObjectID]) -> [T.ReadOnly?] {
        objectIDs.lazy.map(load(objectID:))
    }

    public func load<T: Entity>(forURIRepresentation uri: URL) -> T.ReadOnly? {
        guard let managedObjectID = context.rootContext.persistentStoreCoordinator!
                .managedObjectID(forURIRepresentation: uri) else { return nil }
        return load(objectID: managedObjectID)
    }

    public func commit() throws {
        try context.performSync {
            let executionContext = context.executionContext
            executionContext.transactionAuthor = executionContext.name
            try context.commit()
            executionContext.transactionAuthor = nil
        }
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

    private func warnUnsavedChangesIfNeeded() {
        warning(shouldWarnUnsavedChangesOnPrivateContext(),
                "You should commit changes in session before return")
    }

    public func async(
        name: String? = nil,
        block: @escaping (SessionContext) throws -> Void,
        completion: ((Error?) -> Void)? = nil)
    {
        let context = context
        let executionContext = context.executionContext
        context.performAsyncUndoable {
            executionContext.transactionAuthor = name ?? executionContext.name
            defer { executionContext.transactionAuthor = nil }
            do {
                try block(context)
            } catch {
                if completion == nil {
                    context.logger.log(.critical, "unhandled error occured", error: error)
                }
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }

    public func sync<Property: UnsafeSessionProperty>(
        name: String? = nil,
        block: (SessionContext) throws -> Property
    ) rethrows -> Property.Safe {
        let context = context
        let executionContext = context.executionContext
        let result: Property = try context.performSyncUndoable {
            executionContext.transactionAuthor = name ?? executionContext.name
            defer { executionContext.transactionAuthor = nil }
            return try block(context)
        }
        warnUnsavedChangesIfNeeded()
        return result.wrapped(in: self)
    }

    public func sync<T>(
        name: String? = nil,
        block: (SessionContext) throws -> T
    ) rethrows -> T {
        let executionContext = context.executionContext
        let result: T = try context.performSyncUndoable {
            executionContext.transactionAuthor = name ?? executionContext.name
            defer { executionContext.transactionAuthor = nil }
            return try block(context)
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

extension SessionContext where Self: RawContextProviderProtocol {
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
#if canImport(_Concurrency) && compiler(>=5.5.2)
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension Session {
    public func async<T>(
        name: String? = nil,
        schedule: NSManagedObjectContext.ScheduledType = .immediate,
        block: @escaping (SessionContext) -> T) async -> T
    {
        let context = context
        let executionContext = context.executionContext
        return await executionContext.performAsyncUndoable(schedule: schedule) { () -> T in
            executionContext.transactionAuthor = name ?? executionContext.name
            defer { executionContext.transactionAuthor = nil }
            return block(context)
        }
    }

    public func async<T: UnsafeSessionProperty>(
        name: String? = nil,
        schedule: NSManagedObjectContext.ScheduledType = .immediate,
        block: @escaping (SessionContext) -> T) async -> T.Safe
    {
        let context = context
        let executionContext = context.executionContext
        let result = await executionContext.performAsyncUndoable(schedule: schedule) { () -> T in
            executionContext.transactionAuthor = name ?? executionContext.name
            defer { executionContext.transactionAuthor = nil }
            return block(context)
        }
        return result.wrapped(in: self)
    }

    public func asyncThrowing<T>(
        name: String? = nil,
        schedule: NSManagedObjectContext.ScheduledType = .immediate,
        block: @escaping (SessionContext) throws -> T) async throws -> T
    {
        let context = context
        let executionContext = context.executionContext
        return try await executionContext.performAsyncThrowingUndoable(schedule: schedule) {
            () throws -> T in
            executionContext.transactionAuthor = name ?? executionContext.name
            defer { executionContext.transactionAuthor = nil }
            return try block(context)
        }
    }

    public func asyncThrowing<T: UnsafeSessionProperty>(
        name: String? = nil,
        schedule: NSManagedObjectContext.ScheduledType = .immediate,
        block: @escaping (SessionContext) throws -> T) async throws -> T.Safe
    {
        let context = context
        let executionContext = context.executionContext
        let result = try await executionContext.performAsyncThrowingUndoable(schedule: schedule) {
            () throws -> T in
            executionContext.transactionAuthor = name ?? executionContext.name
            defer { executionContext.transactionAuthor = nil }
            return try block(context)
        }
        return result.wrapped(in: self)
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension NSManagedObjectContext {
    public enum ScheduledType {
        case immediate, enqueued

        @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
        func toScheduledTaskType() -> ScheduledTaskType {
            switch self {
            case .enqueued: return .enqueued
            case .immediate: return .immediate
            }
        }
    }

    func performAsyncUndoable<T>(
        schedule: ScheduledType,
        _ block: @escaping () -> T) async -> T
    {
        if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
            return await perform(schedule: schedule.toScheduledTaskType()) {
                let result = self.undoable(block)
                return result
            }
        } else {
            return await withCheckedContinuation { (continuation: CheckedContinuation<T, Never>) in
                let block = {
                    let result = self.undoable(block)
                    continuation.resume(returning: result)
                }
                switch schedule {
                case .immediate:
                    self.performAndWait(block)
                case .enqueued:
                    self.perform(block)
                }
            }
        }
    }

    func performAsyncThrowingUndoable<T>(
        schedule: ScheduledType,
        _ block: @escaping () throws -> T) async throws -> T
    {
        if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
            return try await perform(schedule: schedule.toScheduledTaskType()) {
                let result = try self.undoable(block)
                return result
            }
        } else {
            return try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<T, Error>) in
                let block = {
                    do {
                        let result = try self.undoable(block)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                switch schedule {
                case .immediate:
                    self.performAndWait(block)
                case .enqueued:
                    self.perform(block)
                }
            }
        }
    }
}
#endif
