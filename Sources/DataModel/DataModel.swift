//
//  DataModel.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

/// Declare a map describing relationships between entites.
///
/// This class should always be subclassed and declared available entities within.
/// There're three kinds of modifier you should use to mark an entity, including ``Abstract``,  ``Concrete``,  and ``Embedded``,
/// where an unannotated entity would be considered as ``Concrete``. Besides, you can assign the entity to multiple
/// configurations by annotating it with multiple ``Configuration``, and the order would not effect the final results.
/// At the same time, it's a different story for entity type modifiers. The modifier on the top would trump the result.
///
/// Example:
///
///     class CurrentEntityMap: EntityMap {
///         @Abstract
///         var abstractEntity = AbstractEntity()
///
///         @Configuration("CONF")
///         @Configuration("ANOTHER CONF")
///         @Embedded
///         @Abstract // This modifier will be ignored
///         var embeddedEntity = EmbeddedEntity()
///
///         @Concrete
///         @Configuration("CONF")
///         var concreteEntity = ConcreteEntity()
///     }
///
///     // "CONF" includes EmbeddedEntity and ConcreteEntity.
///     // "ANOTHER CONF" includes noly EmbeddedEntity.
///
open /*abstract*/ class EntityMap {
    open var name: String {
        String(describing: Self.self)
    }
}

public final class DataModel {
    public struct EntityConfiguration: Hashable {
        public let name: String?
        public let abstractEntities: Set<Entity>
        public let embeddedEntities: Set<Entity>
        public let concreteEntities: Set<Entity>

        public init(name: String?, abstract: Set<Entity> = [], embedded: Set<Entity> = [], concrete: Set<Entity> = []) {
            self.name = name
            self.abstractEntities = abstract
            self.embeddedEntities = embedded
            self.concreteEntities = concrete
        }
    }

    public let name: String

    private let descriptors: [any EntityDescriptor]
    private(set) var uniqueIdentifier: Int

    init(name: String, descriptors: [any EntityDescriptor]) {
        self.name = name
        self.descriptors = descriptors
        self.uniqueIdentifier = {
            var hasher = Hasher()
            hasher.combine(name)
            hasher.combine(Set(descriptors.map { $0.typeIdentifier() }))
            return hasher.finalize()
        }()
    }

    public convenience init(entityMap: EntityMap) {
        let descriptors = Mirror(reflecting: entityMap).children.compactMap {
            switch $0.value {
            case let descriptor as EntityDescriptor: return descriptor
            case let entity as Entity: return Configuration(wrappedValue: entity, nil)
            default: return nil
            }
        }
        self.init(name: entityMap.name, descriptors: descriptors)
    }

    public convenience init(name: String, configurations: Set<DataModel.EntityConfiguration>) {
        assert(Set(configurations.map(\.name)).count == configurations.count, "Configuration name must be unique")

        var descriptorsByEntity: [Entity: any EntityDescriptor] = [:]

        func createDescriptor(
            entity: Entity,
            instance: @autoclosure () -> any EntityDescriptor,
            configuration: EntityConfiguration) -> (any EntityDescriptor)?
        {
            guard descriptorsByEntity[entity] == nil else {
                /// If the descriptor had been created, just update the configuration name
                if let name = configuration.name {
                    descriptorsByEntity[entity]?.configurations.append(name)
                }
                return nil
            }
            /// Create the descriptor and wrap it with `Configuration`
            let descriptor = instance()
            let named = Configuration(wrappedValue: descriptor, configuration.name)
            descriptorsByEntity[entity] = named
            return named
        }

        let descriptors = configurations.flatMap { configuration in
            configuration.abstractEntities.compactMap {
                createDescriptor(
                    entity: $0,
                    instance: Abstract(wrappedValue: $0),
                    configuration: configuration)
            } + configuration.embeddedEntities.compactMap {
                createDescriptor(
                    entity: $0,
                    instance: Embedded(wrappedValue: $0),
                    configuration: configuration)
            } + configuration.concreteEntities.compactMap {
                createDescriptor(
                    entity: $0,
                    instance: Concrete(wrappedValue: $0),
                    configuration: configuration)
            }
        }

        self.init(name: name, descriptors: descriptors)
    }

    public convenience init(name: String, abstract: Set<Entity> = [], embedded: Set<Entity> = [], concrete: Set<Entity>) {
        self.init(name: name, configurations: [
            EntityConfiguration(
                name: nil,
                abstract: abstract,
                embedded: embedded,
                concrete: concrete)
        ])
    }

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
                for configuration in descriptor.configurations ?? [] {
                    dict[configuration].append(description)
                }
                dict[nil].append(description)
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

extension Swift.Optional
where
    Wrapped: MutableCollection & ExpressibleByArrayLiteral & RangeReplaceableCollection,
    Wrapped.ArrayLiteralElement == Wrapped.Element
{
    mutating func append(_ element: Wrapped.Element) {
        switch self {
        case .none:
            self = .some(Wrapped(arrayLiteral: element))
        case .some(let collection):
            var localCollection = collection
            localCollection.append(element)
            self = .some(localCollection)
        }
    }
}
