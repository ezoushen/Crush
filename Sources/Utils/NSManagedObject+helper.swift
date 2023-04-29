//
//  NSManagedObject+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func load(objectID: NSManagedObjectID, isFault: Bool) -> NSManagedObject {
        guard isFault else { return object(with: objectID) }
        do {
            return try existingObject(with: objectID)
        } catch {
            return object(with: objectID)
        }
    }

    func receive<T: NSManagedObject>(runtimeObject: T) -> T {
        load(objectID: runtimeObject.objectID, isFault: runtimeObject.isFault) as! T
    }
}

extension NSManagedObject {
    func fireFaultIfNeeded() {
        guard isFault else { return }
        fireFault()
    }

    func fireFault() {
        let description = Self.entity()
        let key = description.allAttributeKeys().first ??
                    description.allToOneRelationshipKeys().first ??
                    description.allToManyRelationshipKeys().first!
        willAccessValue(forKey: key)
    }
}

extension NSEntityDescription {
    public func allAttributeKeys() -> [String] {
        Array(attributesByName.keys)
    }

    public func allToOneRelationshipKeys() -> [String] {
        relationshipsByName
            .filter { !$0.value.isToMany }
            .map { $0.key }
    }

    public func allToManyRelationshipKeys() -> [String] {
        relationshipsByName
            .filter { $0.value.isToMany }
            .map { $0.key }
    }
}
