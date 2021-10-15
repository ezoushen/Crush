//
//  Entity.swift
//  Crush
//
//  Created by ezou on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public struct EntityDescription: Hashable {

    public let type: Entity.Type
    public let inheritance: EntityInheritance

    public static func == (
        lhs: EntityDescription, rhs: EntityDescription) -> Bool
    {
        lhs.hashValue == rhs.hashValue
    }

    public init(type: Entity.Type, inheritance: EntityInheritance) {
        self.type = type
        self.inheritance = inheritance
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type))
        hasher.combine(inheritance)
    }
}

public enum EntityInheritance: Int, Comparable, Hashable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
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
    
    static func createPropertyCacheKey(domain: String = entityCacheKey, name: String) -> String {
        "\(domain).\(name)"
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
        meta: EntityInheritanceMeta
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
        
        cache.set(entityCacheKey, value: description)
        
        return description
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
