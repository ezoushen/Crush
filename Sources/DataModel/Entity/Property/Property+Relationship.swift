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
    
    var configuration: PropertyConfiguration { get set }
    var inverseKeyPath: AnyKeyPath! { get set }
    
    init<R: RelationshipProtocol>(_ name: String, inverse: KeyPath<Destination, R>, options: PropertyConfiguration) where R.Destination == Source, R.Source == Destination, R.Mapping == InverseMapping, R.InverseMapping == Mapping
}

// MARK: - EntityRelationShipType
public protocol RelationMapping: FieldConvertible {
    associatedtype EntityType: HashableEntity
    
    static func resolveMaxCount(_ amount: Int) -> Int
    static func convert(value: RuntimeObjectValue, with: ManagedObjectValue) -> ManagedObjectValue
}

extension RelationMapping {
    static func getEnity(from value: NSManagedObject) -> EntityType {
        value as! EntityType
    }
}

public struct ToOne<EntityType: HashableEntity>: RelationMapping, FieldConvertible {
    public typealias RuntimeObjectValue = EntityType?
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
        return value?.rawObject
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue, with: ManagedObjectValue) -> ManagedObjectValue {
        return convert(value: value)
    }
}

public struct ToMany<EntityType: HashableEntity>: RelationMapping, FieldConvertible {
    public typealias RuntimeObjectValue = Set<EntityType>
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
    public static func convert(value: RuntimeObjectValue, with nsset: ManagedObjectValue) -> ManagedObjectValue {
        let mutableSet = nsset?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        mutableSet.removeAllObjects()
        mutableSet.union(Set(value.map{ $0.rawObject }))
        return mutableSet
    }
}

@propertyWrapper
public final class Relationship<O: Nullability, I: RelationMapping, R: RelationMapping>: RelationshipProtocol, ObservableProtocol where R.RuntimeObjectValue: Hashable {
    public typealias ObservableType = Mapping
    public typealias PredicateValue = Destination
    public typealias PropertyValue = R.RuntimeObjectValue
    public typealias InverseMapping = I
    public typealias Mapping = R
    public typealias Source = I.EntityType
    public typealias Destination = R.EntityType
    public typealias Nullability = O
    public typealias PropertyOption = RelationshipOption
        
    public var wrappedValue: PropertyValue {
        get { fatalError() }
        set { fatalError() }
    }
    
    public static subscript<EnclosingSelf: HashableEntity>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PropertyValue>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Relationship<O, I, R>>
    ) -> PropertyValue {
        get {
            let property = observed[keyPath: storageKeyPath]
            return R.convert(value: observed.getValue(key: property.name))
        }
        set {
            let property = observed[keyPath: storageKeyPath]
            observed.setValue(
                R.convert(value: newValue, with: observed.getValue(key: property.name)),
                key: property.name
            )
        }
    }

    public var projectedValue: Relationship<Nullability, InverseMapping, Mapping> {
        self
    }
                
    public var name: String = ""
                
    public var inverseKeyPath: AnyKeyPath!
    
    public var configuration: PropertyConfiguration = []
    
    public var propertyCacheKey: String = ""
    
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
