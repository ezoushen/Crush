//
//  PersistentHistoryTracker.swift
//  
//
//  Created by ezou on 2021/10/17.
//

import CoreData
import Foundation

internal protocol UiContextNotifier {
    var container: DataContainer { get }
    var context: _SessionContext { get }

    func enable()
    func disable()
}

extension UiContextNotifier {
    internal func notifyOnMainThread() {
        DispatchQueue.performMainThreadTask {
            NotificationCenter.default.post(
                name: DataContainer.uiContextDidRefresh,
                object: container, userInfo: nil)
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
    override func enable() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave(notification:)),
            name: .NSManagedObjectContextDidSave,
            object: context.rootContext)
    }

    override func disable() {
        NotificationCenter.default.removeObserver(
            self,
            name: .NSManagedObjectContextDidSave,
            object: context.rootContext)
    }

    @objc
    internal func contextDidSave(notification: Notification) {
        context.uiContext.perform(
            #selector(context.uiContext.mergeChanges(fromContextDidSave:)),
            on: Thread.main,
            with: notification,
            waitUntilDone: Thread.isMainThread)

        notifyOnMainThread()
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

        for store in coordinator.persistentStores
        where store.url != nil &&
              store.options?[NSPersistentHistoryTrackingKey] as? NSNumber == true &&
              store.options?["NSPersistentStoreRemoteChangeNotificationOptionKey"] as? NSNumber == true
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
        do {
            let tokenFileURL = storeURL.appendingPathExtension(".tokendata")
            let data = try NSKeyedArchiver
                .archivedData(withRootObject: token, requiringSecureCoding: true)
            try data.write(to: tokenFileURL)
            lastHistoryTokens[storeURL] = token
        } catch {
            logger.log(.error, "Failed to store history token", error: error)
        }
    }

    internal func loadHistoryToken(for storeURL: URL) {
        do {
            let tokenFileURL = storeURL.appendingPathExtension(".tokendata")
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

    @objc
    internal func persistentStoreHistoryChanged(_ notification: Notification) {
        guard let storeURL = notification.userInfo?["storeURL"] as? URL else { return }

        os_unfair_lock_lock(&lock)

        let id = UUID()
        let uiContext = context.uiContext
        let rootContext = context.rootContext
        let transactions = loadPersistentHistory(storeURL: storeURL)

        if let lastToken = notification.userInfo?["historyToken"]
            as? NSPersistentHistoryToken {
            storeHistoryToken(lastToken, for: storeURL)
        }

        for transaction in transactions.sorted(by: { $0.timestamp < $1.timestamp }) {
            let notification = transaction.objectIDNotification()

            guard let changes = notification.userInfo else { continue }

            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: changes, into: [rootContext, uiContext])
        }

        os_unfair_lock_unlock(&lock)

        if transactions.isEmpty == false {
            notifyOnMainThread()
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
