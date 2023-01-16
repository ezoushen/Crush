//
//  DataContainer.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public class DataContainer {
    public static let uiContextDidRefresh = Notification.Name("DataContainerDidRefreshUiContext")

    internal var writerContext: NSManagedObjectContext!
    internal var uiContext: NSManagedObjectContext!
    internal let createdDate: Date = Date()

    internal lazy var notifier: UiContextNotifier = {
        if #available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *),
           coreDataStack.coordinator.checkRequirement([
            .sqliteStore, .remoteChangeNotificationEnabled, .persistentHistoryEnabled
           ])
        {
            return PersistentHistoryNotifier(container: self)
        } else {
            return ContextDidSaveNotifier(container: self)
        }
    }()

    public let coreDataStack: CoreDataStack
    public var logger: LogHandler = .default

#if os(iOS) || os(macOS)
    public private(set) var spotlightIndexer: CoreSpotlightIndexer?
#endif

    private init(
        dataModel: DataModel,
        mergePolicy: NSMergePolicy,
        migrationPolicy: MigrationPolicy)
    {
        coreDataStack = CoreDataStack(
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
    }

    public static func load(
        storages: Storage...,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy = .error,
        migrationPolicy: MigrationPolicy = .lightWeight
    ) throws -> DataContainer {
        let container = DataContainer(
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
        for storage in storages {
            try container.coreDataStack.loadPersistentStore(storage: storage)
        }
        container.setup()
        return container
    }

    public static func loadAsync(
        storages: Storage...,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy = .error,
        migrationPolicy: MigrationPolicy = .lightWeight,
        completion: @escaping (Error?) -> Void
    ) -> DataContainer {
        let container = DataContainer(
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
        for storage in storages {
            container.coreDataStack.loadPersistentStoreAsync(storage: storage) { error in
                defer { completion(error) }
                guard error == nil else { return }
                container.setup()
            }
        }
        return container
    }
#if canImport(_Concurrency) && compiler(>=5.5.2)
    @available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
    public static func loadAsync(
        storages: Storage...,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy = .error,
        migrationPolicy: MigrationPolicy = .lightWeight) async throws -> DataContainer
    {
        let container = DataContainer(
            dataModel: dataModel,
            mergePolicy: mergePolicy,
            migrationPolicy: migrationPolicy)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for storage in storages {
                group.addTask {
                    try await container.coreDataStack
                        .loadPersistentStoreAsync(storage: storage)
                }
            }
            try await group.waitForAll()
        }
        container.setup()
        return container
    }
#endif
    private func setup() {
        initializeAllContext()
        notifier.initialize()
        notifier.enable()
    }
    
    private func initializeAllContext() {
        writerContext = coreDataStack.createWriterContext()
        uiContext = coreDataStack.createUiContext(parent: writerContext)
    }

    @discardableResult
    private func _destroy(storage: Storage) throws -> Bool {
        if let storage = storage as? ConcreteStorage {
            try coreDataStack.coordinator.destroyPersistentStore(
                at: storage.storageUrl, ofType: storage.storeType)
            try storage.destroy()
        } else if let store = coreDataStack.coordinator.persistentStore(of: storage) {
            try coreDataStack.coordinator.remove(store)
        } else {
            return false
        }
        return true
    }
    
    public func rebuildStorages() throws {
        for storage in coreDataStack.storages {
            guard try _destroy(storage: storage) else { continue }
            try build(storage: storage)
        }
    }

    public func destroyStorages() throws {
        for storage in coreDataStack.storages {
            try _destroy(storage: storage)
        }
    }
    
    @discardableResult
    public func destroy(storage: Storage) throws -> Bool {
        guard coreDataStack.isLoaded(storage: storage) else { return false }
        return try _destroy(storage: storage)
    }
    
    public func build(storage: Storage) throws {
        guard coreDataStack.isLoaded(storage: storage) == false else { return }
        try coreDataStack.loadPersistentStore(storage: storage)
    }
    
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    public func loadTransactionHistory(date: Date?) -> [NSPersistentHistoryTransaction] {
        guard let persistentHistoryTracker = notifier as? PersistentHistoryNotifier else {
            logger.log(.warning, "loadTransactionHistory is not available")
            return []
        }
        return persistentHistoryTracker.loadPersistentHistory(date: date ?? createdDate)
    }

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    public func clearTransactionHistory() {
        guard let persistentHistoryTracker = notifier as? PersistentHistoryNotifier else {
            return logger.log(.warning, "loadTransactionHistory is not available")
        }
        return persistentHistoryTracker.deleteHistory(before: Date())
    }
}

// MARK: Metadata

extension DataContainer {
    public func setMetadata(key: String, value: Any, storage: Storage) {
        let metadata: [String: Any] = {
            guard var metadata = self.metadata(of: storage) else { return [key: value] }
            metadata[key] = value
            return metadata
        }()
        updateMetadata(metadata, storage: storage)
    }

    public func setMetadata(_ metadata: [String: Any], storage: Storage) {
        let newMetaData: [String: Any] = {
            guard var newMetaData = self.metadata(of: storage) else { return metadata }
            newMetaData.merge(metadata, uniquingKeysWith: { $1 })
            return newMetaData
        }()
        updateMetadata(newMetaData, storage: storage)
    }

    public func removeMetadata(key: String, storage: Storage) {
        guard var metadata = metadata(of: storage) else { return }
        metadata[key] = nil
        updateMetadata(metadata, storage: storage)
    }

    public func removeMetadata(keys: [String], storage: Storage) {
        guard var metadata = metadata(of: storage) else { return }
        for key in keys {
            metadata[key] = nil
        }
        updateMetadata(metadata, storage: storage)
    }

    private func updateMetadata(_ metadata: [String: Any], storage: Storage) {
        guard let store = coreDataStack.coordinator.persistentStore(of: storage) else {
            return
        }
        coreDataStack.coordinator.setMetadata(metadata, for: store)
    }

    public func metadata(of storage: Storage) -> [String: Any]? {
        guard let store = coreDataStack.coordinator.persistentStore(of: storage) else {
            return nil
        }
        return coreDataStack.coordinator.metadata(for: store)
    }
    
    public func saveMetadata() throws {
        let context = coreDataStack.createBackgroundDetachedContext()
        try context.performSync { try context.save() }
    }
}

extension DataContainer {
    internal func detachedSessionContext(name: String? = nil) -> _DetachedSessionContext {
        let context = coreDataStack.createBackgroundDetachedContext()
        if context.persistentStoreCoordinator?.checkRequirement([
            .sqliteStore, .concreteFile
        ]) ?? false {
            try! context.setQueryGenerationFrom(.current)
        }
        context.name = name ?? "backgroundDetached"
        return _DetachedSessionContext(
            executionContext: context,
            rootContext: writerContext,
            uiContext: uiContext,
            logger: logger,
            handler: notifier.sessionContextExecutionResultHandler)
    }
    
    internal func backgroundSessionContext(name: String? = nil) -> _SessionContext {
        let context = coreDataStack.createBackgroundContext(parent: writerContext)
        context.name = name ?? "background"
        return _SessionContext(
            executionContext: context,
            rootContext: writerContext,
            uiContext: uiContext,
            logger: logger,
            handler: notifier.sessionContextExecutionResultHandler)
    }
    
    internal func uiSessionContext(name: String? = nil) -> _SessionContext {
        let context = coreDataStack.createMainThreadContext(parent: writerContext)
        context.name = name ?? "ui"
        return _SessionContext(
            executionContext: context,
            rootContext: writerContext,
            uiContext: context,
            logger: logger,
            handler: notifier.sessionContextExecutionResultHandler)
    }
    
    internal func querySessionContext(name: String? = nil) -> _SessionContext {
        return _SessionContext(
            executionContext: uiContext,
            rootContext: writerContext,
            uiContext: uiContext,
            logger: logger,
            handler: notifier.sessionContextExecutionResultHandler)
    }
}

extension DataContainer: MutableQueryerProtocol, ReadOnlyQueryerProtocol {
    private func canUseBatchRequest<T: Entity>(type: T.Type) -> Bool {
        let managedObjectModel = coreDataStack.dataModel.managedObjectModel

        for store in coreDataStack.coordinator.persistentStores
        where
            managedObjectModel
                .entities(forConfigurationName: store.configurationName)?
                .contains(where: { $0.name == T.fetchKey}) == true &&
            store.type == NSSQLiteStoreType
        {
            return true
        }
        return false
    }

    public func fetch<T: Entity>(for type: T.Type) -> ReadOnlyFetchBuilder<T> {
        .init(config: .init(), context: querySessionContext())
    }
    
    public func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T> {
        .init(config: .init(batch: canUseBatchRequest(type: type)),
              context: backgroundSessionContext())
    }
    
    public func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T> {
        .init(config: .init(batch: canUseBatchRequest(type: type)),
              context: backgroundSessionContext())
    }
    
    public func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T> {
        .init(config: .init(batch: canUseBatchRequest(type: type)),
              context: backgroundSessionContext())
    }
}

extension DataContainer {
    public func startDetachedSession(name: String? = nil) -> Session {
        Session(
            context: detachedSessionContext(name: name),
            mergePolicy: coreDataStack.mergePolicy)
    }
    
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
    
    public func load<T: Entity>(objectID: NSManagedObjectID, isFault: Bool = true) -> T.ReadOnly? {
        guard let object = uiContext
            .load(objectID: objectID, isFault: isFault) as? ManagedObject<T>
        else { return nil }
        return T.ReadOnly(object)
    }
    
    public func load<T: Entity>(objectIDs: [NSManagedObjectID], isFault: Bool = true) -> [T.ReadOnly?] {
        objectIDs.lazy.map { load(objectID: $0, isFault: isFault)}
    }

    public func load<T: Entity>(forURIRepresentation uri: String, isFault: Bool = true) -> T.ReadOnly? {
        guard let managedObjectID = coreDataStack.coordinator
                .managedObjectID(forURIRepresentation: URL(string: uri)!) else { return nil }
        return load(objectID: managedObjectID, isFault: isFault)
    }
    
    public func load<T: Entity>(_ object: T.ReadOnly) -> T.ReadOnly {
        guard uiContext != object.managedObject.managedObjectContext else { return object }
        let newObject = uiContext.receive(runtimeObject: object.managedObject)
        return T.ReadOnly(object: newObject)
    }

    public func faultAllObjects() {
        uiContext.refreshAllObjects()
        writerContext.refreshAllObjects()
    }
}

#if os(iOS) || os(macOS)
import CoreSpotlight

@available(iOS 13.0, macOS 10.15, *)
extension DataContainer {
    @discardableResult
    public func initializeCoreSpotlightIndexer(
        for storage: Storage,
        provider: @escaping (NSManagedObject) -> CSSearchableItemAttributeSet?) -> Bool
    {
        guard let description = coreDataStack.persistentStoreDescriptions[storage] else {
            return false
        }
        spotlightIndexer = CoreSpotlightIndexer(
            provider: CoreSpotlightAttributeSetProviderProxy(provider),
            storeDescription: description,
            coordinator: coreDataStack.coordinator)
        return true
    }
}
#endif
