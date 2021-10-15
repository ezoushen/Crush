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
    internal let coreDataStack: CoreDataStack
    internal var writerContext: NSManagedObjectContext!
    internal var uiContext: NSManagedObjectContext!

    public var logger: LogHandler = .default

    private init(
        storage: Storage,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy,
        migrationPolicy: MigrationPolicy) throws
    {
        coreDataStack = try CoreDataStack(
            storage: storage,
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
    }

    public static func load(
        storage: Storage,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy = .error,
        migrationPolicy: MigrationPolicy = LightWeightMigrationPolicy()
    ) throws -> DataContainer {
        let container = try DataContainer(
            storage: storage,
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
        try container.coreDataStack.loadPersistentStore()
        container.initializeAllContext()
        container.observingContextDidSaveNotification()
        return container
    }

    public static func loadAsync(
        storage: Storage,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy = .error,
        migrationPolicy: MigrationPolicy = LightWeightMigrationPolicy(),
        loadCompletion: @escaping (Error?) -> Void
    ) throws -> DataContainer {
        let container = try DataContainer(
            storage: storage,
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
        try container.coreDataStack.loadPersistentStoreAsync { error in
            defer { loadCompletion(error) }
            guard error == nil else { return }
            container.initializeAllContext()
            container.observingContextDidSaveNotification()
        }
        return container
    }
    
    private func initializeAllContext() {
        writerContext = coreDataStack.createWriterContext()
        uiContext = coreDataStack.createUiContext(parent: writerContext)
    }

    private func observingContextDidSaveNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(writerContextDidSave),
            name: Notification.Name.NSManagedObjectContextDidSave,
            object: writerContext)
    }
    
    @objc private func writerContextDidSave(notification: Notification) {
        uiContext.perform(
            #selector(uiContext.mergeChanges(fromContextDidSave:)),
            on: .main,
            with: notification,
            waitUntilDone: Thread.isMainThread)

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .DataContainerDidRefreshUiContext, object: self, userInfo: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension DataContainer {
    internal func backgroundTransactionContext() -> _TransactionContext {
        _TransactionContext(
            executionContext: coreDataStack.createBackgroundContext(parent: writerContext),
            rootContext: writerContext,
            uiContext: uiContext,
            logger: logger)
    }
    
    internal func uiTransactionContext() -> _TransactionContext {
        let context = coreDataStack.createMainThreadContext(parent: writerContext)
        return _TransactionContext(
            executionContext: context,
            rootContext: writerContext,
            uiContext: context,
            logger: logger)
    }
    
    internal func queryTransactionContext() -> _TransactionContext {
        _TransactionContext(
            executionContext: uiContext,
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
        Transaction(context: backgroundTransactionContext(), mergePolicy: coreDataStack.mergePolicy)
    }
    
    public func startUiTransaction() -> Transaction {
        Transaction(context: uiTransactionContext(), mergePolicy: coreDataStack.mergePolicy)
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
        let newObject = uiContext.receive(runtimeObject: object.value)
        return T.ReadOnly(newObject)
    }

    public func faultAllObjects() {
        uiContext.refreshAllObjects()
        writerContext.refreshAllObjects()
    }
}
