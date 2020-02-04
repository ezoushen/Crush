//
//  DataModel.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol DataModelProtocol {
    var objectModel: NSManagedObjectModel! { get }
}

public class CoreDataModel: DataModelProtocol {
    public private(set) var objectModel: NSManagedObjectModel! = nil
    
    public convenience init(modelName: String) {
        let url = Bundle.main.url(forResource: modelName, withExtension: "momd")
        
        precondition(url != nil, "xcdatamodel not found")
        
        self.init(url: url!)
    }
    
    public init(url: URL) {
        objectModel = NSManagedObjectModel(contentsOf: url)
        precondition(objectModel != nil, "NSManagedObjectModel not found")
    }
}

public class DataModel: DataModelProtocol {
    static private var modelCache: NSCache<NSString, NSManagedObjectModel> = .init()
    static private var mappingCache: NSCache<NSString, _MigrationContainerObject> = .init()
    
    public let objectModel: NSManagedObjectModel!
    public let migration: Migration?
    public var previousModel: DataModel?
    
    internal init() {
        objectModel = nil
        migration = nil
    }
    
    public init<VersionedSchema: VersionedSchemaProtocol>(version: VersionedSchema.Type, entities: [Entity.Type]) {
        let sorted = entities.sorted { !$1.isAbstract }
        let entities = sorted.map { $0.entityDescription() }
        let hashValue = NSString(string: String(reflecting: version.self))

        if let model = DataModel.modelCache.object(forKey: hashValue) {
            objectModel = model
            migration = DataModel.mappingCache.object(forKey: hashValue)?.migration
            return
        }

        let versionHashModifier = String(reflecting: version)
        let model = NSManagedObjectModel()
        model.entities = entities
        model.versionIdentifiers = [versionHashModifier]
        
        DataModel.modelCache.setObject(model, forKey: hashValue)
        
        objectModel = model
        
        if VersionedSchema.LastVersion.self != FirstVersion.self {
            let entityMappings = sorted.compactMap {
                return try? $0.createEntityMapping(sourceModel: VersionedSchema.LastVersion.model.objectModel,
                                                   destinationModel: model)
            }
            let mapping = VersionMigration(from: VersionedSchema.LastVersion.init(), to: version.init(), mappings: entityMappings)
            
            DataModel.mappingCache.setObject(_MigrationContainerObject(migration: mapping), forKey: hashValue)
            
            previousModel = VersionedSchema.LastVersion.model
            migration = mapping
        } else {
            previousModel = nil
            migration = nil
        }
        
    }
}

fileprivate class _MigrationContainerObject: NSObject {
    let migration: Migration
    
    init(migration: Migration) {
        self.migration = migration
    }
}
