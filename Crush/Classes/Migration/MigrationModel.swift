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
    associatedtype FromVersion: SchemaProtocol
    associatedtype ToVersion: SchemaProtocol
    
    func createMappingModel() throws -> NSMappingModel
    func fullMappingModel() throws -> NSMappingModel
}

extension MigrationModel {
    var sourceModel: NSManagedObjectModel {
        FromVersion.model.objectModel
    }

    var destinationModel: NSManagedObjectModel {
        ToVersion.model.objectModel
    }
    
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

struct VersionMigration<FromVersion: SchemaProtocol, ToVersion: SchemaProtocol>: MigrationModel {
    
    let entityMappings: [NSEntityMapping]
    
    init(from: FromVersion, to: ToVersion, mappings: [NSEntityMapping]) {
        self.entityMappings = mappings
    }
    
    func createMappingModel() throws -> NSMappingModel {
        let mappingModel = NSMappingModel()
        mappingModel.entityMappings = entityMappings
        return mappingModel
    }
}
