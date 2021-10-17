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
}

extension RelationshipOption: MutablePropertyConfigurable {
    public typealias Description = NSRelationshipDescription
    
    public var id: Int {
        switch self {
        case .unidirectionalInverse:
            return 0x010
        case .maxCount:
            return 0x020
        case .minCount:
            return 0x030
        case .deleteRule:
            return 0x040
        }
    }
    
    public func updatePropertyDescription<D: NSPropertyDescription>(_ description: D) {
        guard let description = description as? Description else { return }
        switch self {
        case .unidirectionalInverse: break
        case .maxCount(let amount): description.maxCount = amount
        case .minCount(let amount): description.minCount = amount
        case .deleteRule(let rule): description.deleteRule = rule
        }
    }
}

public protocol RelationshipProtocol: ValuedProperty {
    associatedtype Destination: Entity
    associatedtype Source: Entity
    associatedtype Mapping: RelationMapping where Mapping.RuntimeObjectValue == PropertyValue
    
    var configuration: PropertyConfiguration { get set }
    var inverseName: String? { get set }
}

// MARK: - EntityRelationShipType
public protocol RelationMapping: FieldConvertible {
    associatedtype EntityType: Entity
    
    static var isOrdered: Bool { get }
    static func resolveMaxCount(_ amount: Int) -> Int
    static func resolveMinCount(_ amount: Int) -> Int
}

public protocol ToManyRelationMappingProtocol: RelationMapping { }

public protocol ToOneRelationMappingProtocol: RelationMapping { }

extension RelationMapping {
    static func getEnity(from value: NSManagedObject) -> ManagedObject<EntityType> {
        value as! ManagedObject<EntityType>
    }
}

public struct ToOne<EntityType: Entity>: ToOneRelationMappingProtocol, FieldConvertible {
    public typealias RuntimeObjectValue = ManagedObject<EntityType>?
    public typealias ManagedObjectValue = NSManagedObject?
    
    public static var isOrdered: Bool { false }
    
    public static func resolveMaxCount(_ amount: Int) -> Int {
        return 1
    }

    public static func resolveMinCount(_ amount: Int) -> Int {
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

public struct ToMany<EntityType: Entity>: ToManyRelationMappingProtocol, FieldConvertible {
    public typealias RuntimeObjectValue = MutableSet<ManagedObject<EntityType>>
    public typealias ManagedObjectValue = NSMutableSet
    
    public static var isOrdered: Bool { false }
    
    public static func resolveMaxCount(_ amount: Int) -> Int {
        return amount == 1 ? 0 : amount
    }

    public static func resolveMinCount(_ amount: Int) -> Int {
        return amount
    }
    
    @inline(__always)
    public static func convert(value: ManagedObjectValue) -> RuntimeObjectValue {
        return MutableSet(value)
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue) -> ManagedObjectValue {
        return value.mutableSet
    }
}

public struct ToOrderedMany<EntityType: Entity>: ToManyRelationMappingProtocol, FieldConvertible {
    public typealias RuntimeObjectValue = MutableOrderedSet<ManagedObject<EntityType>>
    public typealias ManagedObjectValue = NSMutableOrderedSet
    
    public static var isOrdered: Bool { true }
    
    public static func resolveMaxCount(_ amount: Int) -> Int {
        return amount == 1 ? 0 : amount
    }

    public static func resolveMinCount(_ amount: Int) -> Int {
        return amount
    }
    
    @inline(__always)
    public static func convert(value: ManagedObjectValue) -> RuntimeObjectValue {
        return MutableOrderedSet(value)
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue) -> ManagedObjectValue {
        return value.orderedSet
    }
}

public final class Relationship<O: Nullability, S: Entity, R: RelationMapping, T: Transience>: RelationshipProtocol {
    public typealias Transience = T
    public typealias PredicateValue = Destination
    public typealias PropertyValue = R.RuntimeObjectValue
    public typealias Mapping = R
    public typealias Source = S
    public typealias Destination = R.EntityType
    public typealias Nullability = O
    public typealias PropertyOption = RelationshipOption
    public typealias FieldConvertor = R

    public var isAttribute: Bool {
        false
    }
                
    public var name: String = ""
                
    public lazy var inverseName: String? = {
        guard let inverseKeyPath = inverseKeyPath,
              let inverseProperty = Destination.init()[keyPath: inverseKeyPath] as? PropertyProtocol
        else { return nil }
        return inverseProperty.name
    }()
    
    private var inverseKeyPath: PartialKeyPath<Destination>?
    
    public var configuration: PropertyConfiguration = []
        
    public convenience init(wrappedValue: PropertyValue, _ name: String) {
        self.init(name)
    }
    
    public init(_ name: String) {
        self.name = name
    }
    
    public init<R>(_ name: String, inverse: KeyPath<Destination, R>, options: PropertyConfiguration = [])
        where R: RelationshipProtocol, R.Destination == Source, R.Source == Destination {
        self.name = name
        self.inverseKeyPath = inverse
        self.configuration = options
    }
    
    public init(_ name: String, options: PropertyConfiguration) {
        self.name = name
        self.configuration = options
    }
    
    public func createPropertyDescription() -> NSPropertyDescription {
        let description = NSRelationshipDescription()
        
        configuration.configure(description: description)

        description.name = name
        description.isTransient = isTransient
        description.isOptional = O.isOptional
        description.isOrdered = R.isOrdered
        description.userInfo = description.userInfo ?? [:]
        description.maxCount = Mapping.resolveMaxCount(description.maxCount)
        description.minCount = Mapping.resolveMinCount(description.minCount)

        let isUniDirectional = configuration
            .contains(RelationshipOption.unidirectionalInverse)

        Caches.entity.getAndWait(Destination.entityCacheKey) {
            description.destinationEntity = $0

            guard let inverseName = self.inverseName else { return }

            if let inverseRelationship = $0.relationshipsByName[inverseName] {
                description.inverseRelationship = inverseRelationship
                guard isUniDirectional == false else { return }
                inverseRelationship.inverseRelationship = description
            } else {
                assertionFailure("inverse relationship not found")
            }
        }
        
        return description
    }
}

extension Relationship where Source == Destination {
    public convenience init(
        _ name: String,
        inverse: String,
        options: PropertyConfiguration = [])
    {
        self.init(name, options: options)
        self.inverseName = inverse
    }
}
