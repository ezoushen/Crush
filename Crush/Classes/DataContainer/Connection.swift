//
//  Connection.swift
//  Crush
//
//  Created by ezou on 2020/1/16.
//  Copyright © 2020 ezou. All rights reserved.
//

import CoreData

enum ConnectionError: Error {
    case databaseUrlNotFound
}

public final class Connection {
    private static var connected: [String: NSPersistentStoreCoordinator] = [:]
    
    private lazy var docomentDirectoryUrl: URL? = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }()
    
    lazy var currentUrl: URL? = {
        createPersistentStoreURL(name: name)
    }()
    
    private var _coordinator: NSPersistentStoreCoordinator?
    
    internal var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        _coordinator ?? createPersistenStoreCoordinator(model: schema.model)
    }
    
    let type: PersistentStoreType
    let name: String
    let migrator: DataMigrator
    
    private var schema: SchemaProtocol.Type {
        Swift.type(of: migrator.activeVersion)
    }
    
    public init(type: PersistentStoreType, name: String, migrator: DataMigrator) {
        self.type = type
        self.name = name
        self.migrator = migrator
        
        _coordinator = Connection.connected["\(type)\(name)"]
    }
    
    internal func connect(completion: @escaping () -> Void) throws {
        if let _ = _coordinator {
            return completion()
        }
        if let url = currentUrl, FileManager.default.fileExists(atPath: url.path) {
            try migrator.processStore(at: url)
        }
        
        addPersistentStore(completion)
    }
    
    internal func deleteDatabase() throws {
        guard let url = currentUrl, FileManager.default.fileExists(atPath: url.path) else {
            throw ConnectionError.databaseUrlNotFound
        }
        
        try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: type.type, options: nil)
        try FileManager.default.removeItem(atPath: url.path)
        try FileManager.default.removeItem(atPath: url.path + "-shm")
        try FileManager.default.removeItem(atPath: url.path + "-wal")
    }
    
    private func createPersistentStoreURL(name: String) -> URL? {
        return type.createURL(docomentDirectoryUrl, with: name)
    }
    
    private func createPersistenStoreCoordinator(model: DataModel) -> NSPersistentStoreCoordinator {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model.objectModel)
        return persistentStoreCoordinator
    }
    
    private func addPersistentStore(_ completion: @escaping () -> Void) {
        let description = NSPersistentStoreDescription()
        description.type = type.type
        description.url = currentUrl
        description.shouldMigrateStoreAutomatically = false
        description.shouldInferMappingModelAutomatically = false
        
        _coordinator = persistentStoreCoordinator
        _coordinator?.addPersistentStore(with: description) { _, _ in
            completion()
        }
    }
}
