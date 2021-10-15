//
//  DataModel.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

public class DataModel {
    public let name: String
    public let entityDescriptions: Set<EntityDescription>

    public init(_ name: String, descriptions: Set<EntityDescription>) {
        self.name = name
        self.entityDescriptions = descriptions
    }

    internal func entityDescriptionHash() -> Int {
        var hasher = Hasher()
        hasher.combine(entityDescriptions)
        return hasher.finalize()
    }

    lazy var managedObjectModel: NSManagedObjectModel = {
        let key = entityDescriptionHash()
        if let cachedModel = Caches.managedObjectModel.get(key) {
            return cachedModel
        }
        let model = NSManagedObjectModel()
        Caches.property.clean()
        Caches.entity.clean()
        defer {
            Caches.managedObjectModel.set(key, value: model)
            Caches.property.clean()
            Caches.entity.clean()
        }
        let sortedDescriptions = entityDescriptions
            .sorted { $0.inheritance < $1.inheritance }
        let meta = sortedDescriptions
            .reduce(into: EntityInheritanceMeta()) {
                $0[ObjectIdentifier($1.type)] = $1.inheritance
            }
        let entities: [NSEntityDescription] = sortedDescriptions
            .compactMap { $0.type.createEntityDescription(meta: meta) }
        model.versionIdentifiers = [name]
        model.entities = entities
        return model
    }()
}
