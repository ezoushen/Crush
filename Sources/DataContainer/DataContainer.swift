//
//  DataContainer.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

extension Notification.Name {
    public static let DataContainerDidRefreshUiContext: Notification.Name = .init("Notification.Name.DataContainerDidRefreshUiContext")
}

public class DataContainer {
    internal var writerContext: NSManagedObjectContext!
    internal var uiContext: NSManagedObjectContext!

    public enum LogLevel {
        case info, warning, error, critical
    }

    public var logger: LogHandler = .default
    
    let connection: Connection
    
    let mergePolicy: NSMergePolicy
        
    public init(
        connection: Connection,
        mergePolicy: NSMergePolicy = .error,
        completion: @escaping () -> Void = {}
    ) throws {
        self.connection = connection
        self.mergePolicy = mergePolicy
        
        let block = { [weak self] in
            guard let `self` = self else { return }
            self.initializeAllContext()
            DispatchQueue.main.async(execute: completion)
        }
        
        connection.isConnected
            ? block()
            : try connection.connect(completion: block)
    }
    
    private func initializeAllContext() {
        writerContext = createWriterContext()
        uiContext = createUiContext(parent: writerContext)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(writerContextDidSave),
            name: Notification.Name.NSManagedObjectContextDidSave,
            object: writerContext)
    }
    
    @objc private func writerContextDidSave(notification: Notification) {
        uiContext.perform(
            #selector(self.uiContext.mergeChanges(fromContextDidSave:)),
            on: .main,
            with: notification,
            waitUntilDone: Thread.isMainThread)

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .DataContainerDidRefreshUiContext, object: self, userInfo: nil)
        }
    }
    
    private func createWriterContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = connection.persistentStoreCoordinator
        context.mergePolicy = mergePolicy
        context.automaticallyMergesChangesFromParent = false
        return context
    }
    
    private func createUiContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parent
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    private func createContext(parent: NSManagedObjectContext, concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        autoreleasepool {
            let context = NSManagedObjectContext(concurrencyType: concurrencyType)
            context.parent = parent
            context.automaticallyMergesChangesFromParent = false
            return context
        }
    }
    
    private func createBackgroundContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        createContext(parent: parent, concurrencyType: .privateQueueConcurrencyType)
    }
    
    private func createMainThreadContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        createContext(parent: parent, concurrencyType: .mainQueueConcurrencyType)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension DataContainer {
    internal func backgroundTransactionContext() -> _TransactionContext {
        _TransactionContext(executionContext: createBackgroundContext(parent: writerContext),
                            rootContext: writerContext,
                            uiContext: uiContext,
                            logger: logger)
    }
    
    internal func uiTransactionContext() -> _TransactionContext {
        let context = createMainThreadContext(parent: writerContext)
        return _TransactionContext(executionContext: context,
                                   rootContext: writerContext,
                                   uiContext: context,
                                   logger: logger)
    }
    
    internal func queryTransactionContext() -> _TransactionContext {
        _TransactionContext(executionContext: uiContext,
                            rootContext: writerContext,
                            uiContext: uiContext,
                            logger: logger)
    }
}

extension DataContainer: MutableQueryerProtocol, ReadOnlyQueryerProtocol {
    public func fetch<T: Entity>(for type: T.Type) -> FetchBuilder<T, ManagedObject<T>, T.ReadOnly> {
        .init(config: .init(), context: queryTransactionContext(), onUiContext: true)
    }
    
    public func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T> {
        .init(config: .init(), context: backgroundTransactionContext())
    }
    
    public func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T> {
        .init(config: .init(), context: backgroundTransactionContext())
    }
    
    public func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T> {
        .init(config: .init(), context: backgroundTransactionContext())
    }
}

extension DataContainer {
    public func startTransaction() -> Transaction {
        Transaction(context: backgroundTransactionContext(), mergePolicy: mergePolicy)
    }
    
    public func startUiTransaction() -> Transaction {
        Transaction(context: uiTransactionContext(), mergePolicy: mergePolicy)
    }
    
    public func load<T: Entity>(objectID: NSManagedObjectID) -> T.ReadOnly? {
        guard let object = uiContext.object(with: objectID) as? ManagedObject<T> else { return nil }
        return T.ReadOnly(object)
    }
    
    public func load<T: Entity>(objectIDs: [NSManagedObjectID]) -> [T.ReadOnly?] {
        objectIDs.map(load(objectID:))
    }
    
    public func load<T: Entity>(_ object: T.ReadOnly) -> T.ReadOnly {
        guard uiContext != object.value.managedObjectContext else { return object }
        let newObject = uiContext.receive(runtimeObject: object.value) as! ManagedObject<T>
        return T.ReadOnly(newObject)
    }
}

extension DataContainer {
    public struct LogHandler {
        public static var `default`: LogHandler {
            .init(
                info: { print($0) },
                warning: { print($0)},
                error: { msg, err in print(msg) },
                critical: { msg, err in print(msg) })
        }

        private static let queue: DispatchQueue = .init(
            label: "\(Bundle.main.bundleIdentifier ?? "").DataContainer.LogHandler",
            qos: .background)

        public enum Level {
            case info, warning, error, critical
        }

        private let _info: (String) -> Void
        private let _warning: (String) -> Void
        private let _error: (String, Error?) -> Void
        private let _critical: (String, Error?) -> Void

        public init(
            info: @escaping (String) -> Void,
            warning: @escaping (String) -> Void,
            error: @escaping (String, Error?) -> Void,
            critical: @escaping (String, Error?) -> Void)
        {
            _info = info
            _warning = warning
            _error = error
            _critical = critical
        }

        func log(_ level: Level, _ message: String, error: Error? = nil) {
            Self.queue.async {
                switch level {
                case .info: return _info(message)
                case .warning: return _warning(message)
                case .error: return _error(message, error)
                case .critical: return _critical(message, error)
                }
            }
        }
    }
}
