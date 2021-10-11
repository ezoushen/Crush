//
//  RuntimeObject.swift
//  Crush
//
//  Created by ezou on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public enum EntityInheritance: Int, Comparable {
    public static func < (
        lhs: EntityInheritance,
        rhs: EntityInheritance
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case abstract
    case embedded
    case concrete
}

typealias EntityInheritanceMeta = [ObjectIdentifier: EntityInheritance]

public protocol Entity: AnyObject, Field {
    static var renamingIdentifier: String? { get }
    static var entityCacheKey: String { get }

    init()
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
    
    public static var renamingClass: Entity.Type? {
        return nil
    }

    public static var renamingIdentifier: String? {
        renamingClass?.fetchKey
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
        
        let coordinator = CacheCoordinator.shared
        let object = Self.init()
        let mirror = Mirror(reflecting: object)
        
        // Setup properties
        let description = NSEntityDescription()
        description.managedObjectClassName = NSStringFromClass(ManagedObject.self)
        description.name = fetchKey
        description.properties = object.createProperties(mirror: mirror, meta: meta)
        description.isAbstract = inheritance == .abstract
        description.renamingIdentifier = renamingIdentifier
        
        if let superMirror = mirror.superclassMirror,
           let superType = superMirror.subjectType as? Entity.Type,
           meta[ObjectIdentifier(superType)] != .embedded
        {
            coordinator.getAndWait(superType.entityCacheKey, in: CacheType.entity) {
                $0.subentities.append(description)
            }
        }
        
        coordinator.set(entityCacheKey, value: description, in: CacheType.entity)
        
        return description
    }

    static func entityDescription() -> NSEntityDescription {
        ManagedObject.entity()
    }
}
