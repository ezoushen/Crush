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

extension RelationshipOption: MutablePropertyOptionProtocol {
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

public protocol RelationshipProtocol: NullablePropertyProtocol {
    associatedtype DestinationEntity: Entity
    associatedtype SourceEntity: Entity
    associatedtype RelationshipType: RelationshipTypeProtocol
    associatedtype InverseType: RelationshipTypeProtocol
    
    var inverseKeyPath: Any! { get set }
    
    init<R: RelationshipProtocol>(wrappedValue: PropertyValue?, inverse: KeyPath<DestinationEntity, R>, options: [PropertyOptionProtocol]) where R.DestinationEntity == SourceEntity, R.SourceEntity == DestinationEntity, R.RelationshipType == InverseType, R.InverseType == RelationshipType
}

public extension RelationshipProtocol {
    init<R: RelationshipProtocol>(wrappedValue: PropertyValue?, inverse: KeyPath<DestinationEntity, R>, options: PropertyOptionProtocol...) where R.DestinationEntity == SourceEntity, R.SourceEntity == DestinationEntity, R.RelationshipType == InverseType, R.InverseType == RelationshipType {
        self.init(wrappedValue: wrappedValue, inverse: inverse, options: options)
    }
}

// MARK: - EntityRelationShipType

public protocol FieldTypeProtocol {
    associatedtype RuntimeObjectValue
    associatedtype ManagedObjectValue
    
    static func convert(value: ManagedObjectValue, proxyType: PropertyProxyType) -> RuntimeObjectValue
    static func convert(value: RuntimeObjectValue, proxyType: PropertyProxyType) -> ManagedObjectValue
}

public protocol RelationshipTypeProtocol: FieldTypeProtocol {
    associatedtype EntityType: Entity
        
    static func resolveMaxCount(_ amount: Int) -> Int
}

public struct ToOneRelationshipType<EntityType: Entity>: RelationshipTypeProtocol, FieldTypeProtocol {
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

public struct ToManyRelationshipType<EntityType: Hashable & Entity>: RelationshipTypeProtocol, FieldTypeProtocol {
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
public final class Relationship<O: OptionalTypeProtocol, I: RelationshipTypeProtocol, R: RelationshipTypeProtocol>: RelationshipProtocol {

    public typealias PredicateValue = DestinationEntity
    public typealias PropertyValue = R.RuntimeObjectValue
    public typealias InverseType = I
    public typealias RelationshipType = R
    public typealias SourceEntity = I.EntityType
    public typealias DestinationEntity = R.EntityType
    public typealias OptionalType = O
    public typealias Option = RelationshipOption
    
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
            
            proxy.setValue(RelationshipType.convert(value: newValue, proxyType: proxy.proxyType), property: self)
        }
    }

    dynamic public var projectedValue: Relationship<OptionalType, InverseType, RelationshipType> {
        self
    }
            
    public var defaultName: String = ""
            
    public var inverseRelationship: String?
    
    public var inverseKeyPath: Any!
    
    public var options: [PropertyOptionProtocol] = []
    
    public var propertyCacheKey: String = ""
    
    public convenience init(wrappedValue: PropertyValue) {
        self.init()
    }
    
    public init() { }
    
    public init<R>(wrappedValue: PropertyValue? = nil, inverse: KeyPath<DestinationEntity, R>, options: [PropertyOptionProtocol] = [])
        where R: RelationshipProtocol, R.DestinationEntity == SourceEntity, R.SourceEntity == DestinationEntity, R.RelationshipType == InverseType, R.InverseType == RelationshipType {
        self.inverseKeyPath = inverse
        self.options = options
    }
    
    public init(wrappedValue: PropertyValue? = nil, options: [PropertyOptionProtocol]) {
        self.options = options
    }
    
    public func emptyPropertyDescription() -> NSPropertyDescription {
        let description = NSRelationshipDescription()
        
        options.forEach{ $0.updatePropertyDescription(description) }

        description.isOptional = O.isOptional
        description.isTransient = isTransient
        description.name = description.name.isEmpty ? defaultName : description.name
        description.maxCount = RelationshipType.resolveMaxCount(description.maxCount)
        description.userInfo = description.userInfo ?? [:]
        description.userInfo?[UserInfoKey.relationshipDestination] = DestinationEntity.entityCacheKey
        
        if let inverseKeyPath = inverseKeyPath {
            description.userInfo?[UserInfoKey.inverseRelationship] = inverseKeyPath
        }
        
        return description
    }
}
