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
    var maxCount: Int { get }
    var minCount: Int { get }
    var deleteRule: NSDeleteRule { get }
    var isOrdered: Bool { get }
    
    init<R: RelationshipProtocol>(_ name: String?, inverse: KeyPath<DestinationEntity, R>, options: [PropertyOptionProtocol]) where R.DestinationEntity == SourceEntity, R.SourceEntity == DestinationEntity, R.RelationshipType == InverseType, R.InverseType == RelationshipType
}

public extension RelationshipProtocol {
    
    var maxCount: Int { 1 }
    var minCount: Int { 0 }
    var deleteRule: NSDeleteRule { .nullifyDeleteRule }
    var isOrdered: Bool { false }
    
    func createDescription<T: NSPropertyDescription>() -> T! {
        let description = NSRelationshipDescription()
        
        description.isOptional = isOptional
        description.isTransient = isTransient
        description.userInfo = userInfo
        description.isIndexedBySpotlight = isIndexedBySpotlight
        description.versionHashModifier = versionHashModifier
        description.renamingIdentifier = renamingIdentifier
        description.setValidationPredicates(validationPredicates, withValidationWarnings: validationWarnings)
        
        description.maxCount = maxCount
        description.minCount = minCount
        description.deleteRule = deleteRule
        description.isOrdered = isOrdered
        description.userInfo?[UserInfoKey.relationshipDestination] = DestinationEntity.entityCacheKey
        
        if let inverseKeyPath = inverseKeyPath {
            description.userInfo?[UserInfoKey.inverseRelationship] = inverseKeyPath
        }
        
        return description as? T
    }
    
    init<R: RelationshipProtocol>(_ name: String?, inverse: KeyPath<DestinationEntity, R>, options: PropertyOptionProtocol...) where R.DestinationEntity == SourceEntity, R.SourceEntity == DestinationEntity, R.RelationshipType == InverseType, R.InverseType == RelationshipType {
        self.init(name, inverse: inverse, options: options)
    }
}

// MARK: - EntityRelationShipType

public protocol FieldTypeProtocol {
    associatedtype RuntimeObjectValue
    associatedtype ManagedObjectValue
    
    static func convert(value: ManagedObjectValue) -> RuntimeObjectValue
    static func convert(value: RuntimeObjectValue) -> ManagedObjectValue
}

public protocol RelationshipTypeProtocol: FieldTypeProtocol {
    associatedtype EntityType: Entity
        
    static func resolveMaxCount(_ amount: Int) -> Int
}

public struct ToOneRelationshipType<EntityType: Entity>: RelationshipTypeProtocol, FieldTypeProtocol {
    public typealias RuntimeObjectValue = EntityType
    public typealias ManagedObjectValue = NSManagedObject
    
    public static func resolveMaxCount(_ amount: Int) -> Int {
        return 1
    }
    
    @inline(__always)
    public static func convert(value: ManagedObjectValue) -> RuntimeObjectValue {
        return RuntimeObjectValue.create(value)
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue) -> ManagedObjectValue {
        return value.rawObject
    }
}

public struct ToManyRelationshipType<EntityType: Hashable & Entity>: RelationshipTypeProtocol, FieldTypeProtocol {
    public typealias RuntimeObjectValue = Set<EntityType>
    public typealias ManagedObjectValue = NSSet
    
    public static func resolveMaxCount(_ amount: Int) -> Int {
        return amount == 1 ? 0 : amount
    }
    
    @inline(__always)
    public static func convert(value: ManagedObjectValue) -> RuntimeObjectValue {
        return Set(value.allObjects.compactMap{ EntityType.create($0 as! NSManagedObject) })
    }
    
    @inline(__always)
    public static func convert(value: RuntimeObjectValue) -> ManagedObjectValue {
        return value as ManagedObjectValue
    }
}

@propertyWrapper
public final class Relationship<O: OptionalTypeProtocol, I: RelationshipTypeProtocol>: RelationshipProtocol where O.FieldType: RelationshipTypeProtocol {
    
    public typealias PropertyValue = OptionalType.PropertyValue
    public typealias InverseType = I
    public typealias RelationshipType = O.FieldType
    public typealias SourceEntity = I.EntityType
    public typealias DestinationEntity = RelationshipType.EntityType
    public typealias OptionalType = O
    public typealias Option = RelationshipOption
    public typealias EntityType = RelationshipType.EntityType
    
    public var valueMappingProxy: ReadOnlyValueMapperProtocol? = nil
    
    public var wrappedValue: PropertyValue {
        get {
            let value: RelationshipType.ManagedObjectValue! = valueMappingProxy?.getValue(property: self)
            return RelationshipType.convert(value: value) as! O.PropertyValue
        }
        set {
            guard let proxy = valueMappingProxy as? ReadWriteValueMapperProtocol else {
                return assertionFailure("value should not be modified with read only value mapper")
            }
            
            guard let value = newValue as? RelationshipType.RuntimeObjectValue else {
                return assertionFailure("raw object type mismatch")
            }
            
            proxy.setValue(RelationshipType.convert(value: value), property: self)
        }
    }

    dynamic public var projectedValue: Relationship<OptionalType, InverseType> {
        self
    }
    
    public var userInfo: [AnyHashable : Any]? = [:]
    
    public var name: String?
    
    public var renamingIdentifier: String?
    
    public var versionHashModifier: String?
    
    public lazy var description: NSPropertyDescription! = {
        return self.createDescription()
    }()
    
    public var inverseRelationship: String?
    
    public var inverseKeyPath: Any!
    
    public convenience init(wrappedValue: O.PropertyValue) {
        self.init()
    }
    
    public init() {
        updateProperty()
    }
    
    public init<R: RelationshipProtocol>(_ name: String? = nil, inverse: KeyPath<DestinationEntity, R>, options: [PropertyOptionProtocol] = []) where R.DestinationEntity == SourceEntity, R.SourceEntity == DestinationEntity, R.RelationshipType == InverseType, R.InverseType == RelationshipType {
        self.inverseKeyPath = inverse
        self.name = name
        self.updateProperty()
        options.forEach{ $0.updatePropertyDescription(description) }
    }
    
    
    public func updateProperty() {
        guard let description = description as? NSRelationshipDescription else { return }
        description.name = name ?? description.name
        description.renamingIdentifier = renamingIdentifier
        description.versionHashModifier = versionHashModifier
        description.maxCount = RelationshipType.resolveMaxCount(description.maxCount)
        description.isOptional = OptionalType.isOptional
        
        if let inverseKeyPath = inverseKeyPath {
            description.userInfo?[UserInfoKey.inverseRelationship] = inverseKeyPath
        }
    }
}
