//
//  Property+Relationship.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - EntityRelationship

protocol EntityCachedProtocol: AnyObject {
    var cache: EntityCache? { get set }
}

public protocol RelationshipProtocol: WritableProperty
where
    Description == NSRelationshipDescription,
    Mapping == PropertyType
{
    associatedtype Destination: Entity
    associatedtype Mapping: RelationMapping where Mapping.RuntimeValue == RuntimeValue
    
    var isUniDirectional: Bool { get set }
}

extension RelationshipProtocol {
    public var isAttribute: Bool { false }
}

// MARK: - EntityRelationShipType
public protocol RelationMapping: PropertyType {
    associatedtype EntityType: Entity

    static var isOrdered: Bool { get }
    static var minCount: Int { get }
    static var maxCount: Int { get }
}

public protocol ToOneRelationMappingProtocol: RelationMapping { }
public protocol ToManyRelationMappingProtocol: RelationMapping { }

public struct ToOne<EntityType: Entity>: ToOneRelationMappingProtocol, PropertyType {
    public typealias RuntimeValue = ManagedObject<EntityType>?
    public typealias ManagedValue = ManagedObject<EntityType>?
    public typealias PredicateValue = NSObject

    public static var isOrdered: Bool { false }
    public static var maxCount: Int { 1 }
    public static var minCount: Int { 1 }

    @inlinable public static var defaultManagedValue: ManagedObject<EntityType>? { nil }
    @inlinable public static var defaultRuntimeValue: ManagedObject<EntityType>? { nil }
}

public struct ToMany<EntityType: Entity>: ToManyRelationMappingProtocol, PropertyType {
    public typealias RuntimeValue = MutableSet<ManagedObject<EntityType>>
    public typealias ManagedValue = NSMutableSet
    public typealias PredicateValue = NSObject

    public static var isOrdered: Bool { false }
    public static var maxCount: Int { 0 }
    public static var minCount: Int { 0 }
    
    @inlinable
    public static func convert(managedValue: ManagedValue) -> RuntimeValue {
        return MutableSet(managedValue)
    }
    
    public static func convert(runtimeValue: RuntimeValue) -> ManagedValue {
        return runtimeValue.mutableSet
    }

    @inlinable public static var defaultManagedValue: ManagedValue { [] }
    @inlinable public static var defaultRuntimeValue: RuntimeValue { [] }
}

public struct ToOrdered<EntityType: Entity>: ToManyRelationMappingProtocol, PropertyType {
    public typealias RuntimeValue = MutableOrderedSet<ManagedObject<EntityType>>
    public typealias ManagedValue = NSMutableOrderedSet
    public typealias PredicateValue = NSObject

    public static var isOrdered: Bool { true }
    public static var maxCount: Int { 0 }
    public static var minCount: Int { 0 }
    
    @inlinable
    public static func convert(managedValue: ManagedValue) -> RuntimeValue {
        return MutableOrderedSet(managedValue)
    }
    
    public static func convert(runtimeValue: RuntimeValue) -> ManagedValue {
        return runtimeValue.orderedSet
    }

    @inlinable public static var defaultManagedValue: ManagedValue { [] }
    @inlinable public static var defaultRuntimeValue: RuntimeValue { [] }
}

public final class Relationship<Mapping: RelationMapping>:
    RelationshipProtocol,
    EntityCachedProtocol,
    TransientProperty
{
    public typealias PropertyType = Mapping
    public typealias PredicateValue = Mapping.ManagedValue
    public typealias PropertyValue = Mapping.RuntimeValue
    public typealias Destination = Mapping.EntityType
    public typealias Description = NSRelationshipDescription

    public let name: String
    public var isUniDirectional: Bool = false

    var cache: EntityCache?

    public init(_ name: String) {
        self.name = name
    }

    public func createPropertyDescription() -> NSRelationshipDescription {
        let description = NSRelationshipDescription()
        description.name = name
        description.maxCount = Mapping.maxCount
        description.minCount = Mapping.minCount
        description.isOrdered = Mapping.isOrdered

        cache?.get(Destination.entityCacheKey) {
            description.destinationEntity = $0
        }

        return description
    }
}
