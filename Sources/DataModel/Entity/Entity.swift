//
//  Entity.swift
//  Crush
//
//  Created by ezou on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public enum EntityInheritance: Int {
    case singleTable = 0
    case multiTable = 1
}

public enum EntityAbstraction {
    case abstract(inheritance: EntityInheritance), concrete
}

extension EntityAbstraction {
    var isEntityDescriptionRequired: Bool {
        guard case .abstract(let inheritance) = self else {
            return true
        }
        return inheritance == .singleTable
    }
}

extension EntityAbstraction: Comparable, Hashable, Equatable {
    var order: Int {
        switch self {
        case .abstract(let inheritance):
            return inheritance.rawValue
        case .concrete:
            return 2
        }
    }

    public static func < (
        lhs: EntityAbstraction,
        rhs: EntityAbstraction) -> Bool
    {
        lhs.order < rhs.order
    }
}

private var ENTITY_DESC_KEY = 0

open class Entity {
    internal static var registeredEntities: Set<ObjectIdentifier> = []
    internal static var propertyNamesByEntity: [ObjectIdentifier: [String]] = [:]
    required public init() { }

    func typeIdentifier() -> ObjectIdentifier {
        ObjectIdentifier(type(of: self))
    }

    @objc open dynamic class func willSave(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func didSave(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func prepareForDeletion(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func willTurnIntoFault(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func didTurnIntoFault(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func awakeFromFetch(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func awakeFromInsert(_ managedObject: NSManagedObject) { }
    @objc open dynamic class func awake(_ managedObject: NSManagedObject,
                                        fromSnapshotEvents: NSSnapshotEventType) { }
    @objc open dynamic class func validateValue(
        _ managedObject: NSManagedObject,
        value: AutoreleasingUnsafeMutablePointer<AnyObject?>,
        forKey key: String) throws
    {
        try (managedObject as? ManagedObjectBase)?.originalValidateValue(value, forKey: key)
    }
    @objc open dynamic class func validateForDelete(_ managedObject: NSManagedObject) throws {
        try (managedObject as? ManagedObjectBase)?.originalValidateForDelete()
    }
    @objc open dynamic class func validateForInsert(_ managedObject: NSManagedObject) throws {
        try (managedObject as? ManagedObjectBase)?.originalValidateForInsert()
    }
    @objc open dynamic class func validateForUpdate(_ managedObject: NSManagedObject) throws {
        try (managedObject as? ManagedObjectBase)?.originalValidateForUpdate()
    }

    func createEntityDescription(
        abstractionData: [ObjectIdentifier: EntityAbstraction],
        cache: EntityCache
    ) -> NSEntityDescription? {
        let identifier = ObjectIdentifier(Self.self)
        let mirror = Mirror(reflecting: self)

        defer {
            Self.propertyNamesByEntity[ObjectIdentifier(Self.self)] = propertyNames(mirror: mirror)
        }

        /// If abstraction data no presented in dictionary, consider it as embedded entity
        let abstraction = abstractionData[identifier] ?? .abstract(inheritance: .multiTable)

        guard abstraction.isEntityDescriptionRequired else {
            return nil
        }

        // Setup properties
        let description = NSEntityDescription()
        let properties = createProperties(
            mirror: mirror,
            abstractionData: abstractionData,
            cache: cache)
        description.userInfo?[UserInfoKey.entityClassName] = NSStringFromClass(Self.self)
        description.name = Self.fetchKey
        description.isAbstract = abstraction != .concrete
        description.properties = properties
        description.managedObjectClassName = NSStringFromClass(ManagedObjectBase.self)

        objc_setAssociatedObject(Self.self, &ENTITY_DESC_KEY, description, .OBJC_ASSOCIATION_RETAIN)

        setupIndexes(description: description)
        setupUniquenessConstraints(description: description)

        if let superMirror = mirror.superclassMirror,
           let superType = superMirror.subjectType as? Entity.Type,
           let superAbstraction = abstractionData[ObjectIdentifier(superType)],
           superAbstraction != .abstract(inheritance: .multiTable)
        {
            cache.get(superType.entityCacheKey) {
                $0.subentities.append(description)
            }
        }

        cache.set(Self.entityCacheKey, value: description)
        Self.registeredEntities.insert(ObjectIdentifier(Self.self))

        return description
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
    public static func entity() -> NSEntityDescription {
        objc_getAssociatedObject(Self.self, &ENTITY_DESC_KEY) as! NSEntityDescription
    }
    
    @inlinable public static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        NSFetchRequest(entityName: entity().name!)
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

    private func propertyNames(mirror: Mirror) -> [String] {
        let names = mirror.children
            .compactMap { $0.value as? (any Property) }
            .map(\.name)
        if let superMirror = mirror.superclassMirror {
            return names + propertyNames(mirror: superMirror)
        }
        return names
    }
    
    private func createProperties(
        mirror: Mirror,
        abstractionData: [ObjectIdentifier: EntityAbstraction],
        cache: EntityCache
    ) -> [NSPropertyDescription] {
        let ownedProperties = mirror.children
            .compactMap { $0.value as? (any Property) }
            .map {
                if let entityCached = $0 as? EntityCachedProtocol {
                    entityCached.cache = cache
                }
                return $0.createPropertyDescription()
            }
        
        if let superMirror = mirror.superclassMirror {
            let abstraction = abstractionData[ObjectIdentifier(superMirror.subjectType)] ?? .abstract(inheritance: .multiTable)
            if abstraction == .abstract(inheritance: .multiTable) {
                return ownedProperties + createProperties(
                    mirror: superMirror, abstractionData: abstractionData, cache: cache)
            }
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
    public typealias Driver = ManagedDriver<Self>
    public typealias RawDriver = ManagedRawDriver<Self>
}
