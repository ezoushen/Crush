//
//  NSManagedObject+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func receive<T: NSManagedObject>(runtimeObject: T) -> T {
        let result = object(with: runtimeObject.objectID) as! T
        if runtimeObject.isFault == false {
            let description = T.entity()
            let key = description.allAttributeKeys().first ??
                        description.allToOneRelationshipKeys().first ??
                        description.allToManyRelationshipKeys().first!
            result.willAccessValue(forKey: key)
        }
        return result
    }
}

extension NSEntityDescription {
    open func allAttributeKeys() -> [String] {
        Array(attributesByName.keys)
    }

    open func allToOneRelationshipKeys() -> [String] {
        relationshipsByName
            .filter { !$0.value.isToMany }
            .map { $0.key }
    }

    open func allToManyRelationshipKeys() -> [String] {
        relationshipsByName
            .filter { $0.value.isToMany }
            .map { $0.key }
    }
}
