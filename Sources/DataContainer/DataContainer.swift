//
//  DataContainer.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

extension Notification.Name {
    public static let DataContainerDidRefreshUiContext = Notification.Name("DataContainerDidRefreshUiContext")
}

public class DataContainer {
    internal let coreDataStack: CoreDataStack
    internal var writerContext: NSManagedObjectContext!
    internal var uiContext: NSManagedObjectContext!
    internal let createdDate: Date = Date()

    internal lazy var persistentHistoryTracker =
        PersistentHistoryTracker(
            context: backgroundSessionContext(),
            coordinator: coreDataStack.coordinator)

    public var logger: LogHandler = .default

    private init(
        storage: Storage,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy,
        migrationPolicy: MigrationPolicy)
    {
        coreDataStack = CoreDataStack(
            storage: storage,
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
    }

    public static func load(
        storage: Storage,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy = .error,
        migrationPolicy: MigrationPolicy = .lightWeight
    ) throws -> DataContainer {
        let container = DataContainer(
            storage: storage,
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
        try container.coreDataStack.loadPersistentStore()
        container.setup()
        return container
    }

    public static func loadAsync(
        storage: Storage,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy = .error,
        migrationPolicy: MigrationPolicy = .lightWeight,
        completion: @escaping (Error?) -> Void
    ) -> DataContainer {
        let container = DataContainer(
            storage: storage,
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
        container.coreDataStack.loadPersistentStoreAsync { error in
            defer { completion(error) }
            guard error == nil else { return }
            container.setup()
        }
        return container
    }

    private func setup() {
        initializeAllContext()
        persistentHistoryTracker.enable()
    }
    
    private func initializeAllContext() {
        writerContext = coreDataStack.createWriterContext()
        uiContext = coreDataStack.createUiContext(parent: writerContext)
    }
    
    public func rebuildStorage() throws {
        guard try destroyStorage() else { return }
        try buildStorage()
    }
    
    @discardableResult
    public func destroyStorage() throws -> Bool {
        guard let storage = coreDataStack.storage as? ConcreteStorage,
              coreDataStack.isLoaded()
        else { return false }
        try coreDataStack.coordinator
            .destroyPersistentStore(
                at: storage.storageUrl,
                ofType: storage.storeType, options: nil)
        try storage.destroy()
        return true
    }
    
    public func buildStorage() throws {
        guard coreDataStack.isLoaded() == false else { return }
        try coreDataStack.loadPersistentStore()
    }
    
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    public func loadTransactionHistory(date: Date?) -> [NSPersistentHistoryTransaction] {
        persistentHistoryTracker.loadPersistentHistory(date: date ?? createdDate)
    }
}

extension DataContainer {
    internal func backgroundSessionContext(name: String? = nil) -> _SessionContext {
        let context = coreDataStack.createBackgroundContext(parent: writerContext)
        context.name = name ?? "background"
        return _SessionContext(
            executionContext: context,
            rootContext: writerContext,
            uiContext: uiContext,
            logger: logger)
    }
    
    internal func uiSessionContext(name: String? = nil) -> _SessionContext {
        let context = coreDataStack.createMainThreadContext(parent: writerContext)
        context.name = name ?? "ui"
        return _SessionContext(
            executionContext: context,
            rootContext: writerContext,
            uiContext: context,
            logger: logger)
    }
    
    internal func querySessionContext(name: String? = nil) -> _SessionContext {
        return _SessionContext(
            executionContext: uiContext,
            rootContext: writerContext,
            uiContext: uiContext,
            logger: logger)
    }
}

extension DataContainer: MutableQueryerProtocol, ReadOnlyQueryerProtocol {
    private func canUseBatchRequest() -> Bool {
        coreDataStack.storage.storeType == NSSQLiteStoreType
    }

    public func fetch<T: Entity>(for type: T.Type) -> ReadOnlyFetchBuilder<T> {
        .init(config: .init(), context: querySessionContext())
    }
    
    public func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T> {
        .init(config: .init(batch: canUseBatchRequest()),
              context: backgroundSessionContext())
    }
    
    public func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T> {
        .init(config: .init(batch: canUseBatchRequest()),
              context: backgroundSessionContext())
    }
    
    public func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T> {
        .init(config: .init(batch: canUseBatchRequest()),
              context: backgroundSessionContext())
    }
}

extension DataContainer {
    public func startSession(name: String? = nil) -> Session {
        Session(
            context: backgroundSessionContext(name: name),
            mergePolicy: coreDataStack.mergePolicy)
    }
    
    public func startInteractiveSession(name: String? = nil) -> Session {
        Session(
            context: uiSessionContext(name: name),
            mergePolicy: coreDataStack.mergePolicy)
    }
    
    public func load<T: Entity>(objectID: NSManagedObjectID) -> T.ReadOnly? {
        guard let object = uiContext.object(with: objectID) as? ManagedObject<T> else { return nil }
        return T.ReadOnly(object)
    }
    
    public func load<T: Entity>(objectIDs: [NSManagedObjectID]) -> [T.ReadOnly?] {
        objectIDs.map(load(objectID:))
    }
    
    public func load<T: Entity>(_ object: T.ReadOnly) -> T.ReadOnly {
        guard uiContext != object.managedObject.managedObjectContext else { return object }
        let newObject = uiContext.receive(runtimeObject: object.managedObject)
        return T.ReadOnly(newObject)
    }

    public func faultAllObjects() {
        uiContext.refreshAllObjects()
        writerContext.refreshAllObjects()
    }
}
