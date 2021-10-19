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

    public init(name: String, descriptions: Set<EntityDescription>) {
        self.name = name
        self.entityDescriptions = descriptions
    }
    
    public init(
        _ name: String,
        @CollectionBuilder<EntityDescription>
        descriptions: () -> Set<EntityDescription>)
    {
        self.name = name
        self.entityDescriptions = descriptions()
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
        Caches.entity.clean()
        defer {
            Caches.managedObjectModel.set(key, value: model)
            Caches.entity.clean()
        }
        let sortedDescriptions = entityDescriptions
            .sorted { $0.inheritance < $1.inheritance }
        let entityDescriptionsByType = sortedDescriptions
            .reduce(into: [ObjectIdentifier: EntityDescription]()) {
                $0[ObjectIdentifier($1.type)] = $1
            }
        let entities: [NSEntityDescription] = sortedDescriptions
            .compactMap {
                $0.type.createEntityDescription(
                    entityDescriptionsByType: entityDescriptionsByType)
            }
        model.versionIdentifiers = [name]
        model.entities = entities
        return model
    }()
}
