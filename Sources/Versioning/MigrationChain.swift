//
//  MigrationChain.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public final class MigrationChain {

    let migrations: [ModelMigration]

    fileprivate var _managedObjectModels: [NSManagedObjectModel]? = nil
    fileprivate var _mappingModels: [NSMappingModel]? = nil

    public init(_ migrations: [ModelMigration]) {
        self.migrations = migrations
    }

    public init(
        @CollectionBuilder<ModelMigration>
        builder: () -> OrderedSet<ModelMigration>)
    {
        self.migrations = Array(builder())
    }

    public func managedObjectModels() throws -> [NSManagedObjectModel] {
        if let managedObjectModels = _managedObjectModels {
            return managedObjectModels
        }
        var lastModel: NSManagedObjectModel = .init()
        let managedObjectModels = try migrations.map {
            migration -> NSManagedObjectModel in
            lastModel = try migration.migrateModel(lastModel)
            return lastModel
        }
        _managedObjectModels = managedObjectModels
        return managedObjectModels
    }

    public func mappingModels() throws -> [NSMappingModel] {
        if let mappingModels = _mappingModels {
            return mappingModels
        }
        let managedObjectModels = try managedObjectModels()
        var mappingModels: [NSMappingModel] = []

        defer { _mappingModels = mappingModels }

        guard var lastManagedObjectModel = managedObjectModels.first
        else { return mappingModels }

        let sequnce = zip(migrations, managedObjectModels).dropFirst()

        for (migration, model) in sequnce {
            defer { lastManagedObjectModel = model }
            let mappingModel = try migration.createMappingModel(
                from: lastManagedObjectModel, to: model)
            mappingModels.append(mappingModel)
        }
        return mappingModels
    }
}
