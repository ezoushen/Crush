//
//  MigrationChain.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

/// You can defined how the data model changed over time.
///
/// It simply saved a collection of model migrations.
public final class MigrationChain {

    let migrations: [ModelMigration]

    private var _managedObjectModels: [NSManagedObjectModel]? = nil
    private var _mappingModels: [NSMappingModel]? = nil

    public init(_ migrations: [ModelMigration]) {
        self.migrations = migrations
    }

    public init(
        @OrderedSetBuilder<ModelMigration>
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
            lastModel.versionIdentifiers = [migration.name]
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
