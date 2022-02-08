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
    internal var lastHistoryToken: NSPersistentHistoryToken?
    internal var transactionLifetime: TimeInterval = 604_800

    private let logger = LogHandler.default

    internal override init(container: DataContainer) {
        coordinator = container.coreDataStack.coordinator
        super.init(container: container)
        setup()
    }

    internal func setup() {
        purgeHistory()
        loadHistoryToken()
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

    private var persistentHistoryQueue: DispatchQueue =
        DispatchQueue(label: (Bundle.main.bundleIdentifier ?? "") + ".persistentHistoryQueue" )

    internal lazy var tokenFileURL: URL = {
        let fileManager = FileManager.default
        let url = CurrentWorkingDirectory()
            .appendingPathComponent("CrushMeta", isDirectory: true)

        try! fileManager
            .createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil)

        return url.appendingPathComponent("token.data", isDirectory: false)
    }()

    internal func storeHistoryToken(_ token: NSPersistentHistoryToken) {
        do {
            let data = try NSKeyedArchiver
                .archivedData(withRootObject: token, requiringSecureCoding: true)
            try data.write(to: tokenFileURL)
            lastHistoryToken = token
        } catch {
            logger.log(.error, "Failed to store history token", error: error)
        }
    }

    internal func loadHistoryToken() {
        do {
            let tokenData = try Data(contentsOf: tokenFileURL)
            lastHistoryToken = try NSKeyedUnarchiver
                .unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
        } catch {
            logger.log(.error, "Failed to load history token", error: error)
        }
    }

    @objc
    internal func persistentStoreHistoryChanged(_ notification: Notification) {
        let uiContext = context.uiContext
        let rootContext = context.rootContext
        rootContext.performAsync {
            for session in self.loadPersistentHistory() {
                let txNotification = session.objectIDNotification()
                // Merge changes into root context
                rootContext.mergeChanges(fromContextDidSave: txNotification)
                // Merge changes into ui context
                uiContext.perform(
                    #selector(uiContext.mergeChanges(fromContextDidSave:)),
                    on: .main,
                    with: txNotification,
                    waitUntilDone: Thread.isMainThread)
            }

            self.notifyOnMainThread()

            if let lastToken = notification.userInfo?["historyToken"]
                    as? NSPersistentHistoryToken {
                self.storeHistoryToken(lastToken)
            }
        }
    }

    internal func loadPersistentHistory() -> [NSPersistentHistoryTransaction] {
        let fetchHistoryRequest = NSPersistentHistoryChangeRequest
            .fetchHistory(after: lastHistoryToken)
        return executePersistentHistoryRequest(fetchHistoryRequest)
    }
    
    internal func loadPersistentHistory(date: Date) -> [NSPersistentHistoryTransaction] {
        let fetchHistoryRequest = NSPersistentHistoryChangeRequest
            .fetchHistory(after: lastHistoryToken)
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
        let purgeHistoryRequest = NSPersistentHistoryChangeRequest
            .deleteHistory(before: sevenDaysAgo)
        do {
            try context.rootContext.execute(purgeHistoryRequest)
        } catch {
            logger.log(.error, "Failed to purge persistent history", error: error)
        }
    }
}
