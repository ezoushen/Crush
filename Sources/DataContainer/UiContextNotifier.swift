//
//  UiContextNotifier.swift
//  
//
//  Created by ezou on 2021/10/17.
//

import CoreData
import Foundation

// MARK: UiContextNotifier

class UiContextNotifier {
    private let _persistentHistory: NotificationHandler?
    
    let contextDidSave: ContextDidSaveNotificationHandler

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    var persistentHistory: PersistentHistoryNotificationHandler? {
        _persistentHistory as? PersistentHistoryNotificationHandler
    }

    private let notificationBuilder: ([AnyHashable: Any]) -> Notification?

    init(container: DataContainer) {
        let seenTokens = NotificationHandler.SeenTokens(size: 100)

        contextDidSave =
            ContextDidSaveNotificationHandler(container: container, seenTokens: seenTokens)

        if #available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *) {
            _persistentHistory =
                PersistentHistoryNotificationHandler(container: container, seenTokens: seenTokens)
        } else {
            _persistentHistory = nil
        }

        notificationBuilder = { [weak container] userInfo in
            guard let container = container else { return nil }
            return Notification(
                name: DataContainer.uiContextDidRefresh,
                object: container, userInfo: userInfo)
        }

        contextDidSave.notifier = self
        _persistentHistory?.notifier = self
    }

    deinit {
        disable()
    }

    func enable() {
        contextDidSave.enable()
        _persistentHistory?.enable()
    }

    func disable() {
        contextDidSave.disable()
        _persistentHistory?.disable()
    }

    fileprivate func postNotification(userInfo: [AnyHashable: Any]) {
        guard let notification = notificationBuilder(userInfo) else { return }
        DispatchQueue.performMainThreadTask {
            NotificationCenter.default.post(notification)
        }
    }
}

class NotificationHandler {

    let seenTokens: SeenTokens

    private let _uiContext: () -> NSManagedObjectContext?
    lazy var uiContext: NSManagedObjectContext? = _uiContext()

    weak var notifier: UiContextNotifier?

    private(set) var isEnabled: Bool = false

    private var _logger: () -> LogHandler
    var logger: LogHandler { _logger() }

    init(container: DataContainer, seenTokens: SeenTokens) {
        _logger = { [weak container] in container?.logger ?? .default }
        // Load contexts lazily to prevent potential dead lock on initialization
        _uiContext = { [weak container] in container?.uiContext }
        self.seenTokens = seenTokens
    }

    func enable() { isEnabled = true }
    func disable() { isEnabled = false }
}

extension NotificationHandler {
    class SeenTokens {
        let tokens: MutableOrderedSet<NSPersistentHistoryToken> = []
        let size: Int

        private let lock = UnfairLock()

        init(size: Int) {
            self.size = size
        }

        private func insert(_ token: NSPersistentHistoryToken) {
            if tokens.count >= size {
                tokens.removeFirst()
            }
            tokens.append(token)
        }

        private func remove(_ token: NSPersistentHistoryToken) -> Bool {
            tokens.remove(token) != nil
        }

        func shouldProcessToken(_ token: NSPersistentHistoryToken) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            /// Return false if it's already presented in the set
            guard remove(token) else {
                /// Return true if it's not been processed, and then mark the token as seen
                insert(token)
                return true
            }
            return false
        }
    }
}

class ContextDidSaveNotificationHandler: NotificationHandler {
    override func enable() {
        guard !isEnabled else { return }
        super.enable()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave(notification:)),
            name: .NSManagedObjectContextDidSave,
            object: nil)
    }

    override func disable() {
        guard isEnabled else { return }
        super.disable()
        NotificationCenter.default.removeObserver(
            self,
            name: .NSManagedObjectContextDidSave,
            object: nil)
    }

    @objc func contextDidSave(notification: Notification) {
        /// Check the new change token and merge changes of the notification if it hadn't been processed
        if #available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *),
           let token = notification.userInfo?["newChangeToken"] as? NSPersistentHistoryToken,
           seenTokens.shouldProcessToken(token) == false
        {
            return
        }
        /// Merge the changes if it's not empty
        guard let uiContext = uiContext,
              let notifier = notifier,
              let userInfo = notification.userInfo,
              let managedObjectContext = notification.object as? NSManagedObjectContext,
              userInfo.contains(where: {
                  ($0.key == AnyHashable(NSInsertedObjectsKey) ||
                   $0.key == AnyHashable(NSUpdatedObjectsKey) ||
                   $0.key == AnyHashable(NSDeletedObjectsKey)) &&
                  ($0.value as? NSSet)?.count ?? 0 > 0
              }) else { return }

        /// Merge changes into ui context and refresh deleted objects
        let deletedObjectIDs = (userInfo[NSDeletedObjectsKey] as? NSSet)?
            .compactMap { ($0 as? NSManagedObject)?.objectID }

        DispatchQueue.performMainThreadTask {
            uiContext.mergeChanges(fromContextDidSave: notification)
            /// Refresh for forcing KVO on deleted objects
            if let deletedObjectIDs {
                for object in deletedObjectIDs.compactMap(uiContext.registeredObject(for:)) {
                    uiContext.refresh(object, mergeChanges: true)
                }
            }
        }
        /// Send notification on main thread
        let merger = UserInfoMerger(userInfo: userInfo)
        let name = managedObjectContext.name ?? "Unknown"
        notifier.postNotification(userInfo: [
            AnyHashable(name): merger.createUserInfo()
        ])
    }
}

@available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
class PersistentHistoryNotificationHandler: NotificationHandler {
    let coordinator: NSPersistentStoreCoordinator
    var lastHistoryTokens: [URL: NSPersistentHistoryToken] = [:]
    var transactionLifetime: TimeInterval = 604_800

    var canTrackPersistentHistory: Bool {
        coordinator.checkRequirement([
           .sqliteStore, .persistentHistoryEnabled, .remoteChangeNotificationEnabled
        ])
    }

    private let lock = UnfairLock()

    override init(container: DataContainer, seenTokens: NotificationHandler.SeenTokens) {
        coordinator = container.coreDataStack.coordinator
        super.init(container: container, seenTokens: seenTokens)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reload),
            name: .NSPersistentStoreCoordinatorStoresDidChange,
            object: coordinator)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func reload() {
         guard canTrackPersistentHistory else { return disable() }
        /// Purge out-dated history
        let sevenDaysAgo = Date(timeIntervalSinceNow: -transactionLifetime)
        deleteHistory(before: sevenDaysAgo)

        /// Load persistent token from disk
        for store in coordinator.persistentStores {
            guard let storeURL = store.url, storeURL.isDevNull == false else { continue }
            do {
                let tokenFileURL = tokenURL(for: storeURL)
                let tokenData = try Data(contentsOf: tokenFileURL)
                let token = try NSKeyedUnarchiver
                    .unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
                lock.lock()
                lastHistoryTokens[storeURL] = token
                lock.unlock()
            } catch let error {
                switch (error as NSError).code {
                case 260: break // File not found
                case 4864: break // Data corrupted
                default: logger.log(.error, "Failed to load history token", error: error)
                }
            }
        }
    }

    override func enable() {
        guard !isEnabled else { return }
        super.enable()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(persistentStoreHistoryChanged(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: coordinator)
    }

    override func disable() {
        guard isEnabled else { return }
        super.disable()
        NotificationCenter.default.removeObserver(
            self,
            name: .NSPersistentStoreRemoteChange,
            object: coordinator)
    }

    func storeHistoryToken(_ token: NSPersistentHistoryToken, for storeURL: URL) {
        if storeURL.isDevNull { return }
        do {
            lastHistoryTokens[storeURL] = token
            let tokenFileURL = tokenURL(for: storeURL)
            let data = try NSKeyedArchiver
                .archivedData(withRootObject: token, requiringSecureCoding: true)
            try data.write(to: tokenFileURL)
        } catch {
            logger.log(.error, "Failed to store history token", error: error)
        }
    }

    private func tokenURL(for storeURL: URL) -> URL {
        storeURL.appendingPathExtension("tokendata")
    }

    @objc func persistentStoreHistoryChanged(_ notification: Notification) {
        guard let uiContext = uiContext,
              let storeURL = notification.userInfo?["storeURL"] as? URL,
              let notifier = notifier else { return }

        let token: NSPersistentHistoryToken? =
            notification.userInfo?["historyToken"] as? NSPersistentHistoryToken

        if let lastToken = token, !seenTokens.shouldProcessToken(lastToken) {
            return
        }

        lock.lock()

        let transactions = loadPersistentHistory(storeURL: storeURL)
            .sorted(by: { $0.timestamp < $1.timestamp })
        var mergers: [AnyHashable: UserInfoMerger] = [:]
        
        if let lastToken = token ?? transactions.last?.token {
            storeHistoryToken(lastToken, for: storeURL)
        }

        for transaction in transactions {
            let notification = transaction.objectIDNotification()
            
            guard let changes = notification.userInfo else { continue }

            let key = AnyHashable(transaction.author ?? "Unknown")
            let merger: UserInfoMerger = mergers[key] ?? {
                let merger = UserInfoMerger()
                mergers[key] = merger
                return merger
            }()
            
            merger.merge(userInfo: changes)
            
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: changes, into: [uiContext])
        }

        lock.unlock()

        if transactions.isEmpty == false {
            let userInfo = mergers.mapValues { $0.createUserInfo() }
            notifier.postNotification(userInfo: userInfo)
        }
    }

    func loadPersistentHistory(date: Date) -> [NSPersistentHistoryTransaction] {
        let fetchHistoryRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
        return executePersistentHistoryRequest(fetchHistoryRequest)
    }

    func deleteHistory(before date: Date) {
        let purgeHistoryRequest = NSPersistentHistoryChangeRequest
            .deleteHistory(before: date)
        _ = executePersistentHistoryRequest(purgeHistoryRequest)
    }

    private func loadPersistentHistory(storeURL: URL) -> [NSPersistentHistoryTransaction] {
        let fetchHistoryRequest = NSPersistentHistoryChangeRequest
            .fetchHistory(after: lastHistoryTokens[storeURL])
        return executePersistentHistoryRequest(fetchHistoryRequest)
    }

    private func executePersistentHistoryRequest(_ request: NSPersistentHistoryChangeRequest) -> [NSPersistentHistoryTransaction] {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        do {
            let historyResult = try context
                .execute(request) as? NSPersistentHistoryResult
            guard let history = historyResult?.result as? [NSPersistentHistoryTransaction]
            else { return [] }
            return history
        } catch {
            logger.log(.error, "Failed to load persistent history", error: error)
            return []
        }
    }
}

// MARK: User Info

struct NSManagedObjectIDIterator: IteratorProtocol {
    private var iterators: AnyIterator<AnyIterator<Any>>
    private var iterator: AnyIterator<Any>?

    init<I: IteratorProtocol>(_ iterators: I) where I.Element == AnyIterator<Any> {
        self.iterators = AnyIterator(iterators)
    }

    mutating func next() -> NSManagedObjectID? {
        if iterator == nil {
            iterator = iterators.next()
        }
        return iterator?.next() as? NSManagedObjectID
    }
}

class UserInfoMerger {
    var insertedObjectIDIterators: [AnyIterator<Any>] = []
    var updatedObjectIDIterators: [AnyIterator<Any>] = []
    var deletedObjectIDIterators: [AnyIterator<Any>] = []

    init(userInfo: [AnyHashable: Any]) {
        merge(userInfo: userInfo)
    }

    init(userInfos: [[AnyHashable: Any]]) {
        userInfos.forEach(merge(userInfo:))
    }

    init() { }

    func merge(userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo else { return }

        if let insertedObjectIDs = userInfo[AnyHashable(NSInsertedObjectIDsKey)] as? NSSet {
            insertedObjectIDIterators.append(AnyIterator(insertedObjectIDs.makeIterator()))
        }
        if let insertedObjects = userInfo[AnyHashable(NSInsertedObjectsKey)] as? NSSet {
            insertedObjectIDIterators.append(AnyIterator(
                insertedObjects.lazy.compactMap{ ($0 as? NSManagedObject)?.objectID }.makeIterator()))
        }
        if let updatedObjectIDs = userInfo[AnyHashable(NSUpdatedObjectIDsKey)] as? NSSet {
            updatedObjectIDIterators.append(AnyIterator(updatedObjectIDs.makeIterator()))
        }
        if let updatedObjects = userInfo[AnyHashable(NSUpdatedObjectsKey)] as? NSSet {
            updatedObjectIDIterators.append(AnyIterator(
                updatedObjects.lazy.compactMap{ ($0 as? NSManagedObject)?.objectID }.makeIterator()))
        }
        if let deletedObjectIDs = userInfo[AnyHashable(NSDeletedObjectIDsKey)] as? NSSet {
            deletedObjectIDIterators.append(AnyIterator(deletedObjectIDs.makeIterator()))
        }
        if let deletdeObjects = userInfo[AnyHashable(NSDeletedObjectsKey)] as? NSSet {
            deletedObjectIDIterators.append(AnyIterator(
                deletdeObjects.lazy.compactMap{ ($0 as? NSManagedObject)?.objectID }.makeIterator()))
        }
    }

    func createUserInfo() -> [AnyHashable: Any] {
        let inserted = insertedObjectIDIterators
        let updated = updatedObjectIDIterators
        let deleted = deletedObjectIDIterators
        return [
            AnyHashable(NSInsertedObjectIDsKey): AnySequence<NSManagedObjectID> {
                NSManagedObjectIDIterator(inserted.makeIterator())
            },
            AnyHashable(NSUpdatedObjectIDsKey): AnySequence<NSManagedObjectID> {
                NSManagedObjectIDIterator(updated.makeIterator())
            },
            AnyHashable(NSDeletedObjectIDsKey): AnySequence<NSManagedObjectID> {
                NSManagedObjectIDIterator(deleted.makeIterator())
            },
        ]
    }
}

extension Entity {
    /// Check if user info received from ``DataContainer/uiContextDidRefresh`` has related changes against specified `Entity`s
    public static func hasChanges(
        userInfo: [AnyHashable: Any], entities: [Entity.Type]) -> Bool
    {
        guard let inserted = userInfo[NSInsertedObjectIDsKey] as? AnySequence<NSManagedObjectID>,
              let updated = userInfo[NSUpdatedObjectIDsKey] as? AnySequence<NSManagedObjectID>,
              let deleted = userInfo[NSDeletedObjectIDsKey] as? AnySequence<NSManagedObjectID>
        else { return false }

        let entityNames = Set(entities.map { $0.name })
        
        return inserted.contains { entityNames.contains($0.entity.name ?? "") } ||
            updated.contains { entityNames.contains($0.entity.name ?? "") } ||
            deleted.contains { entityNames.contains($0.entity.name ?? "") }
    }
}
