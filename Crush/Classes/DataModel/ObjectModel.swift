//
//  DataModel.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol ObjectModel {
    var rawModel: NSManagedObjectModel! { get }
    var migration: Migration? { get }
    var previousModel: ObjectModel? { get }
}

public class CoreDataModel: ObjectModel {
    public private(set) var rawModel: NSManagedObjectModel! = nil
    public var previousModel: ObjectModel? { nil }
    public var migration: Migration? {
        guard let previousModel = previousModel else { return nil }
        return CoreDataMigration(sourceModel: rawModel, destinationModel: previousModel.rawModel)
    }
    
    public convenience init(modelName: String, previousModel: ObjectModel? = nil) {
        let url = Bundle.main.url(forResource: modelName, withExtension: "momd")
        
        precondition(url != nil, "xcdatamodel not found")
        
        self.init(url: url!, previousModel: previousModel)
    }
    
    public init(url: URL, previousModel: ObjectModel? = nil) {
        rawModel = NSManagedObjectModel(contentsOf: url)
        precondition(rawModel != nil, "NSManagedObjectModel not found")
    }
}

public class DataModel: ObjectModel {
    static private var modelCache: NSCache<NSString, NSManagedObjectModel> = .init()
    static private var mappingCache: NSCache<NSString, _MigrationContainerObject> = .init()
    
    public let rawModel: NSManagedObjectModel!
    public let migration: Migration?
    public var previousModel: ObjectModel?
    
    public init(version: SchemaProtocol, entities: [Entity.Type]) {
        let sorted = entities.sorted { !$1.isAbstract }
        let entities = sorted.map { $0.entityDescription() }
        let hashValue = NSString(string: String(reflecting: version.self))

        if let model = DataModel.modelCache.object(forKey: hashValue) {
            rawModel = model
            migration = DataModel.mappingCache.object(forKey: hashValue)?.migration
            return
        }

        let versionHashModifier = String(reflecting: version)
        let model = NSManagedObjectModel()
        model.entities = entities
        model.versionIdentifiers = [versionHashModifier]
        
        DataModel.modelCache.setObject(model, forKey: hashValue)
        
        rawModel = model
        previousModel = version.lastVersion?.model

        guard let lastVersion = version.lastVersion,
              let previousModel = self.previousModel else {
            migration = nil
            return
        }
        
        let entityMappings = sorted.compactMap {
            try? $0.createEntityMapping(sourceModel: previousModel.rawModel,
                                        destinationModel: model)
        }
        let mapping = VersionMigration(from: lastVersion,
                                       to: version,
                                       mappings: entityMappings)
        
        DataModel.mappingCache.setObject(_MigrationContainerObject(migration: mapping), forKey: hashValue)
        
        migration = mapping
    }
}

fileprivate class _MigrationContainerObject: NSObject {
    let migration: Migration
    
    init(migration: Migration) {
        self.migration = migration
    }
}
