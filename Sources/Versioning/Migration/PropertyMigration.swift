//
//  PropertyMigration.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public protocol PropertyMigration {
    var hashModifier: String? { get set }
    var originPropertyName: String? { get }
    var name: String? { get }

    func migrateProperty(
        _ property: NSPropertyDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSPropertyDescription?

    func createPropertyMapping(
        from sourceProperty: NSPropertyDescription?,
        to destinationProperty: NSPropertyDescription?,
        of sourceEntity: NSEntityDescription) throws -> NSPropertyMapping?

    func versionHashModifier(_ modifier: String?) -> Self
}

extension PropertyMigration {
    public func versionHashModifier(_ modifier: String?) -> Self {
        var migration = self
        migration.hashModifier = modifier
        return migration
    }

    public func customize(_ block: (inout Self) -> Void) -> Self {
        var migration = self
        block(&migration)
        return migration
    }
}

public protocol AddPropertyMigration: PropertyMigration {
    func createProperty(callbackStore: inout [EntityMigrationCallback]) -> NSPropertyDescription
}

extension AddPropertyMigration where Self: AttributeMigration {
    public func migrateAttribute(
        _ attribute: NSAttributeDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSAttributeDescription?
    {
        guard let property = createProperty(
            callbackStore: &callbackStore) as? NSAttributeDescription
        else {
            throw MigrationModelingError.internalTypeMismatch
        }
        return property
    }
}

extension AddPropertyMigration where Self: RelationshipMigration {
    public func migrateRelationship(
        _ relationship: NSRelationshipDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSRelationshipDescription?
    {
        guard let property = createProperty(
            callbackStore: &callbackStore) as? NSRelationshipDescription
        else {
            throw MigrationModelingError.internalTypeMismatch
        }
        return property
    }
}

public protocol UpdatePropertyMigration: PropertyMigration {
    var hashModifierUpdated: Bool { get set }
}

extension UpdatePropertyMigration {
    public func versionHashModifier(_ modifier: String?) -> Self {
        var updateAttribute = self
        updateAttribute.hashModifierUpdated = true
        updateAttribute.hashModifier = modifier
        return updateAttribute
    }
}

public struct RemoveProperty: PropertyMigration {
    public var originPropertyName: String? { name }
    public let name: String?

    public var hashModifier: String? = nil

    public init(_ name: String) {
        self.name = name
    }

    public func migrateProperty(
        _ property: NSPropertyDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSPropertyDescription?
    {
        return nil
    }

    public func createPropertyMapping(
        from sourceProperty: NSPropertyDescription?,
        to destinationProperty: NSPropertyDescription?,
        of sourceEntity: NSEntityDescription) -> NSPropertyMapping?
    {
        return nil
    }
}
