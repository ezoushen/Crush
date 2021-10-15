//
//  RelationshipMigration.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public protocol RelationshipMigration: PropertyMigration {
    func migrateRelationship(
        _ relationship: NSRelationshipDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSRelationshipDescription?
}

extension RelationshipMigration {
    public func migrateProperty(
        _ property: NSPropertyDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSPropertyDescription?
    {
        guard property == nil || property is NSAttributeDescription else {
            throw MigrationModelingError.internalTypeMismatch
        }
        return try migrateRelationship(
            property as? NSRelationshipDescription,
            callbackStore: &callbackStore)
    }
}

public struct AddRelationship: RelationshipMigration, AddPropertyMigration {
    public let originPropertyName: String? = nil

    public let name: String?
    public let isOptional: Bool
    public let isTransient: Bool
    public let isOrdered: Bool
    public let destinationEntity: String
    public let inverseRelationship: String?
    public let minCount: Int
    public let maxCount: Int
    public let deleteRule: NSDeleteRule

    public init(
        _ name: String,
        toOne destinationEntity: String,
        inverse inverseRelationship: String? = nil,
        isOptional: Bool = false,
        isTransient: Bool = false,
        isOrdered: Bool = false,
        deleteRule: NSDeleteRule = .nullifyDeleteRule
    ) {
        self.init(
            name: name,
            isOptional: isOptional,
            isTransient: isTransient,
            isOrdered: isOrdered,
            destinationEntity: destinationEntity,
            inverseRelationship: inverseRelationship,
            minCount: 1,
            maxCount: 1,
            deleteRule: deleteRule)
    }

    public init(
        _ name: String,
        toMany destinationEntity: String,
        inverse inverseRelationship: String? = nil,
        minCount: Int = 0,
        maxCount: Int = 0,
        isOptional: Bool = false,
        isTransient: Bool = false,
        isOrdered: Bool = false,
        deleteRule: NSDeleteRule = .nullifyDeleteRule
    ) {
        self.init(
            name: name,
            isOptional: isOptional,
            isTransient: isTransient,
            isOrdered: isOrdered,
            destinationEntity: destinationEntity,
            inverseRelationship: inverseRelationship,
            minCount: minCount,
            maxCount: maxCount,
            deleteRule: deleteRule)
    }

    private init(
        name: String,
        isOptional: Bool,
        isTransient: Bool,
        isOrdered: Bool,
        destinationEntity: String,
        inverseRelationship: String?,
        minCount: Int,
        maxCount: Int,
        deleteRule: NSDeleteRule)
    {
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.isOrdered = isOrdered
        self.destinationEntity = destinationEntity
        self.inverseRelationship = inverseRelationship
        self.minCount = minCount
        self.maxCount = maxCount
        self.deleteRule = deleteRule
    }

    public func createProperty(
        callbackStore: inout [EntityMigrationCallback]) -> NSPropertyDescription
    {
        let description = NSRelationshipDescription()
        description.name = name!
        description.isOptional = isOptional
        description.deleteRule = deleteRule
        description.minCount = minCount
        description.maxCount = maxCount
        description.isOrdered = isOrdered
        callbackStore.append {
            guard let desitnation = $0[destinationEntity]
            else { return }
            description.destinationEntity = desitnation
            if let inverse = inverseRelationship,
               let inverseDescription = desitnation.relationshipsByName[inverse] {
                description.inverseRelationship = inverseDescription
            }
        }
        return description
    }

    public func createPropertyMapping(
        from sourceProperty: NSPropertyDescription?,
        to destinationProperty: NSPropertyDescription?,
        of sourceEntity: NSEntityDescription) -> NSPropertyMapping?
    {
        let propertyMapping = NSPropertyMapping()
        propertyMapping.name = destinationProperty?.name
        return propertyMapping
    }
}

public typealias RemoveRelationship = RemoveProperty

public struct UpdateRelationship: RelationshipMigration {
    public let originPropertyName: String?
    public let originKeyPath: String

    public let name: String?
    public let isOptional: Bool?
    public let isTransient: Bool?
    public let isOrdered: Bool?
    public let destinationEntity: String?
    public let inverseRelationship: String?
    public let minCount: Int?
    public let maxCount: Int?
    public let deleteRule: NSDeleteRule?

    private let updateInverseRelationship: Bool

    public init(
        _ originPropertyName: String,
        name: String? = nil,
        toOne destinationEntity: String? = nil,
        inverse inverseRelationship: String?,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil,
        isOrdered: Bool? = nil,
        deleteRule: NSDeleteRule? = nil
    ) {
        self.init(
            originPropertyName: originPropertyName,
            name: name,
            isOptional: isOptional,
            isTransient: isTransient,
            isOrdered: isOrdered,
            destinationEntity: destinationEntity,
            inverseRelationship: inverseRelationship,
            minCount: 1,
            maxCount: 1,
            deleteRule: deleteRule,
            updateInverseRelationship: true)
    }

    public init(
        _ originPropertyName: String,
        name: String? = nil,
        toMany destinationEntity: String? = nil,
        inverse inverseRelationship: String?,
        minCount: Int? = nil,
        maxCount: Int? = nil,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil,
        isOrdered: Bool? = nil,
        deleteRule: NSDeleteRule? = nil
    ) {
        self.init(
            originPropertyName: originPropertyName,
            name: name,
            isOptional: isOptional,
            isTransient: isTransient,
            isOrdered: isOrdered,
            destinationEntity: destinationEntity,
            inverseRelationship: inverseRelationship,
            minCount: minCount,
            maxCount: maxCount,
            deleteRule: deleteRule,
            updateInverseRelationship: true)
    }

    public init(
        _ originPropertyName: String,
        name: String? = nil,
        toOne destinationEntity: String? = nil,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil,
        isOrdered: Bool? = nil,
        deleteRule: NSDeleteRule? = nil
    ) {
        self.init(
            originPropertyName: originPropertyName,
            name: name,
            isOptional: isOptional,
            isTransient: isTransient,
            isOrdered: isOrdered,
            destinationEntity: nil,
            inverseRelationship: nil,
            minCount: 1,
            maxCount: 1,
            deleteRule: deleteRule,
            updateInverseRelationship: false)
    }

    public init(
        _ originPropertyName: String,
        name: String? = nil,
        toMany destinationEntity: String? = nil,
        minCount: Int? = nil,
        maxCount: Int? = nil,
        isOptional: Bool? = nil,
        isTransient: Bool? = nil,
        isOrdered: Bool? = nil,
        deleteRule: NSDeleteRule? = nil
    ) {
        self.init(
            originPropertyName: originPropertyName,
            name: name,
            isOptional: isOptional,
            isTransient: isTransient,
            isOrdered: isOrdered,
            destinationEntity: nil,
            inverseRelationship: nil,
            minCount: minCount,
            maxCount: maxCount,
            deleteRule: deleteRule,
            updateInverseRelationship: false)
    }

    private init(
        originPropertyName: String,
        name: String?,
        isOptional: Bool?,
        isTransient: Bool?,
        isOrdered: Bool?,
        destinationEntity: String?,
        inverseRelationship: String?,
        minCount: Int?,
        maxCount: Int?,
        deleteRule: NSDeleteRule?,
        updateInverseRelationship: Bool)
    {
        self.originPropertyName = String(originPropertyName.split(separator: ".")[0])
        self.originKeyPath = originPropertyName
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.isOrdered = isOrdered
        self.destinationEntity = destinationEntity
        self.inverseRelationship = inverseRelationship
        self.minCount = minCount
        self.maxCount = maxCount
        self.deleteRule = deleteRule
        self.updateInverseRelationship = updateInverseRelationship
    }

    public func migrateRelationship(
        _ relationship: NSRelationshipDescription?,
        callbackStore: inout [EntityMigrationCallback]) throws -> NSRelationshipDescription?
    {
        guard let relationship = relationship else {
            let name = originPropertyName.contentDescription
            throw MigrationModelingError
                .migrationTargetNotFound("relationship \(name) not found")
        }
        if let name = name {
            relationship.name = name
        }
        if let isOptional = isOptional {
            relationship.isOptional = isOptional
        }
        if let isTransient = isTransient {
            relationship.isTransient = isTransient
        }
        if let deleteRule = deleteRule {
            relationship.deleteRule = deleteRule
        }
        if let maxCount = maxCount {
            relationship.maxCount = maxCount
        }
        if let minCount = minCount {
            relationship.minCount = minCount
        }
        if let destinationEntity = destinationEntity {
            callbackStore.append {
                guard let description = $0[destinationEntity]
                else { return }
                relationship.destinationEntity = description
            }
        }
        if updateInverseRelationship {
            callbackStore.append { entities in
                guard let inverse = inverseRelationship else {
                    return relationship.inverseRelationship = nil
                }
                guard let destination = relationship.destinationEntity else {
                    throw MigrationModelingError
                        .migrationTargetNotFound("failed to find destination")
                }
                if let inverseRelationship = destination.relationshipsByName[inverse] {
                    relationship.inverseRelationship = inverseRelationship
                } else {
                    throw MigrationModelingError.migrationTargetNotFound(
                        "failed to find inverse relationship \(inverse)")
                }
            }
        }
        return relationship
    }

    public func createPropertyMapping(
        from sourceProperty: NSPropertyDescription?,
        to destinationProperty: NSPropertyDescription?,
        of sourceEntity: NSEntityDescription) throws -> NSPropertyMapping?
    {
        guard let _ = sourceProperty,
              containsValue(forKeyPath: originKeyPath, in: sourceEntity),
              let destinationProperty = destinationProperty
        else {
            throw MigrationModelingError.migrationTargetNotFound(
                "neither sourceProperty nor destinationProperty should be nil")
        }
        let propertyMapping = NSPropertyMapping()
        propertyMapping.name = destinationProperty.name
        propertyMapping.valueExpression = .relationshipMapping(
            from: originKeyPath,
            to: destinationProperty.name)
        return propertyMapping
    }

    private func containsValue(
        forKeyPath keyPath: String,
        in entityDescription: NSEntityDescription) -> Bool
    {
        if keyPath.contains(".") == false {
            return entityDescription.relationshipsByName[keyPath] != nil
        }

        let components = keyPath.split(separator: ".")
        let name: String = String(components[0])
        let keyPath: String = components.dropFirst().joined(separator: ".")

        guard let destinationEntity = entityDescription
                .relationshipsByName[name]?.destinationEntity
        else { return false }

        return containsValue(forKeyPath: keyPath, in: destinationEntity)
    }
}
