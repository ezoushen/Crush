//
//  FetchedPropertyMigration.swift
//  
//
//  Created by EZOU on 2023/4/26.
//

import CoreData

public protocol FetchedPropertyMigration: PropertyMigration { }

extension FetchedPropertyMigration {
    public func createPropertyMapping(
        from sourceProperty: NSPropertyDescription?,
        to destinationProperty: NSPropertyDescription?,
        of sourceEntity: NSEntityDescription) throws -> NSPropertyMapping?
    {
        nil
    }
}

public struct AddFetchedProperty: FetchedPropertyMigration, AddPropertyMigration {
    
    public var hashModifier: String?
    public let originPropertyName: String? = nil
    
    public let name: String?
    public let fetchRequest: NSFetchRequest<NSFetchRequestResult>
    
    public init(name: String, fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        self.name = name
        self.fetchRequest = fetchRequest
    }
    
    public func migrateProperty(_ property: NSPropertyDescription?, callbackStore: inout [EntityMigrationCallback]) throws -> NSPropertyDescription? {
        createProperty(callbackStore: &callbackStore)
    }
    
    public func createProperty(callbackStore: inout [EntityMigrationCallback]) -> NSPropertyDescription {
        let description = NSFetchedPropertyDescription()
        description.name = name!
        description.fetchRequest = fetchRequest
        return description
    }
}

public struct UpdateFetchedProperty: FetchedPropertyMigration, UpdatePropertyMigration {
    public var hashModifierUpdated: Bool = false
    public var hashModifier: String?
    
    public let name: String?
    public let originPropertyName: String?
    public let fetchRequest: NSFetchRequest<NSFetchRequestResult>?
    
    public init(
        _ originPropertyName: String,
        name: String? = nil,
        fetchRequest: NSFetchRequest<NSFetchRequestResult>? = nil)
    {
        self.name = name
        self.originPropertyName = originPropertyName
        self.fetchRequest = fetchRequest
    }
    
    public func migrateProperty(_ property: NSPropertyDescription?, callbackStore: inout [EntityMigrationCallback]) throws -> NSPropertyDescription? {
        guard let property = property as? NSFetchedPropertyDescription else {
            throw MigrationModelingError.internalTypeMismatch
        }
        if let name {
            property.name = name
        }
        if let fetchRequest {
            property.fetchRequest = fetchRequest
        }
        return property
    }
}
