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
    public let abstractEntities: Set<Entity>
    public let embeddedEntities: Set<Entity>
    public let concreteEntities: Set<Entity>

    public init(name: String, abstract: Set<Entity> = [], embedded: Set<Entity> = [], concrete: Set<Entity>) {
        self.name = name
        self.abstractEntities = abstract
        self.embeddedEntities = embedded
        self.concreteEntities = concrete
    }

    internal func entityDescriptionHash() -> Int {
        var hasher = Hasher()
        hasher.combine(abstractEntities)
        hasher.combine(embeddedEntities)
        hasher.combine(concreteEntities)
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

        var inhertanceData = [ObjectIdentifier: EntityInheritance]()
        abstractEntities.forEach { inhertanceData[ObjectIdentifier(type(of: $0))] = .abstract }
        embeddedEntities.forEach { inhertanceData[ObjectIdentifier(type(of: $0))] = .embedded }
        concreteEntities.forEach { inhertanceData[ObjectIdentifier(type(of: $0))] = .concrete }

        let entities: [NSEntityDescription] = (
            Array(abstractEntities) +
            Array(embeddedEntities) +
            Array(concreteEntities)
        )
            .compactMap { $0.createEntityDescription(inhertanceData: inhertanceData) }
        
        model.versionIdentifiers = [name]
        model.entities = entities
        return model
    }()
}
