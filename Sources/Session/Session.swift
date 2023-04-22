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
    internal let context: SessionContext
    /// A flag that indicates whether a warning message should be logged when saving changes that have not been committed to disk.
    public var enabledWarningForUnsavedChanges: Bool = true
    /// The merge policy to be used for the session.
    public var mergePolicy: NSMergePolicy {
        didSet {
            context.executionContext.mergePolicy = mergePolicy
        }
    }

    /// The name of the session.
    public var name: String? {
        context.executionContext.name
    }

    /**
     Initializes a new instance of `Session`.

     - Parameters:
        - context: The context of the session.
        - mergePolicy: The merge policy to be used for the session.
     */
    internal init(context: SessionContext, mergePolicy: NSMergePolicy) {
        self.context = context
        self.mergePolicy = mergePolicy

        context.executionContext.mergePolicy = mergePolicy
    }

    /**
     Enables the undo manager for the session.
     */
    public func enableUndoManager() {
        context.executionContext.undoManager = UndoManager()
    }

    /**
     Disables the undo manager for the session.
     */
    public func disableUndoManager() {
        context.executionContext.undoManager = nil
    }

    /**
     Undoes the last change made to the session.
     */
    public func undo() {
        checkUndoManager()
        context.executionContext.undoManager?.undo()
    }

    /**
     Redoes the last change that was undone in the session.
     */
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
    /**
        Loads the entity and returns its read-only representation.

        - Parameter entity: The entity to be loaded.
        - Returns: The read-only representation of the entity.
    */
    public func load<T: Entity>(_ entity: T.ReadOnly) -> T.ReadOnly {
        T.ReadOnly(object: context.present(entity.managedObject))
    }

    /**
        Loads the entity with the given object ID and returns its read-only representation.

        - Parameters:
          - objectID: The object ID of the entity to be loaded.
          - isFault: A Boolean value indicating whether the entity should be returned as a fault object.
        - Returns: The read-only representation of the entity if found; otherwise, nil.
    */
    public func load<T: Entity>(objectID: NSManagedObjectID, isFault: Bool = true) -> T.ReadOnly? {
        guard let object = context.uiContext
            .load(objectID: objectID, isFault: isFault) as? ManagedObject<T> else { return nil }
        return T.ReadOnly(object)
    }

    /**
        Loads the entities with the given object IDs and returns their read-only representations.

        - Parameters:
          - objectIDs: The object IDs of the entities to be loaded.
          - isFault: A Boolean value indicating whether the entities should be returned as fault objects.
        - Returns: An array of read-only representations of the entities.
    */
    public func load<T: Entity>(objectIDs: [NSManagedObjectID], isFault: Bool = true) -> [T.ReadOnly?] {
        objectIDs.lazy.map { load(objectID: $0, isFault: isFault) }
    }

    /**
        Loads the entity with the given URI representation and returns its read-only representation.

        - Parameters:
          - uri: The URI representation of the entity to be loaded.
          - isFault: A Boolean value indicating whether the entity should be returned as a fault object.
        - Returns: The read-only representation of the entity if found; otherwise, nil.
    */
    public func load<T: Entity>(forURIRepresentation uri: URL, isFault: Bool = true) -> T.ReadOnly? {
        guard let managedObjectID = context.rootContext.persistentStoreCoordinator!
                .managedObjectID(forURIRepresentation: uri) else { return nil }
        return load(objectID: managedObjectID, isFault: isFault)
    }

    /**
        Commits the changes made to the session's context.
    */
    public func commit() throws {
        let context = context
        let executionContext = context.executionContext
        try executionContext.performSync {
            try executionContext.signed(authorName: executionContext.name) {
                try context.commit()
            }
        }
    }
}

extension Session {

    private func shouldWarnUnsavedChangesOnPrivateContext() -> Bool {
        guard enabledWarningForUnsavedChanges else { return false }
        let executionContext = context.executionContext
        return executionContext.performSync {
            executionContext.hasChanges &&
                executionContext.concurrencyType == .privateQueueConcurrencyType
        }
    }

    private func warnUnsavedChangesIfNeeded() {
        warning(shouldWarnUnsavedChangesOnPrivateContext(),
                "You should commit changes in session before return")
    }

    /**
        Asynchronously performs a block on the session's context, wrapped in an undoable and signed transaction.

        - parameter name: A string representing the author name of the transaction.
        - parameter block: A closure that takes a `SessionContext` argument and returns `Void`.
        - parameter completion: A closure that is called after the block completes execution. It takes an optional `Error` argument that will be non-nil if the block threw an error.
    */
    public func async(
        name: String? = nil,
        block: @escaping (SessionContext) throws -> Void,
        completion: ((Error?) -> Void)? = nil)
    {
        let context = context
        let executionContext = context.executionContext
        executionContext.performSignedUndoableAsync(authorName: name) {
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

    /**
        Synchronously performs a block on the session's context, wrapped in an undoable and signed transaction.

        The block must return a value that conforms to the `UnsafeSessionProperty` protocol. After the block
        completes execution, the session will check if there are any unsaved changes in the context and issue a warning if necessary.

        - parameter name: A string representing the author name of the transaction.
        - parameter block: A closure that takes a `SessionContext` argument and returns an object that conforms to the `UnsafeSessionProperty` protocol.
        - returns: A `Safe` container holding the object returned by the block.
    */
    public func sync<Property: UnsafeSessionProperty>(
        name: String? = nil,
        block: (SessionContext) throws -> Property
    ) rethrows -> Property.Safe {
        let context = context
        let executionContext = context.executionContext
        let result: Property = try executionContext
            .performSignedUndoableSync(authorName: name) {
                try block(context)
            }
        warnUnsavedChangesIfNeeded()
        return result.wrapped(in: self)
    }

    /**
        Synchronously performs a block on the session's context, wrapped in an undoable and signed transaction.

        After the block completes execution, the session will issue a warning if the returned value is an instance of `UnsafeSessionPropertyProtocol`.

        - parameter name: A string representing the author name of the transaction.
        - parameter block: A closure that takes a `SessionContext` argument and returns a value of any type.
        - returns: The value returned by the block.
    */
    public func sync<T>(
        name: String? = nil,
        block: (SessionContext) throws -> T
    ) rethrows -> T {
        let context = context
        let executionContext = context.executionContext
        let result: T = try executionContext
            .performSignedUndoableSync(authorName: name) {
                try block(context)
            }
        warning(
            result is UnsafeSessionPropertyProtocol,
            "Return an \(type(of: result)) is not recommended")
        return result
    }
}

protocol TaskPerformable {
    func perform(_ block: @escaping () -> Void)
    func performAndWait(_ block: () -> Void)
}

extension TaskPerformable {
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
}

extension NSManagedObjectContext: TaskPerformable {
    func undoable<T>(_ block: () throws -> T) rethrows -> T {
        undoManager?.beginUndoGrouping()
        defer {
            undoManager?.endUndoGrouping()
            processPendingChanges()
        }
        return try block()
    }
    
    func signed<T>(authorName: String?, _ block: () throws -> T) rethrows -> T {
        transactionAuthor = authorName ?? name
        defer {
            transactionAuthor = nil
        }
        return try block()
    }
    
    func performSignedUndoableAsync(authorName: String?, _ block: @escaping () -> Void) {
        performAsync {
            self.signed(authorName: authorName) {
                self.undoable(block)
            }
        }
    }
    
    func performSignedUndoableSync<T>(authorName: String?, _ block: () throws -> T) rethrows -> T {
        try performSync {
            try self.signed(authorName: authorName) {
                try self.undoable(block)
            }
        }
    }
}

#if canImport(_Concurrency) && compiler(>=5.5.2)
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension Session {
    /**
     Asynchronously performs a block of code on the session's execution context,  wrapped in an undoable and signed transaction.

     - Parameters:
        - name: An optional name to assign to the undo group associated with the performed operation.
        - schedule: The scheduling behavior to use for the block.
        - block: The block of code to execute, taking a `SessionContext` as its input and returning a value of type `T`.

     - Returns: A value of type `T`, which is the result of executing the provided block.

     - Note: This function is only available on platforms that support Swift concurrency and have a compiler version of at least 5.5.2.
     */
    public func async<T>(
        name: String? = nil,
        schedule: NSManagedObjectContext.ScheduledType = .immediate,
        _ block: @escaping (SessionContext) -> T) async -> T
    {
        let context = context
        let executionContext = context.executionContext
        return await executionContext
            .performSignedUndoableAsync(authorName: name, schedule: schedule) {
                block(context)
            }
    }

    /**
     Asynchronously performs a block of code on the session's execution context, wrapped in an undoable and signed transaction,
     where the block may contain unsafe session property access.

     - Parameters:
        - name: An optional name to assign to the undo group associated with the performed operation.
        - schedule: The scheduling behavior to use for the block.
        - block: The block of code to execute, taking a `SessionContext` as its input and returning a value of type `T`, where `T` is a type that conforms to `UnsafeSessionProperty`.

     - Returns: A value of type `T.Safe`, which is the result of executing the provided block, wrapped in a safe container type.

     - Note: This function is only available on platforms that support Swift concurrency and have a compiler version of at least 5.5.2.
     */
    public func async<T: UnsafeSessionProperty>(
        name: String? = nil,
        schedule: NSManagedObjectContext.ScheduledType = .immediate,
        _ block: @escaping (SessionContext) -> T) async -> T.Safe
    {
        let context = context
        let executionContext = context.executionContext
        let result = await executionContext
            .performSignedUndoableAsync(authorName: name, schedule: schedule) {
                block(context)
            }
        return result.wrapped(in: self)
    }

    /**
     Asynchronously performs a block of code on the session's execution context, wrapped in an undoable and signed transaction.,
     where the block may throw an error.

     - Parameters:
        - name: An optional name to assign to the undo group associated with the performed operation.
        - schedule: The scheduling behavior to use for the block.
        - block: The block of code to execute, taking a `SessionContext` as its input and returning a value of type `T`, where `T` is a type that can be thrown.

     - Returns: A value of type `T`, which is the result of executing the provided block.

     - Throws: An error of type `Error` if the block throws an error.

     - Note: This function is only available on platforms that support Swift concurrency and have a compiler version of at least 5.5.2.
     */
    public func asyncThrowing<T>(
        name: String? = nil,
        schedule: NSManagedObjectContext.ScheduledType = .immediate,
        _ block: @escaping (SessionContext) throws -> T) async throws -> T
    {
        let context = context
        let executionContext = context.executionContext
        return try await executionContext
            .performThrowingSignedUndoableAsync(authorName: name, schedule: schedule) {
                try block(context)
            }
    }

    /**
     Asynchronously performs a throwing block of code on a private context of the session in an undoable and signed transaction,
     and wraps the result in a safe object that can be accessed on any context.

     - Parameters:
       - name: An optional name for the undoable operation.
       - schedule: The type of scheduling for the block.
       - block: The throwing block of code to be performed on the session context.

     - Throws: Any error thrown by the block.

     - Returns: The result of the block, wrapped in a safe object that can be accessed on any context.

     - Note: This function is only available on platforms that support Swift concurrency and have a compiler version of at least 5.5.2.
    */
    public func asyncThrowing<T: UnsafeSessionProperty>(
        name: String? = nil,
        schedule: NSManagedObjectContext.ScheduledType = .immediate,
        _ block: @escaping (SessionContext) throws -> T) async throws -> T.Safe
    {
        let context = context
        let executionContext = context.executionContext
        let result = try await executionContext
            .performThrowingSignedUndoableAsync(authorName: name, schedule: schedule) {
                try block(context)
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

    func performSignedUndoableAsync<T>(
        authorName: String?,
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
                    let result = self.signed(authorName: authorName) {
                        self.undoable(block)
                    }
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

    func performThrowingSignedUndoableAsync<T>(
        authorName: String?,
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
                        let result = try self.signed(authorName: authorName) {
                            try self.undoable(block)
                        }
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
