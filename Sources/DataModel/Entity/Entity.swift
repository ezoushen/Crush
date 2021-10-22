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
    public static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        Self.Managed.fetchRequest()
    }
    
    public static func entity() -> NSEntityDescription {
        Self.Managed.entity()
    }

    public static var fetchKey: String {
        String(describing: Self.self)
    }

    static var entityCacheKey: String {
        String(reflecting: Self.self)
    }
    
    func createEntityDescription(
        inhertanceData: [ObjectIdentifier: EntityInheritance]
    ) -> NSEntityDescription? {
        let identifier = ObjectIdentifier(Self.self)

        guard let inheritance = inhertanceData[identifier],
              inheritance != .embedded else {
            return nil
        }
        
        let cache = Caches.entity
        let mirror = Mirror(reflecting: self)
        
        // Setup properties
        let description = NSEntityDescription()
        let properties = createProperties(
            mirror: mirror,
            inhertanceData: inhertanceData)

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
        
        return description
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
            guard let element = property.userInfo?[UserInfoKey.index]
                    as? NSFetchIndexElementDescription else { continue }
            let indexName = property.userInfo?[UserInfoKey.indexName] as? String ?? property.name
            let indexPredicate = property.userInfo?[UserInfoKey.indexPredicate] as? NSPredicate

            defer {
                property.userInfo?[UserInfoKey.index] = nil
                property.userInfo?[UserInfoKey.indexName] = nil
                property.userInfo?[UserInfoKey.indexPredicate] = nil
            }

            var indexes = indexesByName[indexName] ?? []
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
}
