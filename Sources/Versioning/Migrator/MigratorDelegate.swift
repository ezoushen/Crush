//
//  MigratorDelegate.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

internal protocol MigratorDelegate: AnyObject {
    func migrator(_ migrator: Migrator, willProcessStoreAt url: URL)
}

internal class SQLiteMigratorDelegate: MigratorDelegate {
    internal let lastActiveModel: NSManagedObjectModel

    internal init(managedObjectModel: NSManagedObjectModel) {
        self.lastActiveModel = managedObjectModel
    }

    internal func migrator(_ migrator: Migrator, willProcessStoreAt url: URL) {
        do {
            try forceWALCheckpointingForStore(at: url)
        } catch {
            LogHandler.default.log(
                .warning,
                "failed to force WAL check pointing for store at \(url), error: \(error)")
        }
    }

    private func forceWALCheckpointingForStore(at storeURL: URL) throws {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(
            managedObjectModel: lastActiveModel)
        let storage = Storage.sqlite(
            url: storeURL,
            options: .sqlitePragmas(["journal_model": "DELETE" as NSObject]))
        let description = storage.createDescription()
        persistentStoreCoordinator.addPersistentStore(with: description) { _, _ in }
        if let store = persistentStoreCoordinator.persistentStore(for: storeURL) {
            try persistentStoreCoordinator.remove(store)
        }
    }
}
