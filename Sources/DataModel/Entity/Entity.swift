//
//  Entity.swift
//  Crush
//
//  Created by ezou on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public enum EntityInheritance: Int, Comparable, Hashable {
    case abstract, embedded, concrete
}

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

extension EntityInheritance {
    public static func < (
        lhs: EntityInheritance,
        rhs: EntityInheritance) -> Bool
    {
        lhs.rawValue < rhs.rawValue
    }
}

open class Entity: Field {
    required public init() { }
}

extension Entity {
    public static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        NSFetchRequest<NSFetchRequestResult>(entityName: fetchKey)
    }
    
    public static func entityDescription() -> NSEntityDescription {
        ManagedObject<Self>.entity()
    }
    
    public static var entityCacheKey: String {
        String(reflecting: Self.self)
    }
    
    static var fetchKey: String {
        String(describing: Self.self)
    }
    
    static func createEntityDescription(
        entityDescriptionsByType: [ObjectIdentifier: AnyEntityDescription]
    ) -> NSEntityDescription? {
        let identifier = ObjectIdentifier(Self.self)
        let entityDescription = entityDescriptionsByType[identifier]
        
        guard let entityDescription = entityDescription,
              entityDescription.inheritance != .embedded else {
            return nil
        }
        
        let inheritance = entityDescription.inheritance
        let cache = Caches.entity
        let mirror = Mirror(reflecting: Self.init())
        
        // Setup properties
        let description = NSEntityDescription()
        description.managedObjectClassName = NSStringFromClass(ManagedObject<Self>.self)
        description.name = fetchKey
        description.isAbstract = inheritance == .abstract
        description.properties = createProperties(
            mirror: mirror,
            entityDescriptionsByType: entityDescriptionsByType)

        if let superMirror = mirror.superclassMirror,
           let superType = superMirror.subjectType as? Entity.Type,
           entityDescriptionsByType[ObjectIdentifier(superType)]?.inheritance != .embedded
        {
            cache.getAndWait(superType.entityCacheKey) {
                $0.subentities.append(description)
            }
        }
        
        let allIndexes = findAll(
            keyPath: \.indexes,
            mirror: mirror,
            entityDescription: entityDescription,
            entityDescriptionsByType: entityDescriptionsByType)
        let allUniqueConstraints = findAll(
            keyPath: \.uniqueConstraints,
            mirror: mirror,
            entityDescription: entityDescription,
            entityDescriptionsByType: entityDescriptionsByType)
        let allValidations = findAll(
            keyPath: \.validations,
            mirror: mirror,
            entityDescription: entityDescription,
            entityDescriptionsByType: entityDescriptionsByType)
        
        setupIndexes(allIndexes, in: description)
        setupUniqueConstraints(allUniqueConstraints, in: description)
        setupValidations(allValidations, in: description)
        
        cache.set(entityCacheKey, value: description)
        
        return description
    }
    
    private static func createProperties(
        mirror: Mirror,
        entityDescriptionsByType: [ObjectIdentifier: AnyEntityDescription]
    ) -> [NSPropertyDescription] {
        let ownedProperties = mirror.children
            .compactMap { $0.value as? PropertyProtocol }
            .map { $0.createPropertyDescription() }
        
        if let superMirror = mirror.superclassMirror,
           entityDescriptionsByType[ObjectIdentifier(superMirror.subjectType)]?.inheritance == .embedded
        {
            return ownedProperties + createProperties(mirror: superMirror, entityDescriptionsByType: entityDescriptionsByType)
        }
        
        return ownedProperties
    }
    
    private static func findAll<T>(
        keyPath: KeyPath<AnyEntityDescription, [T]>,
        mirror: Mirror,
        entityDescription: AnyEntityDescription,
        entityDescriptionsByType: [ObjectIdentifier: AnyEntityDescription]) -> [T]
    {
        guard mirror.subjectType == self ||
              entityDescription.inheritance == .embedded
        else { return [] }
        
        let array = entityDescription[keyPath: keyPath]
        guard let superMirror = mirror.superclassMirror,
              let superDescription =
                entityDescriptionsByType[ObjectIdentifier(superMirror.subjectType)]
        else { return array }
        
        return array +
            findAll(
                keyPath: keyPath,
                mirror: superMirror,
                entityDescription: superDescription,
                entityDescriptionsByType: entityDescriptionsByType)
    }
    
    private static func setupIndexes(
        _ indexes: [IndexProtocol],
        in description: NSEntityDescription)
    {
        description.indexes = indexes
            .map { $0.createIndexDescription(for: description) }
    }
    
    private static func setupUniqueConstraints(
        _ constraints: [UniqueConstraintProtocol],
        in description: NSEntityDescription)
    {
        description.uniquenessConstraints = constraints
            .map { $0.uniquenessConstarints }
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
}

public protocol ManagableObject { }

extension Entity: ManagableObject { }

extension ManagableObject where Self: Entity {
    public typealias Managed = ManagedObject<Self>
}
