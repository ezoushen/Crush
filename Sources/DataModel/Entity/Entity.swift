//
//  Entity.swift
//  Crush
//
//  Created by ezou on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public class AnyEntityDescription: Hashable {
    public let type: Entity.Type
    public let inheritance: EntityInheritance
    public let indexes: [IndexProtocol]
    public let uniqueConstraints: [UniqueConstraintProtocol]
    public let validations: [ValidationProtocol]

    public static func == (
        lhs: AnyEntityDescription, rhs: AnyEntityDescription) -> Bool
    {
        lhs.hashValue == rhs.hashValue
    }

    init<T: Entity>(
        _ type: T.Type,
        inheritance: EntityInheritance,
        indexes: Set<Index<T>> = [],
        uniqueConstraints: Set<UniqueConstraint<T>> = [],
        validations: Set<Validation<T>> = [])
    {
        self.type = type
        self.inheritance = inheritance
        self.indexes = Array(indexes)
        self.uniqueConstraints = Array(uniqueConstraints)
        self.validations = Array(validations)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type))
        hasher.combine(inheritance)
    }
}

public class EntityDescription<T: Entity>: AnyEntityDescription {
    public init(
        inheritance: EntityInheritance,
        indexes: Set<Index<T>> = [],
        uniqueConstraints: Set<UniqueConstraint<T>> = [],
        validations: Set<Validation<T>> = [])
    {
        super.init(T.self, inheritance: inheritance, indexes: indexes, uniqueConstraints: uniqueConstraints, validations: validations)
    }
    
    public convenience init(
        _ inheritance: EntityInheritance,
        @CollectionBuilder<Index<T>>
        indexes: () -> Set<Index<T>> = { [] },
        @CollectionBuilder<UniqueConstraint<T>>
        uniqueConstraints: () -> Set<UniqueConstraint<T>> = { [] },
        @CollectionBuilder<Validation<T>>
        validations: () -> Set<Validation<T>> = { [] })
    {
        self.init(
            inheritance: inheritance,
            indexes: indexes(),
            uniqueConstraints: uniqueConstraints(),
            validations: validations())
    }
}

public enum EntityInheritance: Int, Comparable, Hashable {
    public static func < (
        lhs: EntityInheritance,
        rhs: EntityInheritance) -> Bool
    {
        lhs.rawValue < rhs.rawValue
    }

    case abstract
    case embedded
    case concrete
}

typealias EntityInheritanceMeta = [ObjectIdentifier: EntityInheritance]

open class Entity: Field {
    required public init() { }
}

extension Entity {
    public static var entityCacheKey: String {
        String(reflecting: Self.self)
    }
    
    static var fetchKey: String {
        String(describing: Self.self)
    }
        
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        NSFetchRequest<NSFetchRequestResult>(entityName: fetchKey)
    }

    func createProperties(
        mirror: Mirror,
        meta: EntityInheritanceMeta
    ) -> [NSPropertyDescription] {
        let ownedProperties = mirror.children
            .compactMap { $0.value as? PropertyProtocol }
            .map { $0.createPropertyDescription() }
        
        if let superMirror = mirror.superclassMirror,
           meta[ObjectIdentifier(superMirror.subjectType)] == .embedded
        {
            return ownedProperties + createProperties(mirror: superMirror, meta: meta)
        }
        
        return ownedProperties
    }
    
    static func createEntityDescription(
        meta: EntityInheritanceMeta,
        indexes: [IndexProtocol] = [],
        uniqueConstraints: [UniqueConstraintProtocol] = [],
        validations: [ValidationProtocol] = []
    ) -> NSEntityDescription? {
        guard let inheritance = meta[ObjectIdentifier(Self.self)],
              inheritance != .embedded else {
            return nil
        }
        
        let cache = Caches.entity
        let object = Self.init()
        let mirror = Mirror(reflecting: object)
        
        // Setup properties
        let description = NSEntityDescription()
        description.managedObjectClassName = NSStringFromClass(ManagedObject<Self>.self)
        description.name = fetchKey
        description.properties = object.createProperties(mirror: mirror, meta: meta)
        description.isAbstract = inheritance == .abstract

        if let superMirror = mirror.superclassMirror,
           let superType = superMirror.subjectType as? Entity.Type,
           meta[ObjectIdentifier(superType)] != .embedded
        {
            cache.getAndWait(superType.entityCacheKey) {
                $0.subentities.append(description)
            }
        }
        
        description.indexes = indexes
            .map { $0.createIndexDescription(for: description) }
        description.uniquenessConstraints = uniqueConstraints
            .map { $0.uniquenessConstarints }
        
        setupValidations(validations, in: description)
        
        cache.set(entityCacheKey, value: description)
        
        return description
    }
    
    private static func setupValidations(
        _ validations: [ValidationProtocol],
        in description: NSEntityDescription)
    {
        let propertiesByName = description.propertiesByName
        
        var predicatesByName: [String: [NSPredicate]] = [:]
        var warningsByName: [String: [String]] = [:]
        
        for validation in validations {
            let name = validation.propertyName
            var predicates = predicatesByName[name] ?? []
            var warnings = warningsByName[name] ?? []
            
            predicates.append(validation.predicate)
            warnings.append(validation.warning)
            
            predicatesByName[name] = predicates
            warningsByName[name] = warnings
        }
        
        for name in predicatesByName.keys {
            guard let property = propertiesByName[name]
            else { continue }
            property.setValidationPredicates(
                predicatesByName[name],
                withValidationWarnings: warningsByName[name])
        }
    }
    
    static func entityDescription() -> NSEntityDescription {
        ManagedObject<Self>.entity()
    }
}

public protocol ManagableObject { }

extension Entity: ManagableObject { }

extension ManagableObject where Self: Entity {
    public typealias Managed = ManagedObject<Self>
}
