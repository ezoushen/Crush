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

public protocol RelationshipProtocol: NullableProperty where PropertyValue: Equatable {
    associatedtype Destination: Entity
    associatedtype Source: Entity
    associatedtype Mapping: RelationMapping
    associatedtype InverseMapping: RelationMapping
    
    var configuration: PropertyConfiguration { get set }
    var inverseKeyPath: AnyKeyPath! { get set }
    
    init<R: RelationshipProtocol>(wrappedValue: PropertyValue?, inverse: KeyPath<Destination, R>, options: PropertyConfiguration) where R.Destination == Source, R.Source == Destination, R.Mapping == InverseMapping, R.InverseMapping == Mapping
}

// MARK: - EntityRelationShipType
public protocol RelationMapping: FieldConvertible where RuntimeObjectValue: Equatable {
    associatedtype EntityType: HashableEntity
    
    static func resolveMaxCount(_ amount: Int) -> Int
}

extension RelationMapping {
    static func getEnity(from value: ManagedObject, proxyType: PropertyProxyType) -> EntityType {
        EntityType.init(value, proxyType: proxyType)
    }
}

public struct ToOne<EntityType: HashableEntity>: RelationMapping, FieldConvertible {
    public typealias RuntimeObjectValue = EntityType?
    public typealias ManagedObjectValue = ManagedObject?
    
    public static func resolveMaxCount(_ amount: Int) -> Int {
        return 1
    }
    
    @inline(__always)
    public static func convert(value: ManagedObjectValue, proxyType: PropertyProxyType) -> RuntimeObjectValue {
        guard let value = value else { return nil }
        return getEnity(from: value, proxyType: proxyType)
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue, proxyType: PropertyProxyType) -> ManagedObjectValue {
        return value?.rawObject as? ManagedObject
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
        return Set(value.allObjects.compactMap{ getEnity(from: $0 as! ManagedObject, proxyType: proxyType) })
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
            let value: R.ManagedObjectValue = proxy!.getValue(key: description.name)
            return R.convert(value: value, proxyType: proxy.proxyType)
        }
        set {
            guard let proxy = proxy as? ReadWritePropertyProxy else {
                return assertionFailure("value should not be modified with read only value mapper")
            }
            #if canImport(Combine)
            let oldValue: PropertyValue = wrappedValue
            defer {
                if #available(iOS 13.0, watchOS 6.0, macOS 10.15, *), oldValue != newValue {
                    objectWillChange.send()
                    entityObject?.objectWillChange.send()
                }
            }
            #endif
            proxy.setValue(Mapping.convert(value: newValue, proxyType: proxy.proxyType), key: description.name)
        }
    }

    dynamic public var projectedValue: Crush.Relationship<Nullability, InverseMapping, Mapping> {
        self
    }
            
    public weak var entityObject: NeutralEntityObject?
    
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
