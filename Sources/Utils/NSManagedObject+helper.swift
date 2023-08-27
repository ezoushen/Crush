//
//  NSManagedObject+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func load(objectID: NSManagedObjectID, isFault: Bool) -> NSManagedObject? {
        // Load from registered object first
        if let object = registeredObject(for: objectID) {
            return object
        }
        // Load from persistent store
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: objectID.entity.name!)
        request.predicate = NSPredicate(format: "SELF = %@", objectID)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = isFault
        request.resultType = isFault ? .managedObjectIDResultType : .managedObjectResultType

        let result = try! fetch(request).first

        if let id = result as? NSManagedObjectID {
            return object(with: id)
        } else if let object = result as? NSManagedObject {
            return object
        } else {
            return nil
        }
    }

    func receive<T: NSManagedObject>(runtimeObject: T) -> T {
        (load(objectID: runtimeObject.objectID, isFault: runtimeObject.isFault) ?? object(with: runtimeObject.objectID)) as! T
    }
}

extension NSManagedObject {
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

extension NSManagedObjectContext {
    func getRootStoreCoordinator() -> NSPersistentStoreCoordinator? {
        if let coordinator = persistentStoreCoordinator {
            return coordinator
        }
        return parent?.getRootStoreCoordinator()
    }
}
