//
//  Entity.swift
//  Crush
//
//  Created by ezou on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public enum EntityInheritance: Int {
    case abstract, embedded, concrete
}

extension EntityInheritance: Comparable, Hashable {
    public static func < (
        lhs: EntityInheritance,
        rhs: EntityInheritance) -> Bool
    {
        lhs.rawValue < rhs.rawValue
    }
}

open class Entity {
    internal static var registeredEntities: Set<ObjectIdentifier> = []
    internal static var propertyNamesByEntity: [ObjectIdentifier: [String]] = [:]
    required public init() { }
    @objc open dynamic class func willSave(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func didSave(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func prepareForDeletion(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func willTurnIntoFault(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func didTurnIntoFault(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func awakeFromFetch(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func awakeFromInsert(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func awake(_ managedObject: NSManagedObject,
                                        fromSnapshotEvents: NSSnapshotEventType) { }
    @objc open dynamic class func validateForDelete(_ managedObject: NSManagedObject) throws {
        try (managedObject as? ManagedObjectBase)?.originalValidateForDelete()
    }
    @objc open dynamic class func validateForInsert(_ managedObject: NSManagedObject) throws {
        try (managedObject as? ManagedObjectBase)?.originalValidateForInsert()
    }
    @objc open dynamic class func validateForUpdate(_ managedObject: NSManagedObject) throws {
        try (managedObject as? ManagedObjectBase)?.originalValidateForUpdate()
    }
}

extension Entity: Hashable {
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(Self.self))
    }
}

extension Entity {
    @inlinable public static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        Self.Managed.fetchRequest()
    }
    
    @inlinable public static func entity() -> NSEntityDescription {
        Self.Managed.entity()
    }

    @inlinable public static var fetchKey: String {
        name
    }
    
    @inlinable public static var name: String {
        String(describing: Self.self)
    }

    static var entityCacheKey: String {
        String(reflecting: Self.self)
    }

    static func isRegistered() -> Bool {
        Self.registeredEntities.contains(ObjectIdentifier(Self.self))
    }

    static func propertyNames() -> [String]? {
        Self.propertyNamesByEntity[ObjectIdentifier(Self.self)]
    }
    
    func createEntityDescription(
        inhertanceData: [ObjectIdentifier: EntityInheritance]
    ) -> NSEntityDescription? {
        let identifier = ObjectIdentifier(Self.self)
        let mirror = Mirror(reflecting: self)

        defer {
            Self.propertyNamesByEntity[ObjectIdentifier(Self.self)] = propertyNames(mirror: mirror)
        }

        guard let inheritance = inhertanceData[identifier],
              inheritance != .embedded else {
            return nil
        }

        let cache = Caches.entity
        
        // Setup properties
        let description = NSEntityDescription()
        let properties = createProperties(
            mirror: mirror,
            inhertanceData: inhertanceData)

        description.userInfo?[UserInfoKey.entityClassName] = Self.entityCacheKey
        description.managedObjectClassName = NSStringFromClass(ManagedObject<Self>.self)
        description.name = Self.fetchKey
        description.isAbstract = inheritance == .abstract
        description.properties = properties
        
        setupIndexes(description: description)
        setupUniquenessConstraints(description: description)

        if let superMirror = mirror.superclassMirror,
           let superType = superMirror.subjectType as? Entity.Type,
           inhertanceData[ObjectIdentifier(superType)] != .embedded
        {
            cache.getAndWait(superType.entityCacheKey) {
                $0.subentities.append(description)
            }
        }

        cache.set(Self.entityCacheKey, value: description)
        Self.registeredEntities.insert(ObjectIdentifier(Self.self))
        
        return description
    }

    private func propertyNames(mirror: Mirror) -> [String] {
        let names = mirror.children
            .compactMap { $0.value as? PropertyProtocol }
            .map(\.name)
        if let superMirror = mirror.superclassMirror {
            return names + propertyNames(mirror: superMirror)
        }
        return names
    }
    
    private func createProperties(
        mirror: Mirror,
        inhertanceData: [ObjectIdentifier: EntityInheritance]
    ) -> [NSPropertyDescription] {
        let ownedProperties = mirror.children
            .compactMap { $0.value as? PropertyProtocol }
            .map { $0.createPropertyDescription() }
        
        if let superMirror = mirror.superclassMirror,
           let inheritance = inhertanceData[ObjectIdentifier(superMirror.subjectType)],
           inheritance == .embedded
        {
            return ownedProperties + createProperties(
                mirror: superMirror, inhertanceData: inhertanceData)
        }
        
        return ownedProperties
    }

    private func setupIndexes(description: NSEntityDescription) {
        var indexesByName: [String: [NSFetchIndexElementDescription]] = [:]
        var indexPredicatesByName: [String: NSPredicate] = [:]

        for property in description.properties {
            guard let indexProtocols = property.userInfo?[UserInfoKey.indexes]
                    as? [IndexProtocol] else { continue }

            property.userInfo?[UserInfoKey.indexes] = nil

            for index in indexProtocols {
                guard index.targetEntityName == nil ||
                        index.targetEntityName == Self.fetchKey else { continue }
                let indexName = index.indexName ?? property.name
                let indexPredicate = index.predicate

                var indexes = indexesByName[indexName] ?? []
                let element = index
                    .createFetchIndexElementDescription(from: property)
                indexes.append(element)
                indexesByName[indexName] = indexes

                guard let indexPredicate = indexPredicate else { continue }

                if let predicate = indexPredicatesByName[indexName] {
                    indexPredicatesByName[indexName] = NSCompoundPredicate(
                        orPredicateWithSubpredicates: [indexPredicate, predicate])
                } else {
                    indexPredicatesByName[indexName] = indexPredicate
                }
            }
        }

        description.indexes = indexesByName.map { (name, elements) in
            let index = NSFetchIndexDescription(name: name, elements: elements)
            index.partialIndexPredicate = indexPredicatesByName[name]
            return index
        }
    }

    private func setupUniquenessConstraints(description: NSEntityDescription) {
        let key = UserInfoKey.uniquenessConstraintName
        var uniquenessConstraintsByName: [String: [String]] = [:]

        for property in description.properties {
            guard let name = property.userInfo?[key] as? String else { continue }
            var constraints = uniquenessConstraintsByName[name] ?? []
            constraints.append(property.name)
            uniquenessConstraintsByName[name] = constraints
            property.userInfo?[UserInfoKey.uniquenessConstraintName] = nil
        }

        description.uniquenessConstraints = Array(uniquenessConstraintsByName.values)
    }
}

public protocol ManagableObject { }

extension Entity: ManagableObject { }

extension ManagableObject where Self: Entity {
    public typealias Managed = ManagedObject<Self>
    public typealias Driver = ManagedDriver<Self>
}
