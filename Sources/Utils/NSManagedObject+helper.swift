//
//  NSManagedObject+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func receive<T: RuntimeObject>(runtimeObject: T) -> NSManagedObject {
        let object = self.object(with: runtimeObject.rawObject.objectID)
        if !runtimeObject.rawObject.isFault,
            let name = object.entity.attributesByName.keys.first {
            object.willAccessValue(forKey: name)
            defer {
                object.didAccessValue(forKey: name)
            }
            _ = object.value(forKey: name)
        }
        return object
    }
}

// MARK: - Value getter

extension NSManagedObject {
    class var entityName: String {
        return entity().name ?? String(reflecting: self)
    }
}

// MARK: - Clone self

protocol NSManagedObjectCloner: NSManagedObject { }

extension NSManagedObject: NSManagedObjectCloner { }

extension NSManagedObjectCloner {
    func cloned(in context: NSManagedObjectContext) -> Self {
        let cloned = Self.init(entity: Self.entity(), insertInto: context)
        
        // Copy attributes
        self.entity.attributesByName.keys.forEach {
            let value = self.value(forKey: $0)
            cloned.setValue(value, forKey: $0)
        }
        
        //Loop through all relationships, and clone them.
        let relationships = NSEntityDescription.entity(forEntityName: Self.entity().name ?? "",
                                                       in: context)?.relationshipsByName
        
        func mappingRelationships(_ name: String, _ description: NSRelationshipDescription) {
            if description.isToMany {
                let sourceSet = mutableSetValue(forKey: name)
                let clonedSet = cloned.mutableSetValue(forKey: name)
                let enumerator = sourceSet.objectEnumerator()
                
                while let relatedObject = enumerator.nextObject() as? NSManagedObject {
                    clonedSet.add(relatedObject)
                }
            } else if let value = self.value(forKey: name) as? NSManagedObject {
                let target = context.object(with: value.objectID)
                cloned.setValue(target, forKey: name)
            }
        }
        
        relationships?.forEach(mappingRelationships)
        
        return cloned
    }
}
