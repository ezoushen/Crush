//
//  PrimaryKey.swift
//  
//
//  Created by EZOU on 2023/8/11.
//

import CoreData
import Foundation

/// Represents a primary key for an entity.
public struct PrimaryKey<T: Entity> {
    /// The name of the entity.
    public let entityName: String
    /// The incremental ID of the object.
    public let incrementalID: Int

    /// Initializes a primary key with the given incremental ID.
    ///
    /// - Parameter incrementalID: The incremental ID of the object.
    public init(_ incrementalID: Int) {
        self.entityName = T.name
        self.incrementalID = incrementalID
    }

    /// Initializes a primary key with the given object ID.
    ///
    /// - Parameter objectID: The object ID.
    /// - Returns: The primary key if the object ID is valid, otherwise nil.
    public init?(objectID: NSManagedObjectID) {
        guard objectID.isTemporaryID == false, objectID.entity == T.entity()
        else { return nil }
        let uri = objectID.uriRepresentation()
        let idString = String(uri.lastPathComponent.dropFirst(1))
        guard let id = Int(idString) else { return nil }
        self.init(id)
    }
}

extension PrimaryKey {
    /// Returns the `NSManagedObjectID` associated with the `PrimaryKey`.
    ///
    /// - Parameter loader: The `PrimaryKeyLoader` used to retrieve the `NSManagedObjectID`.
    /// - Returns: The `NSManagedObjectID` associated with the `PrimaryKey`, or `nil` if it cannot be retrieved.
    ///
    /// Usage:
    ///
    ///     let loader = PrimaryKeyLoader()
    ///     let objectID = primaryKey.objectID(loader)
    ///     print(objectID) // prints the NSManagedObjectID or nil
    ///
    public func objectID(_ loader: PrimaryKeyLoader) -> NSManagedObjectID? {
        loader.objectID(from: self)
    }
}

/// A protocol for loading NSManagedObjectIDs.
public protocol PrimaryKeyLoader {

    /// Retrieves the NSManagedObjectID for the given primary key.
    ///
    /// - Parameter pk: The primary key of the entity.
    /// - Returns: The NSManagedObjectID associated with the primary key, or nil if not found.
    func objectID<T: Entity>(from pk: PrimaryKey<T>) -> NSManagedObjectID?
}

protocol NSPersistentStoreCoordinatorHolder {
    var coordinator: NSPersistentStoreCoordinator? { get }
}

extension PrimaryKeyLoader where Self: NSPersistentStoreCoordinatorHolder {
    func _objectID(entityName: String, incrementalID: Int) -> NSManagedObjectID? {
        func uriRepresentation(for store: NSPersistentStore) -> URL? {
            var components = URLComponents()
            components.scheme = "x-coredata"
            components.host = store.identifier
            components.path = "/\(entityName)/p\(incrementalID)"
            return components.url
        }

        func managedObjectID(in store: NSPersistentStore?) -> NSManagedObjectID? {
            guard let store, let url = uriRepresentation(for: store),
                  let objectID = coordinator?.managedObjectID(forURIRepresentation: url)
            else { return nil }
            return objectID
        }

        // Load from registered stores sequentially if not provided
        for store in coordinator?.persistentStores ?? [] {
            guard let id = managedObjectID(in: store) else { continue }
            return id
        }

        // Return nil otherwise
        return nil
    }
}

/// A container for managing Core Data operations.
extension DataContainer: PrimaryKeyLoader, NSPersistentStoreCoordinatorHolder {
    /// The persistent store coordinator.
    var coordinator: NSPersistentStoreCoordinator? { coreDataStack.coordinator }

    public func objectID<T: Entity>(from pk: PrimaryKey<T>) -> NSManagedObjectID? {
        _objectID(entityName: pk.entityName, incrementalID: pk.incrementalID)
    }

    /// Loads an object with the specified primary key.
    ///
    /// - Parameters:
    ///   - pk: The primary key.
    ///   - isFault: A flag indicating whether to load the object as a fault. Default is true.
    /// - Returns: The loaded object if found, otherwise nil.
    ///
    /// Usage:
    ///
    ///     let primaryKey = PrimaryKey<MyEntity>(1)
    ///     let object = dataContainer.load(primaryKey: primaryKey)
    ///
    public func load<T: Entity>(primaryKey pk: PrimaryKey<T>, isFault: Bool = true) -> T.ReadOnly? {
        guard let id = _objectID(entityName: pk.entityName, incrementalID: pk.incrementalID)
        else { return nil }
        return load(objectID: id, isFault: isFault)
    }

    /// Loads objects with the specified primary keys.
    ///
    /// - Parameters:
    ///   - pks: The primary keys.
    ///   - isFault: A flag indicating whether to load the objects as faults. Default is true.
    /// - Returns: An array of loaded objects. The array may contain nil values for objects that were not found.
    ///
    /// Usage:
    ///
    ///     let primaryKey1 = PrimaryKey<MyEntity>(1)
    ///     let primaryKey2 = PrimaryKey<MyEntity>(2)
    ///     let objects = dataContainer.load(primaryKeys: [primaryKey1, primaryKey2])
    ///
    public func load<T: Entity>(primaryKeys pks: [PrimaryKey<T>], isFault: Bool = true) -> [T.ReadOnly?] {
        pks.map { load(primaryKey: $0, isFault: isFault) }
    }
}

/// A session for managing Core Data operations.
extension Session: PrimaryKeyLoader, NSPersistentStoreCoordinatorHolder {
    /// The persistent store coordinator.
    var coordinator: NSPersistentStoreCoordinator? { context.uiContext.persistentStoreCoordinator }

    public func objectID<T: Entity>(from pk: PrimaryKey<T>) -> NSManagedObjectID? {
        _objectID(entityName: pk.entityName, incrementalID: pk.incrementalID)
    }

    /// Loads an object with the specified primary key.
    ///
    /// - Parameters:
    ///   - pk: The primary key.
    ///   - isFault: A flag indicating whether to load the object as a fault. Default is true.
    /// - Returns: The loaded object if found, otherwise nil.
    ///
    /// Usage:
    ///
    ///     let primaryKey = PrimaryKey<MyEntity>(1)
    ///     let object = session.load(primaryKey: primaryKey)
    ///
    public func load<T: Entity>(primaryKey pk: PrimaryKey<T>, isFault: Bool = true) -> T.ReadOnly? {
        guard let id = _objectID(entityName: pk.entityName, incrementalID: pk.incrementalID)
        else { return nil }
        return load(objectID: id, isFault: isFault)
    }

    /// Loads objects with the specified primary keys.
    ///
    /// - Parameters:
    ///   - pks: The primary keys.
    ///   - isFault: A flag indicating whether to load the objects as faults. Default is true.
    /// - Returns: An array of loaded objects. The array may contain nil values for objects that were not found.
    ///
    /// Usage:
    ///
    ///     let primaryKey1 = PrimaryKey<MyEntity>(1)
    ///     let primaryKey2 = PrimaryKey<MyEntity>(2)
    ///     let objects = session.load(primaryKeys: [primaryKey1, primaryKey2])
    ///
    public func load<T: Entity>(primaryKeys pks: [PrimaryKey<T>], isFault: Bool = true) -> [T.ReadOnly?] {
        pks.map { load(primaryKey: $0, isFault: isFault) }
    }
}

/// A session context for managing Core Data operations.
extension SessionContext: PrimaryKeyLoader, NSPersistentStoreCoordinatorHolder {
    /// The persistent store coordinator.
    var coordinator: NSPersistentStoreCoordinator? { executionContext.persistentStoreCoordinator }

    public func objectID<T: Entity>(from pk: PrimaryKey<T>) -> NSManagedObjectID? {
        _objectID(entityName: pk.entityName, incrementalID: pk.incrementalID)
    }

    /// Loads an object with the specified primary key.
    ///
    /// - Parameters:
    ///   - pk: The primary key.
    ///   - isFault: A flag indicating whether to load the object as a fault. Default is true.
    /// - Returns: The loaded object if found, otherwise nil.
    ///
    /// Usage:
    ///
    ///     let primaryKey = PrimaryKey<MyEntity>(1)
    ///     let object = sessionContext.load(primaryKey: primaryKey)
    ///
    public func load<T: Entity>(primaryKey pk: PrimaryKey<T>, isFault: Bool = true) -> T.Managed? {
        guard let id = _objectID(entityName: pk.entityName, incrementalID: pk.incrementalID)
        else { return nil }
        return load(objectID: id, isFault: isFault)
    }

    /// Loads objects with the specified primary keys.
    ///
    /// - Parameters:
    ///   - pks: The primary keys.
    ///   - isFault: A flag indicating whether to load the objects as faults. Default is true.
    /// - Returns: An array of loaded objects. The array may contain nil values for objects that were not found.
    ///
    /// Usage:
    ///
    ///     let primaryKey1 = PrimaryKey<MyEntity>(1)
    ///     let primaryKey2 = PrimaryKey<MyEntity>(2)
    ///     let objects = sessionContext.load(primaryKeys: [primaryKey1, primaryKey2])
    ///
    public func load<T: Entity>(primaryKeys pks: [PrimaryKey<T>], isFault: Bool = true) -> [T.Managed?] {
        pks.map { load(primaryKey: $0, isFault: isFault) }
    }
}

extension ManagedObject {
    /// The primary key of the managed object.
    public var primaryKey: PrimaryKey<Entity>? {
        PrimaryKey(objectID: objectID)
    }
}

extension ReadOnly {
    /// The primary key of the read-only object.
    public var primaryKey: PrimaryKey<Entity>? {
        PrimaryKey(objectID: managedObject.objectID)
    }
}

extension ObjectDriver {
    /// The primary key of the object driver.
    public var primaryKey: PrimaryKey<Entity>? {
        PrimaryKey(objectID: managedObject.objectID)
    }
}
