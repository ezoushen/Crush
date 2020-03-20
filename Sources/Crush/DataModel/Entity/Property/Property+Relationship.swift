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

public protocol RelationshipProtocol: NullableProperty {
    associatedtype Destination: Entity
    associatedtype Source: Entity
    associatedtype Mapping: RelationMapping
    associatedtype InverseMapping: RelationMapping
    
    var inverseKeyPath: AnyKeyPath! { get set }
    
    init<R: RelationshipProtocol>(wrappedValue: PropertyValue?, inverse: KeyPath<Destination, R>, options: PropertyConfiguration) where R.Destination == Source, R.Source == Destination, R.Mapping == InverseMapping, R.InverseMapping == Mapping
}

// MARK: - EntityRelationShipType
public protocol RelationMapping: FieldConvertible {
    associatedtype EntityType: HashableEntity
    
    static func resolveMaxCount(_ amount: Int) -> Int
}

public struct ToOne<EntityType: HashableEntity>: RelationMapping, FieldConvertible {
    public typealias RuntimeObjectValue = EntityType?
    public typealias ManagedObjectValue = NSManagedObject?
    
    public static func resolveMaxCount(_ amount: Int) -> Int {
        return 1
    }
    
    @inline(__always)
    public static func convert(value: ManagedObjectValue, proxyType: PropertyProxyType) -> RuntimeObjectValue {
        guard let value = value else { return nil }
        return EntityType.init(value, proxyType: proxyType)
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue, proxyType: PropertyProxyType) -> ManagedObjectValue {
        return value?.rawObject
    }
}

public struct ToMany<EntityType: HashableEntity>: RelationMapping, FieldConvertible {
    public typealias RuntimeObjectValue = Set<EntityType>
    public typealias ManagedObjectValue = NSSet
    
    public static func resolveMaxCount(_ amount: Int) -> Int {
        return amount == 1 ? 0 : amount
    }
    
    @inline(__always)
    public static func convert(value: ManagedObjectValue, proxyType: PropertyProxyType) -> RuntimeObjectValue {
        return Set(value.allObjects.compactMap{ EntityType.init($0 as! NSManagedObject, proxyType: proxyType) })
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue, proxyType: PropertyProxyType) -> ManagedObjectValue {
        return value as ManagedObjectValue
    }
}

@propertyWrapper
public final class Relationship<O: Nullability, I: RelationMapping, R: RelationMapping>: RelationshipProtocol {

    public typealias PredicateValue = Destination
    public typealias PropertyValue = R.RuntimeObjectValue
    public typealias InverseMapping = I
    public typealias Mapping = R
    public typealias Source = I.EntityType
    public typealias Destination = R.EntityType
    public typealias Nullability = O
    public typealias PropertyOption = RelationshipOption
    
    public weak var proxy: PropertyProxy! = nil
    
    public var wrappedValue: PropertyValue {
        get {
            let value: R.ManagedObjectValue = proxy!.getValue(property: self)
            return R.convert(value: value, proxyType: proxy.proxyType)
        }
        set {
            guard let proxy = proxy as? ReadWritePropertyProxy else {
                return assertionFailure("value should not be modified with read only value mapper")
            }
            
            proxy.setValue(Mapping.convert(value: newValue, proxyType: proxy.proxyType), property: self)
        }
    }

    dynamic public var projectedValue: Crush.Relationship<Nullability, InverseMapping, Mapping> {
        self
    }
            
    public var defaultName: String = ""
            
    public var inverseRelationship: String?
    
    public var inverseKeyPath: AnyKeyPath!
    
    public var configuration: PropertyConfiguration = []
    
    public var propertyCacheKey: String = ""
    
    public convenience init(wrappedValue: PropertyValue) {
        self.init()
    }
    
    public init() { }
    
    public init<R>(wrappedValue: PropertyValue? = nil, inverse: KeyPath<Destination, R>, options: PropertyConfiguration = [])
        where R: RelationshipProtocol, R.Destination == Source, R.Source == Destination, R.Mapping == InverseMapping, R.InverseMapping == Mapping {
        self.inverseKeyPath = inverse
        self.configuration = options
    }
    
    public init(wrappedValue: PropertyValue? = nil, options: PropertyConfiguration) {
        self.configuration = options
    }
    
    public func emptyPropertyDescription() -> NSPropertyDescription {
        let description = NSRelationshipDescription()
        
        configuration.configure(description: description)

        description.isOptional = O.isOptional
        description.isTransient = isTransient
        description.name = description.name.isEmpty ? defaultName : description.name
        description.userInfo = description.userInfo ?? [:]
        description.userInfo?[UserInfoKey.relationshipDestination] = Destination.entityCacheKey
        description.maxCount = Mapping.resolveMaxCount(description.maxCount)

        if let inverseKeyPath = inverseKeyPath {
            description.userInfo?[UserInfoKey.inverseRelationship] = inverseKeyPath
        }
        
        return description
    }
}
