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

    internal lazy var persistentHistoryTracker =
        PersistentHistoryTracker(
            context: backgroundSessionContext(),
            coordinator: coreDataStack.coordinator)

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
        migrationPolicy: MigrationPolicy = .lightWeight
    ) throws -> DataContainer {
        let container = try DataContainer(
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
    ) throws -> DataContainer {
        let container = try DataContainer(
            storage: storage,
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
        try container.coreDataStack.loadPersistentStoreAsync { error in
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
        try destroyStorage()
        try buildStorage()
    }
    
    public func destroyStorage() throws {
        guard let storage = coreDataStack.storage as? ConcreteStorage else {
            return
        }
        
        try coreDataStack.coordinator
            .destroyPersistentStore(
                at: storage.storageUrl,
                ofType: storage.storeType, options: nil)
        try storage.destroy()
    }
    
    public func buildStorage() throws {
        try coreDataStack.loadPersistentStore()
    }
}

extension DataContainer {
    internal func backgroundSessionContext() -> _SessionContext {
        _SessionContext(
            executionContext: coreDataStack.createBackgroundContext(parent: writerContext),
            rootContext: writerContext,
            uiContext: uiContext,
            logger: logger)
    }
    
    internal func uiSessionContext() -> _SessionContext {
        let context = coreDataStack.createMainThreadContext(parent: writerContext)
        return _SessionContext(
            executionContext: context,
            rootContext: writerContext,
            uiContext: context,
            logger: logger)
    }
    
    internal func querySessionContext() -> _SessionContext {
        _SessionContext(
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

    public func fetch<T: Entity>(for type: T.Type) -> FetchBuilder<T, ManagedObject<T>, T.ReadOnly> {
        .init(config: .init(), context: querySessionContext(), onUiContext: true)
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
    public func startSession() -> Session {
        Session(context: backgroundSessionContext(), mergePolicy: coreDataStack.mergePolicy)
    }
    
    public func startUiSession() -> Session {
        Session(context: uiSessionContext(), mergePolicy: coreDataStack.mergePolicy)
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
