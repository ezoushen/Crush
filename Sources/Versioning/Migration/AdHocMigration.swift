//
//  AdHocMigration.swift
//  
//
//  Created by ezou on 2021/10/16.
//

import CoreData
import Foundation

public enum AdHocMigrationError: Error {
    case sourceModelNotFound
}

public struct AdHocMigration: Hashable {
    public let sourceName: String
    public let migration: ModelMigration

    public init(_ name: String, migration: ModelMigration) {
        self.sourceName = name
        self.migration = migration
    }

    public func createMappingModel() throws -> NSMappingModel {
        guard let sourceModel = NSManagedObjectModel.load(name: sourceName)
        else { throw AdHocMigrationError.sourceModelNotFound }
        let destinationModel = try migration.migrateModel(sourceModel)
        return try migration.createMappingModel(
            from: sourceModel, to: destinationModel)
    }
}
