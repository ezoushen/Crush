//
//  Property+Relationship.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - EntityRelationship

public enum RelationshipOption {
    case unidirectionalInverse
    case maxCount(Int)
    case minCount(Int)
    case deleteRule(NSDeleteRule)
    case isOrdered(Bool)
}

extension RelationshipOption: MutablePropertyConfigurable {
    public typealias Description = NSRelationshipDescription
    
    public func updatePropertyDescription<D: NSPropertyDescription>(_ description: D) {
        guard let description = description as? Description else { return }
        switch self {
        case .unidirectionalInverse:
            description.userInfo = (description.userInfo ?? [:])
            description.userInfo?[UserInfoKey.inverseUnidirectional] = true
        case .maxCount(let amount): description.maxCount = amount
        case .minCount(let amount): description.minCount = amount
        case .deleteRule(let rule): description.deleteRule = rule
        case .isOrdered(let flag): description.isOrdered = flag
        }
    }
}

public protocol RelationshipProtocol: ValuedProperty {
    associatedtype Destination: Entity
    associatedtype Source: Entity
    associatedtype Mapping: RelationMapping
    associatedtype InverseMapping: RelationMapping
    
    var configuration: PropertyConfiguration { get set }
    var inverseKeyPath: AnyKeyPath! { get set }
    
    init<R: RelationshipProtocol>(
        _ name: String,
        inverse: KeyPath<Destination, R>,
        options: PropertyConfiguration)
    where
        R.Destination == Source,
        R.Source == Destination,
        R.Mapping == InverseMapping,
        R.InverseMapping == Mapping
}

// MARK: - EntityRelationShipType
public protocol RelationMapping: FieldConvertible {
    associatedtype EntityType: Entity
    
    static func resolveMaxCount(_ amount: Int) -> Int
}

extension RelationMapping {
    static func getEnity(from value: NSManagedObject) -> ManagedObject<EntityType> {
        value as! ManagedObject<EntityType>
    }
}

public struct ToOne<EntityType: Entity>: RelationMapping, FieldConvertible {
    public typealias RuntimeObjectValue = ManagedObject<EntityType>?
    public typealias ManagedObjectValue = NSManagedObject?
    
    public static func resolveMaxCount(_ amount: Int) -> Int {
        return 1
    }
    
    @inline(__always)
    public static func convert(value: ManagedObjectValue) -> RuntimeObjectValue {
        guard let value = value else { return nil }
        return getEnity(from: value)
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue) -> ManagedObjectValue {
        return value
    }
}

public struct ToMany<EntityType: Entity>: RelationMapping, FieldConvertible {
    public typealias RuntimeObjectValue = Set<ManagedObject<EntityType>>
    public typealias ManagedObjectValue = NSSet?
    
    public static func resolveMaxCount(_ amount: Int) -> Int {
        return amount == 1 ? 0 : amount
    }
    
    @inline(__always)
    public static func convert(value: ManagedObjectValue) -> RuntimeObjectValue {
        return Set(value?.allObjects.compactMap{ getEnity(from: $0 as! NSManagedObject) } ?? [])
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue) -> ManagedObjectValue {
        return value as ManagedObjectValue
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue, with: @autoclosure () -> ManagedObjectValue) -> ManagedObjectValue {
        let nsset = with()
        let mutableSet = nsset?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        mutableSet.removeAllObjects()
        mutableSet.union(Set(value.map{ $0 }))
        return mutableSet
    }
}

public final class Relationship<O: Nullability, I: RelationMapping, R: RelationMapping>: RelationshipProtocol where R.RuntimeObjectValue: Hashable {
    public typealias PredicateValue = Destination
    public typealias PropertyValue = R.RuntimeObjectValue
    public typealias InverseMapping = I
    public typealias Mapping = R
    public typealias Source = I.EntityType
    public typealias Destination = R.EntityType
    public typealias Nullability = O
    public typealias PropertyOption = RelationshipOption
    public typealias FieldConvertor = R

    public var isAttribute: Bool {
        false
    }
                
    public var name: String = ""
                
    public var inverseKeyPath: AnyKeyPath!
    
    public var configuration: PropertyConfiguration = []
        
    public convenience init(wrappedValue: PropertyValue, _ name: String) {
        self.init(name)
    }
    
    public init(_ name: String) {
        self.name = name
    }
    
    public init<R>(_ name: String, inverse: KeyPath<Destination, R>, options: PropertyConfiguration = [])
        where R: RelationshipProtocol, R.Destination == Source, R.Source == Destination, R.Mapping == InverseMapping, R.InverseMapping == Mapping {
        self.name = name
        self.inverseKeyPath = inverse
        self.configuration = options
    }
    
    public init(_ name: String, options: PropertyConfiguration) {
        self.name = name
        self.configuration = options
    }
    
    public func emptyPropertyDescription() -> NSPropertyDescription {
        let description = NSRelationshipDescription()
        
        configuration.configure(description: description)

        description.isOptional = O.isOptional
        description.isTransient = isTransient
        description.name = name
        description.userInfo = description.userInfo ?? [:]
        description.userInfo?[UserInfoKey.relationshipDestination] = Destination.entityCacheKey
        description.maxCount = Mapping.resolveMaxCount(description.maxCount)

        if let inverseKeyPath = inverseKeyPath {
            description.userInfo?[UserInfoKey.inverseRelationship] = inverseKeyPath
        }
        
        return description
    }
}
