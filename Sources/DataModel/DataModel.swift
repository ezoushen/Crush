//
//  DataModel.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

/// Declare a map that describes relationships between entities.
///
/// This class should always be subclassed and be responsible for declaring available entities within.
/// There are three kinds of modifiers that you can use to mark an entity, including ``Abstract``, ``Concrete``, and ``Embedded``.
/// An unannotated entity is considered ``Concrete``.
/// Besides, you can assign the entity to multiple configurations by annotating it with multiple ``Configuration``. The order of annotation does not affect the final results.
/// However, the modifier on the top will override the result.
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
/// - Note: `EntityMap` should be subclassed and is responsible for declaring available entities within.
///
/// - Warning: A configuration name must be unique.
///
open /*abstract*/ class EntityMap {
    open var name: String {
        String(describing: Self.self)
    }
}

/// A `DataModel` is an immutable collection of configurations that define the entities within the model.
///
/// It also provides convenience methods for initializing the model, and generating a corresponding `NSManagedObjectModel`.
/// You can create a `DataModel` by  ``init(entityMap:)`` or define the relationships between entities directly by ``init(name:_:)``
///
/// Usage:
///
/// ```swift
/// // These two `DataModel` is identical
/// DataModel(name: "MyDataModel", concrete: [MyEntity()])
/// DataModel(name: "MyDataModel", [Concrete(MyEntity())])
///
/// // This will assign `MyEntity` to "configuration"
/// DataModel(name: "MyDataModel", concrete: [Configuration(MyEntity(), "configuration")])
///
/// // Load the entities from custom `EntityMap`
/// DataModel(entityMap: MyEntityMap())
/// ```
///
public final class DataModel {

    public let name: String

    private let descriptors: [any EntityDescriptor]
    private(set) var uniqueIdentifier: Int

    init(name: String, descriptors: [any EntityDescriptor]) {
        assert(
            Set(descriptors.map { $0.typeIdentifier() }).count == descriptors.count,
            "Entities duplicated")
        self.name = name
        self.descriptors = descriptors
        self.uniqueIdentifier = {
            var hasher = Hasher()
            hasher.combine(name)
            hasher.combine(Set(descriptors.map { $0.typeIdentifier() }))
            return hasher.finalize()
        }()
    }

    /// Initializes a `DataModel` instance based on entities
    ///
    /// Uncategorized entities will be considering ``Concrete``
    public convenience init(name: String, _ entities: [Entity]) {
        self.init(name: name, descriptors: entities.map {
            switch $0 {
            case let descriptor as EntityDescriptor: return descriptor
            default: return Configuration(wrappedValue: $0, nil)
            }
        })
    }

    /// Initializes a `DataModel` instance based on an `EntityMap`.
    ///
    /// - Parameter entityMap: The `EntityMap` to be converted.
    public convenience init(entityMap: EntityMap) {
        self.init(name: entityMap.name, Mirror(reflecting: entityMap).children.compactMap {
            $0.value as? Entity
        })
    }

    /// Initializes a `DataModel` instance based on categorized entities
    ///
    /// Entity type descriptor will be ignored if it'd already applied within the entity set
    public convenience init(
        name: String,
        abstract: Set<Entity> = [],
        embedded: Set<Entity> = [],
        concrete: Set<Entity>)
    {
        self.init(
            name: name,
                abstract.map { Abstract($0, inheritance: .singleTable) } +
                embedded.map { Abstract($0, inheritance: .multiTable) } +
                concrete.map { Concrete($0) }
        )
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

        typealias AbstractionData = [ObjectIdentifier: EntityAbstraction]

        /// Dictionary for looking up which abstraction type the entity applied
        let abstractionData = descriptors.reduce(into: AbstractionData()) {
            $0[$1.typeIdentifier()] = $1.entityAbstraction
        }

        let entitiesIndexedByConfiguration = descriptors
            .sorted { $0.entityAbstraction < $1.entityAbstraction }
            .reduce(into: [String?: [NSEntityDescription]]()) { dict, descriptor in
                guard let description = descriptor
                    .createEntityDescription(abstractionData: abstractionData, cache: cache) else { return }
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
