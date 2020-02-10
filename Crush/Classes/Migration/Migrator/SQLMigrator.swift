//
//  CrushSQLMigrator.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/12/30.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

final public class SQLMigrator: DataMigrator {
    let migrations: [Migration]
    let versions: [SchemaProtocol]
    
    public let activeVersion: SchemaProtocol
    
    public init(activeVersion: SchemaProtocol) {
        self.activeVersion = activeVersion
        
        func createVersionChain(version: SchemaProtocol?) -> [SchemaProtocol] {
            guard let version = version else { return [] }
            return [version] + createVersionChain(version: version.lastVersion)
        }
        
        versions = createVersionChain(version: activeVersion).reversed()
        migrations = versions.compactMap{ $0.model.migration }
    }
    
    public func processStore(at url: URL) throws {
        let models = versions.compactMap{ $0.model.rawModel }
        let index = try indexOfCompatibleMom(at: url, models: models)
        let remaining = models.suffix(from: (index + 1))
        
        guard remaining.count > 0 else {
            return
        }
        
        forceWALCheckpointingForStore(at: url)
        
        _ = try remaining.reduce(models[index]) { source, destination in
            try migrateStore(at: url, from: source, to: destination)
            return destination
        }
    }
    
    private func migrateStore(at url: URL, from sourceModel: NSManagedObjectModel, to destinationModel: NSManagedObjectModel) throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        defer {
            _ = try? FileManager.default.removeItem(at: dir)
        }

        let mapping = try findMapping(from: sourceModel, to: destinationModel)
        let destURL = dir.appendingPathComponent(url.lastPathComponent)
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        
        try autoreleasepool {
            try manager.migrateStore(
                from: url,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: mapping,
                toDestinationURL: destURL,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil
            )
        }

        let psc = NSPersistentStoreCoordinator(managedObjectModel: destinationModel)
        try psc.replacePersistentStore(
            at: url,
            destinationOptions: nil,
            withPersistentStoreFrom: destURL,
            sourceOptions: nil,
            ofType: NSSQLiteStoreType
        )
    }
    
    private func forceWALCheckpointingForStore(at storeURL: URL) {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: DataContainer.StoreType.sql.raw,
            at: storeURL, options: nil
        ),
            let currentModel = versions
                .compactMap({ $0.model.rawModel })
                .first(where: {
                    $0.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
                })
        else {
            return
        }

        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)

            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = try persistentStoreCoordinator.addPersistentStore(ofType: DataContainer.StoreType.sql.raw, configurationName: nil, at: storeURL, options: options)
            try persistentStoreCoordinator.remove(store)
        } catch let error {
            fatalError("failed to force WAL checkpointing, error: \(error)")
        }
    }
    
    private func indexOfCompatibleMom(at storeURL: URL, models: [NSManagedObjectModel]) throws -> Int {
        let meta = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL)
        guard let index = models.firstIndex(where: { $0.isConfiguration(withName: nil, compatibleWithStoreMetadata: meta) }) else {
            throw MigratorError.incompatibleModels
        }
        return index
    }
    
    private func findMapping(from sourceModel: NSManagedObjectModel, to destinationModel: NSManagedObjectModel) throws -> NSMappingModel {
        
        if let mapping = migrations.first(where: {
            $0.sourceModel.versionIdentifiers.first == sourceModel.versionIdentifiers.first &&
            $0.destinationModel.versionIdentifiers.first == destinationModel.versionIdentifiers.first }) {
            return try mapping.mappingModel()
        }
        return try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    }
}
