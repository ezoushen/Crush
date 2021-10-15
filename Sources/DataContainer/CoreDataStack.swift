//
//  CoreDataStack.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public class CoreDataStack {
    public let storage: Storage
    public let dataModel: DataModel
    public let mergePolicy: NSMergePolicy

    internal var migratorDelegate: MigratorDelegate?
    internal var migrator: Migrator? = nil {
        didSet { migratorDidUpdate() }
    }

    internal private(set) var coordinator: NSPersistentStoreCoordinator!

    private let completionBlock: () -> Void

    init(
        storage: Storage,
        migrationChain: MigrationChain?,
        dataModel: DataModel,
        mergePolicy: NSMergePolicy,
        completion: @escaping () -> Void) throws
    {
        self.storage = storage
        self.dataModel = dataModel
        self.mergePolicy = mergePolicy
        self.completionBlock = completion
        self.migrator = Migrator.create(
            storage: storage,
            migrationChain: migrationChain,
            dataModel: dataModel)
        try migrateIfNeeded()
        coordinator = createPersistentStoreCoordinator()
        persistActiveDataModel()
    }

    private func migratorDidUpdate() {
        guard storage.storeType == NSSQLiteStoreType,
              let migrator = migrator,
              let model = loadLastActiveDataModel() else { return }
        migratorDelegate =
        SQLiteMigratorDelegate(managedObjectModel: model)
        migrator.delegate = migratorDelegate
    }

    private func loadLastActiveDataModel() -> NSManagedObjectModel? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = url.path+"/\(dataModel.name).crushmodel"
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(withFile: path) as? NSManagedObjectModel
    }

    private func persistActiveDataModel() {
        let data = NSKeyedArchiver.archivedData(withRootObject: dataModel.managedObjectModel)
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = url.path+"/\(dataModel.name).crushmodel"
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
        FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
    }

    private func migrateIfNeeded() throws {
        guard let migrator = migrator else { return }
        do {
            try migrator.migrate()
        } catch {
            if storage.options.contains(.preventAutoMigration) ||
                storage.options.contains(.preventInferringMappingModel) {
                throw error
            }
            LogHandler.default.log(
                .warning, "Custom migration failed with error \(error), trying lightweight migration later")
        }
    }

    private func createPersistentStoreCoordinator() -> NSPersistentStoreCoordinator {
        let cooridnator = NSPersistentStoreCoordinator(
            managedObjectModel: dataModel.managedObjectModel)
        cooridnator.addPersistentStore(with: storage.createDescription()) {
            if let error = $1 {
                fatalError("load persistent store failed with error \(error)")
            }
            self.completionBlock()
        }
        return cooridnator
    }

    internal func createWriterContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.mergePolicy = mergePolicy
        context.automaticallyMergesChangesFromParent = false
        return context
    }

    internal func createUiContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parent
        context.automaticallyMergesChangesFromParent = true
        return context
    }

    internal func createBackgroundContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = parent
        context.automaticallyMergesChangesFromParent = false
        return context
    }

    internal func createMainThreadContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parent
        context.automaticallyMergesChangesFromParent = false
        return context
    }
}
