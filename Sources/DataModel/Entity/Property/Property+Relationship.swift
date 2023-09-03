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
    public typealias RuntimeValue = EntityType.Driver?
    public typealias ManagedValue = NSManagedObject?
    public typealias PredicateValue = NSObject

    public static var isOrdered: Bool { false }
    public static var maxCount: Int { 1 }
    public static var minCount: Int { 1 }

    @inlinable public static var defaultManagedValue: NSManagedObject? { nil }
    @inlinable public static var defaultRuntimeValue: EntityType.Driver? { nil }
    
    @inlinable
    public static func convert(managedValue: NSManagedObject?) -> EntityType.Driver? {
        guard let managedValue else { return nil }
        return .init(managedValue)
    }
    
    @inlinable
    public static func convert(runtimeValue: EntityType.Driver?) -> NSManagedObject? {
        runtimeValue?.managedObject
    }
}

public struct ToMany<EntityType: Entity>: ToManyRelationMappingProtocol, PropertyType {
    public typealias RuntimeValue = MutableSet<EntityType.Driver>
    public typealias ManagedValue = NSMutableSet
    public typealias PredicateValue = NSObject

    public static var isOrdered: Bool { false }
    public static var maxCount: Int { 0 }
    public static var minCount: Int { 0 }
    
    @inline(__always)
    public static func convert(managedValue: ManagedValue) -> RuntimeValue {
        MutableSet(LazyMapMutableSet<NSManagedObject, EntityType.Driver>
            .from(managedValue, from: {
                ManagedDriver(unsafe: $0)
            }, to: {
                $0.managedObject
            }))
    }
    
    @inline(__always)
    public static func convert(runtimeValue: RuntimeValue) -> ManagedValue {
        guard let mappedSet = runtimeValue.mutableSet
                as? LazyMapMutableSet<NSManagedObject, EntityType.Driver> else {
            return runtimeValue.mutableSet
        }
        return mappedSet.mutableSet
    }

    @inlinable public static var defaultManagedValue: ManagedValue { [] }
    @inlinable public static var defaultRuntimeValue: RuntimeValue { [] }
}

public struct ToOrdered<EntityType: Entity>: ToManyRelationMappingProtocol, PropertyType {
    public typealias RuntimeValue = MutableOrderedSet<EntityType.Driver>
    public typealias ManagedValue = NSMutableOrderedSet
    public typealias PredicateValue = NSObject

    public static var isOrdered: Bool { true }
    public static var maxCount: Int { 0 }
    public static var minCount: Int { 0 }
    
    @inline(__always)
    public static func convert(managedValue: ManagedValue) -> RuntimeValue {
        MutableOrderedSet(LazyMapMutableOrderedSet<NSManagedObject, EntityType.Driver>
            .from(managedValue, from: {
                ManagedDriver(unsafe: $0)
            }, to: {
                $0.managedObject
            }))
    }
    
    @inline(__always)
    public static func convert(runtimeValue: RuntimeValue) -> ManagedValue {
        guard let mappedSet = runtimeValue.orderedSet
                as? LazyMapMutableOrderedSet<NSManagedObject, EntityType.Driver> else {
            return runtimeValue.orderedSet
        }
        return mappedSet.mutableOrderedSet
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
