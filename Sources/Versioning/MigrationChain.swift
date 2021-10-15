//
//  MigrationChain.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

@resultBuilder
public struct MigrationChainBuilder {
    public static func buildBlock(_ components: ModelMigration...) -> [ModelMigration] {
        components
    }
}

public final class MigrationChain: IteratorProtocol {

    public struct Node {
        public let name: String
        public let mappingModel: NSMappingModel
        public let destinationManagedObjectModel: NSManagedObjectModel
    }

    private var index: Int = 0

    let migrations: [ModelMigration]

    private var _managedObjectModels: [NSManagedObjectModel]? = nil
    private var _mappingModels: [NSMappingModel]? = nil

    public init(_ migrations: [ModelMigration]) {
        self.migrations = migrations
    }

    public init(@MigrationChainBuilder _ builder: () -> [ModelMigration]) {
        self.migrations = builder()
    }

    public func next() -> Node? {
        guard let mappingModels = _mappingModels,
              let managedObjectModels = _managedObjectModels,
              mappingModels.count > index else { return nil }
        defer { index += 1}
        return Node(
            name: migrations[index+1].name,
            mappingModel: mappingModels[index],
            destinationManagedObjectModel: managedObjectModels[index+1])
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

    func setActiveVersion(managedObjectModel: NSManagedObjectModel?) {
        guard let managedObjectModels = _managedObjectModels,
              let managedObjectModel = managedObjectModel else {
                  return index = 0
              }
        index = managedObjectModels.firstIndex(of: managedObjectModel) ?? 0
    }

    func reset() {
        index = 0
    }
}
