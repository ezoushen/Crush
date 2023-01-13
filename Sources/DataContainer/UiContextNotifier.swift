//
//  PersistentHistoryTracker.swift
//  
//
//  Created by ezou on 2021/10/17.
//

import CoreData
import Foundation

// MARK: User Info

internal struct NSManagedObjectIDIterator: IteratorProtocol {
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

internal class UserInfoMerger {
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
        
        if let insertedObjectIDs = userInfo[AnyHashable(NSInsertedObjectIDsKey)] as? NSMutableSet {
            insertedObjectIDIterators.append(AnyIterator(insertedObjectIDs.makeIterator()))
        }
        if let insertedObjects = userInfo[AnyHashable(NSInsertedObjectsKey)] as? NSMutableSet {
            insertedObjectIDIterators.append(AnyIterator(
                insertedObjects.lazy.compactMap{ ($0 as? NSManagedObject)?.objectID }.makeIterator()))
        }
        if let updatedObjectIDs = userInfo[AnyHashable(NSUpdatedObjectIDsKey)] as? NSMutableSet {
            updatedObjectIDIterators.append(AnyIterator(updatedObjectIDs.makeIterator()))
        }
        if let updatedObjects = userInfo[AnyHashable(NSUpdatedObjectsKey)] as? NSMutableSet {
            updatedObjectIDIterators.append(AnyIterator(
                updatedObjects.lazy.compactMap{ ($0 as? NSManagedObject)?.objectID }.makeIterator()))
        }
        if let deletedObjectIDs = userInfo[AnyHashable(NSDeletedObjectIDsKey)] as? NSMutableSet {
            deletedObjectIDIterators.append(AnyIterator(deletedObjectIDs.makeIterator()))
        }
        if let deletdeObjects = userInfo[AnyHashable(NSDeletedObjectsKey)] as? NSMutableSet {
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

// MARK: UiContextNotifier

internal protocol UiContextNotifier {
    var container: DataContainer { get }
    var context: _SessionContext { get }

    func enable()
    func disable()
}

extension UiContextNotifier {
    internal func notifyOnMainThread(userInfo: [AnyHashable: Any]) {
        DispatchQueue.performMainThreadTask {
            NotificationCenter.default.post(
                name: DataContainer.uiContextDidRefresh,
                object: container, userInfo: userInfo)
        }
    }
}

internal /*abstract*/ class _UiContextNotifier: UiContextNotifier {
    internal var context: _SessionContext

    internal unowned let container: DataContainer

    internal init(container: DataContainer) {
        self.context = container.backgroundSessionContext()
        self.container = container
    }

    func enable() {
        assertionFailure("Not implemented")
    }

    func disable() {
        assertionFailure("Not implemented")
    }

    deinit { disable() }
}

internal class ContextDidSaveNotifier: _UiContextNotifier {
    private let notificationName: Notification.Name = .NSManagedObjectContextDidSave

    override func enable() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave(notification:)),
            name: notificationName,
            object: context.rootContext)
    }

    override func disable() {
        NotificationCenter.default.removeObserver(
            self,
            name: notificationName,
            object: context.rootContext)
    }

    @objc
    internal func contextDidSave(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let managedObjectContext = notification.object as? NSManagedObjectContext,
            userInfo.contains(where: {
                ($0.key == AnyHashable(NSInsertedObjectsKey) ||
                $0.key == AnyHashable(NSUpdatedObjectsKey) ||
                $0.key == AnyHashable(NSDeletedObjectsKey)) &&
                ($0.value as? NSMutableSet)?.count ?? 0 > 0
            }) else { return }
        context.uiContext.perform(
            #selector(context.uiContext.mergeChanges(fromContextDidSave:)),
            on: Thread.main,
            with: notification,
            waitUntilDone: Thread.isMainThread)
        let merger = UserInfoMerger(userInfo: userInfo)
        let name = managedObjectContext.name ?? "Unknown"
        notifyOnMainThread(userInfo: [
            AnyHashable(name): merger.createUserInfo()
        ])
    }
}

@available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
internal class PersistentHistoryNotifier: _UiContextNotifier {

    internal let coordinator: NSPersistentStoreCoordinator
    internal var lastHistoryTokens: [URL: NSPersistentHistoryToken] = [:]
    internal var transactionLifetime: TimeInterval = 604_800

    private var lock = os_unfair_lock()

    private let logger = LogHandler.default

    internal override init(container: DataContainer) {
        coordinator = container.coreDataStack.coordinator
        super.init(container: container)
        setup()
    }

    internal func setup() {
        purgeHistory()

        for store in coordinator.persistentStores where store.url != nil
        {
            loadHistoryToken(for: store.url!)
        }
    }

    internal override func enable() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(persistentStoreHistoryChanged(_:)),
            name: Notification.Name("NSPersistentStoreRemoteChangeNotification"),
            object: coordinator)
    }

    internal override func disable() {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name("NSPersistentStoreRemoteChangeNotification"),
            object: coordinator)
    }

    internal func storeHistoryToken(_ token: NSPersistentHistoryToken, for storeURL: URL) {
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

    internal func loadHistoryToken(for storeURL: URL) {
        if storeURL.isDevNull { return }
        do {
            let tokenFileURL = tokenURL(for: storeURL)
            let tokenData = try Data(contentsOf: tokenFileURL)
            lastHistoryTokens[storeURL] = try NSKeyedUnarchiver
                .unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
        } catch let error {
            switch (error as NSError).code {
            case 260: break // File not found
            case 4864: break // Data corrupted
            default:
                logger.log(.error, "Failed to load history token", error: error)
            }
        }
    }
    
    private func tokenURL(for storeURL: URL) -> URL {
        storeURL.appendingPathExtension("tokendata")
    }

    @objc
    internal func persistentStoreHistoryChanged(_ notification: Notification) {
        guard let storeURL = notification.userInfo?["storeURL"] as? URL else { return }

        lock.lock()

        let uiContext = context.uiContext
        let rootContext = context.rootContext
        let transactions = loadPersistentHistory(storeURL: storeURL)
            .sorted(by: { $0.timestamp < $1.timestamp })
        var mergers: [AnyHashable: UserInfoMerger] = [:]
        
        if let lastToken = notification.userInfo?["historyToken"]
            as? NSPersistentHistoryToken ?? transactions.last?.token
        {
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
                fromRemoteContextSave: changes, into: [rootContext, uiContext])
        }

        lock.unlock()

        if transactions.isEmpty == false {
            let userInfo = mergers.mapValues { $0.createUserInfo() }
            notifyOnMainThread(userInfo: userInfo)
        }
    }

    private func loadPersistentHistory(storeURL: URL) -> [NSPersistentHistoryTransaction] {
        let fetchHistoryRequest = NSPersistentHistoryChangeRequest
            .fetchHistory(after: lastHistoryTokens[storeURL])
        return executePersistentHistoryRequest(fetchHistoryRequest)
    }
    
    internal func loadPersistentHistory(date: Date) -> [NSPersistentHistoryTransaction] {
        let fetchHistoryRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
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

    internal func purgeHistory() {
        let sevenDaysAgo = Date(timeIntervalSinceNow: -transactionLifetime)
        return deleteHistory(before: sevenDaysAgo)
    }

    internal func deleteHistory(before date: Date) {
        let purgeHistoryRequest = NSPersistentHistoryChangeRequest
            .deleteHistory(before: date)
        do {
            try context.rootContext.execute(purgeHistoryRequest)
        } catch {
            logger.log(.error, "Failed to purge persistent history", error: error)
        }
    }
}

extension Entity {
    public static func hasChanges(
        userInfo: [AnyHashable: Any], entities: [Entity.Type]) -> Bool
    {
        let inserted = userInfo[NSInsertedObjectIDsKey] as! AnySequence<NSManagedObjectID>
        let updated = userInfo[NSUpdatedObjectIDsKey] as! AnySequence<NSManagedObjectID>
        let deleted = userInfo[NSDeletedObjectIDsKey] as! AnySequence<NSManagedObjectID>
        let entityNames = Set(entities.map { $0.name })
        
        return inserted.contains { entityNames.contains($0.entity.name ?? "") } ||
            updated.contains { entityNames.contains($0.entity.name ?? "") } ||
            deleted.contains { entityNames.contains($0.entity.name ?? "") }
    }
}
