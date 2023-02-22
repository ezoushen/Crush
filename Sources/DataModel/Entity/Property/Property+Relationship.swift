//
//  Property+Relationship.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - EntityRelationship

public protocol RelationshipProtocol: WritableValuedProperty
where
    Description == NSRelationshipDescription,
    Mapping == FieldConvertor
{
    associatedtype Destination: Entity
    associatedtype Mapping: RelationMapping where Mapping.RuntimeObjectValue == Value
    
    var isUniDirectional: Bool { get set }
}

extension RelationshipProtocol {
    public var isAttribute: Bool { false }
}

// MARK: - EntityRelationShipType
public protocol RelationMapping: FieldConvertible {
    associatedtype EntityType: Entity

    static var isOrdered: Bool { get }
    static var minCount: Int { get }
    static var maxCount: Int { get }
}

public protocol ToOneRelationMappingProtocol: RelationMapping { }
public protocol ToManyRelationMappingProtocol: RelationMapping { }

public struct ToOne<EntityType: Entity>: ToOneRelationMappingProtocol, FieldConvertible {
    public typealias RuntimeObjectValue = ManagedObject<EntityType>?
    public typealias ManagedObjectValue = ManagedObject<EntityType>?

    public static var isOrdered: Bool { false }
    public static var maxCount: Int { 1 }
    public static var minCount: Int { 1 }
    
    @inlinable
    public static func convert(value: ManagedObjectValue) -> RuntimeObjectValue {
        guard let value = value else { return nil }
        return value
    }
}

public struct ToMany<EntityType: Entity>: ToManyRelationMappingProtocol, FieldConvertible {
    public typealias RuntimeObjectValue = MutableSet<ManagedObject<EntityType>>
    public typealias ManagedObjectValue = NSMutableSet
    
    public static var isOrdered: Bool { false }
    public static var maxCount: Int { 0 }
    public static var minCount: Int { 0 }
    
    @inlinable
    public static func convert(value: ManagedObjectValue) -> RuntimeObjectValue {
        return MutableSet(value)
    }
    
    public static func convert(value: RuntimeObjectValue) -> ManagedObjectValue {
        return value.mutableSet
    }
}

public struct ToOrdered<EntityType: Entity>: ToManyRelationMappingProtocol, FieldConvertible {
    public typealias RuntimeObjectValue = MutableOrderedSet<ManagedObject<EntityType>>
    public typealias ManagedObjectValue = NSMutableOrderedSet

    public static var isOrdered: Bool { true }
    public static var maxCount: Int { 0 }
    public static var minCount: Int { 0 }
    
    @inlinable
    public static func convert(value: ManagedObjectValue) -> RuntimeObjectValue {
        return MutableOrderedSet(value)
    }
    
    public static func convert(value: RuntimeObjectValue) -> ManagedObjectValue {
        return value.orderedSet
    }
}

public final class Relationship<R: RelationMapping>:
    RelationshipProtocol,
    TransientProperty,
    AnyFieldConvertible
{
    public typealias FieldConvertor = R
    public typealias PredicateValue = R.ManagedObjectValue
    public typealias PropertyValue = R.RuntimeObjectValue
    public typealias Destination = R.EntityType
    public typealias Description = NSRelationshipDescription

    public let name: String
    public var isUniDirectional: Bool = false

    public init(_ name: String) {
        self.name = name
    }

    public func createDescription() -> NSRelationshipDescription {
        let description = NSRelationshipDescription()
        description.name = name
        description.maxCount = Mapping.maxCount
        description.minCount = Mapping.minCount
        description.isOrdered = Mapping.isOrdered

        Caches.entity.getAndWait(Destination.entityCacheKey) {
            description.destinationEntity = $0
        }

        return description
    }
}
