//
//  DataModel.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol ObjectModel: AnyObject {
    var rawModel: NSManagedObjectModel! { get }
    var migration: Migration? { get }
    var previousModel: ObjectModel? { get }
}

public final class CoreDataModel: ObjectModel {
    public private(set) var rawModel: NSManagedObjectModel! = nil
    public var previousModel: ObjectModel?
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
        self.rawModel = NSManagedObjectModel(contentsOf: url)
        self.previousModel = previousModel
        precondition(rawModel != nil, "NSManagedObjectModel not found")
    }
    
    public func updateCacheKey() { }
}

var firstDescription: NSEntityDescription!

public final class DataModel: ObjectModel {
    
    public weak var previousModel: ObjectModel?
    
    public let rawModel: NSManagedObjectModel!
    public let migration: Migration?
    
    internal let entities: [Entity.Type]
    internal let versionString: String
    
    public init(version: DataSchema, entities: [Entity.Type]) {
        let coordinator = CacheCoordinator.shared
        let versionString = String(reflecting: version.self)
                
        self.versionString = versionString
        self.entities = entities

        if let model = coordinator.get(versionString, in: CacheType.objectModel) {
            rawModel = model
            migration = coordinator.get(versionString, in: CacheType.migration)
            return
        }

        let sorted = entities.sorted { !$1.isAbstract }
        let versionHashModifier = String(reflecting: version)
        
        let model = NSManagedObjectModel()
        let entities: [NSEntityDescription] = sorted.map { $0.entityDescription() }
        zip(sorted, entities).forEach { $0.0.createConstraints(description: $0.1) }
        model.versionIdentifiers = [versionHashModifier]
        model.entities = entities
        coordinator.set(versionString, value: model, in: CacheType.objectModel)
        
        rawModel = model
        previousModel = version.previousVersion?.model
        
        guard let lastVersion = version.previousVersion,
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
    
        coordinator.set(versionString, value: mapping, in: CacheType.migration)
        
        migration = mapping
    }
}
