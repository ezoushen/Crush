//
//  PersistentHistoryTracker.swift
//  
//
//  Created by ezou on 2021/10/17.
//

import CoreData
import Foundation

internal class PersistentHistoryTracker {

    internal var lastHistoryToken: NSPersistentHistoryToken?

    private let logger = LogHandler.default

    internal var context: _SessionContext
    internal var coordinator: NSPersistentStoreCoordinator
    internal let legacyMode: Bool
    
    internal var transactionLifetime: TimeInterval = 604_800

    internal init(context: _SessionContext, coordinator: NSPersistentStoreCoordinator) {
        self.context = context
        self.coordinator = coordinator
        self.legacyMode = !coordinator.persistentStores.contains(where: {
            guard let value = $0.options?["NSPersistentStoreRemoteChangeNotificationOptionKey"]
                    as? NSObject else { return false }
            return value == NSNumber(booleanLiteral: true)
        })
        setup()
    }

    internal func setup() {
        if #available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *), !legacyMode {
            purgeHistory()
            loadHistoryToken()
        }
    }

    internal func enable() {
        if #available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *), !legacyMode {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(persistentStoreHistoryChanged(_:)),
                name: Notification.Name("NSPersistentStoreRemoteChangeNotification"),
                object: coordinator)
        } else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(contextDidSave(notification:)),
                name: .NSManagedObjectContextDidSave,
                object: context.rootContext)
        }
    }

    internal func disable() {
        if #available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *), !legacyMode {
            NotificationCenter.default.removeObserver(
                self,
                name: Notification.Name("NSPersistentStoreRemoteChangeNotification"),
                object: coordinator)
        } else {
            NotificationCenter.default.removeObserver(
                self,
                name: .NSManagedObjectContextDidSave,
                object: context.rootContext)
        }
    }

    deinit {
        disable()
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

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
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

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
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
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
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

            if let lastToken = notification.userInfo?["historyToken"]
                    as? NSPersistentHistoryToken {
                self.storeHistoryToken(lastToken)
            }
        }
        notifyOnMainThread()
    }

    internal func notifyOnMainThread() {
        DispatchQueue.performMainThreadTask {
            NotificationCenter.default.post(
                name: DataContainer.uiContextDidRefresh,
                object: self, userInfo: nil)
        }
    }

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    internal func loadPersistentHistory() -> [NSPersistentHistoryTransaction] {
        let fetchHistoryRequest = NSPersistentHistoryChangeRequest
            .fetchHistory(after: lastHistoryToken)
        return executePersistentHistoryRequest(fetchHistoryRequest)
    }
    
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    internal func loadPersistentHistory(date: Date) -> [NSPersistentHistoryTransaction] {
        let fetchHistoryRequest = NSPersistentHistoryChangeRequest
            .fetchHistory(after: lastHistoryToken)
        return executePersistentHistoryRequest(fetchHistoryRequest)
    }
    
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
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

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
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
