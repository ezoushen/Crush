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
    case alreadyExist
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
        _coordinator ?? createPersistenStoreCoordinator(model: _schema.model as! DataModel)
    }
    
    var isConnected: Bool { _coordinator != nil }
    
    let type: DataContainer.StoreType
    let name: String
    let migrator: DataMigrator?
    
    private var _schema: SchemaProtocol
    
    public init(type: DataContainer.StoreType, name: String, version: SchemaProtocol) {
        self.type = type
        self.name = name
        self.migrator = type.migrator?.init(activeVersion: version)

        _schema = version
        _coordinator = Connection.connected["\(type)\(name)"]
    }
    
    internal func connect(completion: @escaping () -> Void) throws {
        if let _ = _coordinator {
            return completion()
        }
        if let url = currentUrl, FileManager.default.fileExists(atPath: url.path) {
            try migrator?.processStore(at: url)
        }
        
        addPersistentStore(completion)
    }
    
    internal func deleteDatabase() throws {
        guard let url = currentUrl, FileManager.default.fileExists(atPath: url.path) else {
            throw ConnectionError.databaseUrlNotFound
        }
        
        try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: type.raw, options: nil)
        try FileManager.default.removeItem(atPath: url.path)
        try FileManager.default.removeItem(atPath: url.path + "-shm")
        try FileManager.default.removeItem(atPath: url.path + "-wal")
    }
    
    private func createPersistentStoreURL(name: String) -> URL? {
        return type.createURL(docomentDirectoryUrl, with: name)
    }
    
    private func createPersistenStoreCoordinator(model: DataModel) -> NSPersistentStoreCoordinator {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model.rawModel)
        return persistentStoreCoordinator
    }
    
    private func addPersistentStore(_ completion: @escaping () -> Void) {
        let description = NSPersistentStoreDescription()
        description.type = type.raw
        description.url = currentUrl
        description.shouldMigrateStoreAutomatically = false
        description.shouldInferMappingModelAutomatically = false
        
        _coordinator = persistentStoreCoordinator
        _coordinator?.addPersistentStore(with: description) { _, _ in
            completion()
        }
    }
}
