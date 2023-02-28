//
//  DataModel.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

open class DataModel {
    public struct EntityConfiguration: Hashable {
        public let name: String?
        public let abstractEntities: Set<Entity>
        public let embeddedEntities: Set<Entity>
        public let concreteEntities: Set<Entity>

        public init(name: String?, abstract: Set<Entity>, embedded: Set<Entity>, concrete: Set<Entity>) {
            self.name = name
            self.abstractEntities = abstract
            self.embeddedEntities = embedded
            self.concreteEntities = concrete
        }

        var entities: [Entity] {
            Array(abstractEntities) + Array(embeddedEntities) + Array(concreteEntities)
        }
    }

    public let name: String

    private lazy var descriptors: [any ConfigurationEntityDescriptior] = {
        Mirror(reflecting: self).children.compactMap {
            switch $0.value {
            case let configuration as ConfigurationEntityDescriptior:
                return configuration
            case let entity as Entity:
                return Crush.Configuration(wrappedValue: entity, names: nil)
            default:
                return nil
            }
        }
    }()

    public required init(name: String) {
        self.name = name
        self.uniqueIdentifier = ObjectIdentifier(type(of: Self.self)).hashValue
    }

    public init(name: String, configurations: Set<DataModel.EntityConfiguration>) {
        self.name = name
        self.uniqueIdentifier = configurations.hashValue

        assert(Set(configurations.map(\.name)).count == configurations.count, "Configuration name must be unique")
        
        self.descriptors = configurations.flatMap { configuration in
            configuration.abstractEntities.map {
                Crush.Configuration(wrappedValue: Abstract(wrappedValue: $0), name: configuration.name)
            } + configuration.embeddedEntities.map {
                Crush.Configuration(wrappedValue: Embedded(wrappedValue: $0), name: configuration.name)
            } + configuration.concreteEntities.map {
                Crush.Configuration(wrappedValue: Concrete(wrappedValue: $0), name: configuration.name)
            }
        }
    }

    public init(name: String, abstract: Set<Entity> = [], embedded: Set<Entity> = [], concrete: Set<Entity>) {
        self.name = name
        self.uniqueIdentifier = {
            var hasher = Hasher()
            hasher.combine(name)
            hasher.combine(abstract)
            hasher.combine(embedded)
            hasher.combine(concrete)
            return hasher.finalize()
        }()
        self.descriptors =
            abstract.map {
                Crush.Configuration(wrappedValue: Abstract(wrappedValue: $0), name: nil)
            } + embedded.map {
                Crush.Configuration(wrappedValue: Embedded(wrappedValue: $0), name: nil)
            } + concrete.map {
                Crush.Configuration(wrappedValue: Concrete(wrappedValue: $0), name: nil)
            }
    }

    let uniqueIdentifier: Int

    lazy var managedObjectModel: NSManagedObjectModel = {
        let key = uniqueIdentifier

        /// Return cached data model if presented
        if let cachedModel = Caches.managedObjectModel.get(key) {
            return cachedModel
        }

        let model = NSManagedObjectModel()
        let cache = EntityCache()

        defer {
            Caches.managedObjectModel.set(key, value: model)
        }

        typealias InheritanceData = [ObjectIdentifier: EntityInheritance]

        /// Dictionary for looking up which inheritance type the entity applied
        let inheritanceData = descriptors.reduce(into: InheritanceData()) {
            $0[$1.typeIdentifier()] = $1.entityInheritance
        }

        let entitiesIndexedByConfiguration = descriptors
            .sorted { $0.entityInheritance < $1.entityInheritance }
            .reduce(into: [String?: [NSEntityDescription]]()) { dict, descriptor in
                guard let description = descriptor
                    .createEntityDescription(inheritanceData: inheritanceData, cache: cache) else { return }
                func configure(name: String?) {
                    let arr = dict[name, default: []]
                    dict[name] = arr + [description]
                }
                for name in descriptor.names ?? [] {
                    configure(name: name)
                }
                configure(name: nil)
            }

        assert(entitiesIndexedByConfiguration[nil]?.isEmpty == false, "DataModel should not be empty")

        model.versionIdentifiers = [name]
        model.entities = entitiesIndexedByConfiguration[nil] ?? []

        /// Set configurations
        for (configuration, entities) in entitiesIndexedByConfiguration {
            guard let name = configuration else { continue }
            model.setEntities(entities, forConfigurationName: name)
        }

        return model
    }()
}
