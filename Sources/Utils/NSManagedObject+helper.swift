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
        object(with: runtimeObject.objectID) as! T
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
