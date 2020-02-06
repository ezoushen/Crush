//
//  MigrationModel.swift
//  Crush
//
//  Created by ezou on 2019/10/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: Mapping Model Protocol

public protocol Migration {
    var sourceModel: NSManagedObjectModel { get }
    var destinationModel: NSManagedObjectModel { get }
    
    var inferredMappingModelAutomatically: Bool { get }
    
    func mappingModel() throws -> NSMappingModel
}

protocol MigrationModel: Migration, MappingModelMerger {
    func createMappingModel() throws -> NSMappingModel
    func fullMappingModel() throws -> NSMappingModel
}

extension MigrationModel {
    var inferredMappingModelAutomatically: Bool {
        return true
    }
    
    func createMappingModel() throws -> NSMappingModel {
        let mirror = Mirror(reflecting: self)
        let entityMappings: [NSEntityMapping] = try mirror.children
            .filter { $0.value is EntityMapping }
            .compactMap{
                guard let value = $0.value as? EntityMapping,
                      let label = $0.label else { return nil }
                let model = try value.entityMapping(sourceModel: sourceModel,
                                                    destinationModel: destinationModel)
                    model.name = label
                return model
            }
        
        let mappingModel = NSMappingModel()
        mappingModel.entityMappings = entityMappings
        return mappingModel
    }
    
    func fullMappingModel() throws -> NSMappingModel {
        let mappingModel = try createMappingModel()
        let inferredModel = try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
        return try mergeMappingModel(inferredMappingModel: inferredModel, mappingModel: mappingModel)
    }
    
    func mappingModel() throws -> NSMappingModel {
        return try inferredMappingModelAutomatically
            ? fullMappingModel()
            : createMappingModel()
    }
}

struct VersionMigration: MigrationModel {
    let sourceModel: NSManagedObjectModel
    
    let destinationModel: NSManagedObjectModel
    
    let entityMappings: [NSEntityMapping]
    
    init(from: SchemaProtocol, to: SchemaProtocol, mappings: [NSEntityMapping]) {
        self.entityMappings = mappings
        self.sourceModel = from.model.rawModel
        self.destinationModel = to.model.rawModel
    }
    
    func createMappingModel() throws -> NSMappingModel {
        let mappingModel = NSMappingModel()
        mappingModel.entityMappings = entityMappings
        return mappingModel
    }
}

struct CoreDataMigration: Migration {
    var sourceModel: NSManagedObjectModel
    
    var destinationModel: NSManagedObjectModel
    
    var inferredMappingModelAutomatically: Bool = true
    
    func mappingModel() throws -> NSMappingModel {
        if let model = NSMappingModel(from: Bundle.allBundles, forSourceModel: sourceModel, destinationModel: destinationModel) {
            return model
        }
        return try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    }
}
