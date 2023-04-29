//
//  DataContainer.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

/// A well-defined CoreData wrapper.
///
/// `DataContainer` has sync/async static methods for instantiation.
/// You can specified your storage by calling ``DataContainer/load(storages:dataModel:mergePolicy:migrationPolicy:)`` or calling ``load(storage:)``
/// ```swift
/// // Sync version
/// try DataContainer.load(
///     storages: .sqlite(name: "filename"),
///     dataModel: .myDataModel,
///     mergePolicy: .error,
///     migrationPolicy: .lightweight)
///
/// // Async version (completion callback)
/// DataContainer.loadAsync(...) { error in ... }
///
/// // Async version (Swift Concurrency)
/// try await DataContainer.loadAsync(...)
/// ```
///
/// In general, you'll need to create a ``Session`` as your working context. There are three kinds of session for you to use.
///
/// ```swift
/// // For background task which changes would only be apply to ui context once writter context saved successfully.
/// let session = dataContainer.startSession()
///
/// // For background task which changes would be committed into persistent store directly.
/// let session = dataContainer.startDetachedSession()
///
/// // For user interactive task, the changes would be apply on ui context directly.
/// let session = dataContainer.startInteractiveSession()
/// ```
///
/// Also, the `DataContainer` provides some `RequestBuilder` for fetching data and committing changes to persistent store directly.
/// 
/// ```swift
///  // For fetching data
///  dataContainer.fetch(for: MyEntity.self)...
///
///  // Batch insertion
///  try dataContainer.insert(for: MyEntity.self)...
///
///  // Batch delete
///  try dataContainer.delete(for: MyEntity.self)...
///
///  // Batch update
///  try dataContainer.update(for: MyEntity.self)...
/// ```
/// 
/// Metadata manipulation is also supported in well-defined format
/// ```swift
/// // Getter
/// let metadata = dataContainer.metadata(for: storage)
/// // Setter
/// dataContainer.setMetadata(key: "my_key", value: someValue, storage: storage)
/// ```
///
///
public class DataContainer {
    /// Notification that would be send once the UI context updated
    ///
    /// This notification will be sent right after local changes committed into the persistent store,
    /// and after remote changes being merged into writer context and ui context.
    public static let uiContextDidRefresh = Notification.Name("DataContainerDidRefreshUiContext")

    internal lazy var writerContext: NSManagedObjectContext = coreDataStack.createWriterContext()
    internal lazy var uiContext: NSManagedObjectContext = coreDataStack.createUiContext(parent: writerContext)
    
    internal let createdDate: Date = Date()

    internal let metadataLock = UnfairLock()

    lazy var notifier: UiContextNotifier = UiContextNotifier(container: self)

    /// Backbone of `DataContainer`
    public let coreDataStack: CoreDataStack
    public var logger: LogHandler = .default {
        didSet { LogHandler.current = logger }
    }

#if os(iOS) || os(macOS)
    /// CoreSpotlight indexers indexed by corresponding storage
    public private(set) var spotlightIndexersIndexedByStorage: [Storage: CoreSpotlightIndexer] = [:]
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
        notifier.enable()
    }

    deinit {
        notifier.disable()
    }

    /// Initialize a `DataContainer` and load specified storages synchronously
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
        return container
    }

    /// Clean all loaded storages. This will delete all data persisted within each storage.
    public func rebuildStorages() throws {
        for storage in coreDataStack.storages {
            try coreDataStack.removePersistentStore(storage: storage)
            try load(storage: storage)
        }
    }

    /// Destroy all loaded storages.
    public func destroyStorages() throws {
        for storage in coreDataStack.storages {
            try coreDataStack.removePersistentStore(storage: storage)
        }
    }

    /// Destroy the give storage if it has been loaded.
    @discardableResult
    public func destroy(storage: Storage) throws -> Bool {
        guard coreDataStack.isLoaded(storage: storage) else { return false }
        try coreDataStack.removePersistentStore(storage: storage)
        return true
    }

    /// Load the give storage if it hasn't been loaded.
    public func load(storage: Storage) throws {
        guard coreDataStack.isLoaded(storage: storage) == false else { return }
        try coreDataStack.loadPersistentStore(storage: storage)
    }

    /// Load persistent histroy records since the given date.
    ///
    /// > Important: This will only work while both ``SQLiteStorageOption/persistentHistoryTracking(_:)`` and
    /// ``SQLiteStorageOption/persistentHistoryTracking(_:)`` are specified `true` in any loaded storage options.
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    public func loadTransactionHistory(since date: Date?) -> [NSPersistentHistoryTransaction] {
        notifier.persistentHistory?.loadPersistentHistory(date: date ?? createdDate) ?? []
    }

    /// Clean all persistent history tracking records.
    ///
    /// > Important: This will only work while both ``SQLiteStorageOption/persistentHistoryTracking(_:)`` and
    /// ``SQLiteStorageOption/persistentHistoryTracking(_:)`` are specified `true` in any loaded storage options.
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    public func clearTransactionHistory() {
        notifier.persistentHistory?.deleteHistory(before: Date())
    }
}

// MARK: Metadata

extension DataContainer {
    /// Update metadata associated with the storage.
    ///
    /// Value accepts only property list compatible types. Remeber to call ``saveMetadata()`` if `autoSave` is false.
    public func setMetadata(key: String, value: Any, storage: Storage, autoSave: Bool = true) {
        criticalSectionForModifyingMetadata(autoSave: autoSave) {
            let metadata: [String: Any] = {
                guard var metadata = self.metadata(of: storage) else { return [key: value] }
                metadata[key] = value
                return metadata
            }()
            updateMetadata(metadata, storage: storage)
        }
    }

    /// Batch update metadata associated with the storge
    ///
    /// Value accepts only property list compatible types. Remeber to call ``saveMetadata()`` if `autoSave` is false.
    public func setMetadata(_ metadata: [String: Any], storage: Storage, autoSave: Bool = true) {
        criticalSectionForModifyingMetadata(autoSave: autoSave) {
            let newMetaData: [String: Any] = {
                guard var newMetaData = self.metadata(of: storage) else { return metadata }
                newMetaData.merge(metadata, uniquingKeysWith: { $1 })
                return newMetaData
            }()
            updateMetadata(newMetaData, storage: storage)
        }
    }

    /// Remove value of the key in metadata associated with the storage.
    ///
    /// Remeber to call ``saveMetadata()`` if `autoSave` is false.
    public func removeMetadata(key: String, storage: Storage, autoSave: Bool = true) {
        criticalSectionForModifyingMetadata(autoSave: autoSave) {
            guard var metadata = metadata(of: storage) else { return }
            metadata[key] = nil
            updateMetadata(metadata, storage: storage)
        }
    }

    /// Batch removing values of the keys in metadata associated with the storage.
    ///
    /// Remeber to call ``saveMetadata()`` if `autoSave` is false.
    public func removeMetadata(keys: [String], storage: Storage, autoSave: Bool = true) {
        criticalSectionForModifyingMetadata(autoSave: autoSave) {
            guard var metadata = metadata(of: storage) else { return }
            for key in keys {
                metadata[key] = nil
            }
            updateMetadata(metadata, storage: storage)
        }
    }

    /// Load metadata from the storage
    public func metadata(of storage: Storage) -> [String: Any]? {
        guard let store = coreDataStack.coordinator.persistentStore(of: storage) else {
            return nil
        }
        return coreDataStack.coordinator.metadata(for: store)
    }

    /// Commit to-be-stored data to its persistent store
    public func saveMetadata() throws {
        let context = coreDataStack.createBackgroundDetachedContext()
        try context.performSync { try context.save() }
    }

    private func updateMetadata(_ metadata: [String: Any], storage: Storage) {
        guard let store = coreDataStack.coordinator.persistentStore(of: storage) else {
            return
        }
        coreDataStack.coordinator.setMetadata(metadata, for: store)
    }

    private func criticalSectionForModifyingMetadata(autoSave: Bool, _ block: () -> Void) {
        metadataLock.lock()
        let context: NSManagedObjectContext? = autoSave
            ? nil : coreDataStack.createBackgroundDetachedContext()
        defer {
            context?.performAndWait { try! context!.save() }
            metadataLock.unlock()
        }
        block()
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
            uiContext: uiContext)
    }
    
    internal func backgroundSessionContext(name: String? = nil) -> SessionContext {
        let context = coreDataStack.createBackgroundContext(parent: writerContext)
        context.name = name ?? "background"
        return SessionContext(
            executionContext: context,
            rootContext: writerContext,
            uiContext: uiContext)
    }
    
    internal func uiSessionContext(name: String? = nil) -> SessionContext {
        let context = coreDataStack.createMainThreadContext(parent: writerContext)
        context.name = name ?? "ui"
        return SessionContext(
            executionContext: context,
            rootContext: writerContext,
            uiContext: context)
    }
    
    internal func querySessionContext(name: String? = nil) -> SessionContext {
        return SessionContext(
            executionContext: uiContext,
            rootContext: writerContext,
            uiContext: uiContext)
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
    /// Create a detached session that its execution context is connecting directly to the persistent store coordinator.
    ///
    /// - Parameters:
    ///     - name: Name that would be used as transaction author name in persistent history
    public func startDetachedSession(name: String? = nil) -> Session {
        Session(
            context: detachedSessionContext(name: name),
            mergePolicy: coreDataStack.mergePolicy)
    }

    /// Create a working session.
    ///
    /// - Parameters:
    ///     - name: Name that would be used as transaction author name in persistent history
    public func startSession(name: String? = nil) -> Session {
        Session(
            context: backgroundSessionContext(name: name),
            mergePolicy: coreDataStack.mergePolicy)
    }

    /// Create a session that has it execution context and ui context the same
    ///
    /// - Parameters:
    ///     - name: Name that would be used as transaction author name in persistent history
    public func startInteractiveSession(name: String? = nil) -> Session {
        Session(
            context: uiSessionContext(name: name),
            mergePolicy: coreDataStack.mergePolicy)
    }

    /// Load the object by the given object ID
    public func load<T: Entity>(objectID: NSManagedObjectID, isFault: Bool = true) -> T.ReadOnly? {
        guard let object = uiContext
            .load(objectID: objectID, isFault: isFault) as? ManagedObject<T>
        else { return nil }
        return T.ReadOnly(object)
    }

    /// Load the objects by the given object IDs
    public func load<T: Entity>(objectIDs: [NSManagedObjectID], isFault: Bool = true) -> [T.ReadOnly?] {
        objectIDs.lazy.map { load(objectID: $0, isFault: isFault)}
    }

    /// Load the object by the given `NSManagedObjectID` in uri representation
    public func load<T: Entity>(forURIRepresentation uri: URL, isFault: Bool = true) -> T.ReadOnly? {
        guard let managedObjectID = coreDataStack.coordinator
                .managedObjectID(forURIRepresentation: uri) else { return nil }
        return load(objectID: managedObjectID, isFault: isFault)
    }

    /// Load the give read only object, it refreshed the object and it's important especially when the object had been faulted.
    public func load<T: Entity>(_ object: T.ReadOnly) -> T.ReadOnly {
        guard uiContext != object.managedObject.managedObjectContext else { return object }
        let newObject = uiContext.receive(runtimeObject: object.managedObject)
        return T.ReadOnly(object: newObject)
    }

    /// Turn all registered objects in writer context and ui context into faults.
    ///
    /// It helps reduce the memory usage and also refresh objects in context.
    public func faultAllObjects() {
        uiContext.refreshAllObjects()
        writerContext.refreshAllObjects()
    }
}

// MARK: Async API (Callback)

extension DataContainer {
    /// Initialize a `DataContainer` and load specified storages asynchronously
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
        let group = DispatchGroup()
        var error: Error?
        for storage in storages {
            group.enter()
            container.coreDataStack.loadPersistentStoreAsync(storage: storage) {
                if let err = $0 {
                    error = err
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(error)
        }
        return container
    }

    /// Load the give storage asynchronoously if it hasn't been loaded.
    public func loadAsync(storage: Storage, completion: ((Error?) -> Void)? = nil) {
        guard coreDataStack.isLoaded(storage: storage) == false else { return }
        coreDataStack.loadPersistentStoreAsync(storage: storage) {
            completion?($0)
        }
    }

    /// Destroy the give storage asynchronously if it has been loaded.
    public func destroyAsync(storage: Storage, completion: ((Bool, Error?) -> Void)? = nil) {
        guard self.coreDataStack.isLoaded(storage: storage)
        else {
            completion?(false, nil)
            return
        }
        coreDataStack.removePersistentStoreAsync(storage: storage) {
            if let error = $0 {
                completion?(false, error)
            } else {
                completion?(true, nil)
            }
        }
    }
}

// MARK: Async API (Swift Concurrency)

#if canImport(_Concurrency) && compiler(>=5.5.2)
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension DataContainer {
    /// Initialize a `DataContainer` and load specified storages asynchronously
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
                    try await container.coreDataStack.loadPersistentStoreAsync(storage: storage)
                }
            }
            try await group.waitForAll()
        }
        return container
    }

    /// Load the give storage if it hasn't been loaded.
    public func loadAsync(storage: Storage) async throws {
        guard coreDataStack.isLoaded(storage: storage) == false else { return }
        try await coreDataStack.loadPersistentStoreAsync(storage: storage)
    }

    /// Destroy the give storage asynchronously if it has been loaded.
    @discardableResult public func destroyAsync(storage: Storage) async throws -> Bool {
        guard coreDataStack.isLoaded(storage: storage) else { return false }
        try await coreDataStack.removePersistentStoreAsync(storage: storage)
        return true
    }
}
#endif

#if os(iOS) || os(macOS)
import CoreSpotlight

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension DataContainer {
    @discardableResult
    public func initializeCoreSpotlightIndexer(
        for storage: Storage,
        provider: @escaping (NSManagedObject) -> CSSearchableItemAttributeSet?) -> Bool
    {
        guard let description = coreDataStack.persistentStoreDescriptions[storage] else {
            return false
        }
        spotlightIndexersIndexedByStorage[storage] = CoreSpotlightIndexer(
            provider: CoreSpotlightAttributeSetProviderProxy(provider),
            storeDescription: description,
            coordinator: coreDataStack.coordinator)
        return true
    }
}
#endif
