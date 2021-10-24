//
//  ManagedStatus.swift
//  
//
//  Created by ezou on 2021/10/24.
//

import CoreData
import Foundation

public protocol ManagedStatus {
    associatedtype Entity: Crush.Entity

    var hasChanges: Bool { get }
    var managedObjectID: NSManagedObjectID { get }
    var hasPersistentChangedValues: Bool { get }
    var isInserted: Bool { get }
    var isDeleted: Bool { get }
    var isUpdated: Bool { get }
    var isFault: Bool { get }
    var faultingState: Int { get }

    func hasFault<T: RelationshipProtocol>(
        forRelationship keyPath: KeyPath<Entity, T>) -> Bool
    func changedValues() -> [String: Any]
    func changedValuesForCurrentEvent() -> [String: Any]
    func commitedValues(forKeys keys: [String]?) -> [String: Any]
}

extension ManagedStatus where Self: ObjectDriver {
    public var hasChanges: Bool {
        managedObject.hasChanges
    }

    public var managedObjectID: NSManagedObjectID {
        managedObject.objectID
    }

    public var hasPersistentChangedValues: Bool {
        managedObject.hasPersistentChangedValues
    }

    public var isInserted: Bool {
        managedObject.isInserted
    }

    public var isDeleted: Bool {
        managedObject.isDeleted
    }

    public var isUpdated: Bool {
        managedObject.isUpdated
    }

    public var isFault: Bool {
        managedObject.isFault
    }

    public var faultingState: Int {
        managedObject.faultingState
    }

    public func hasFault<T: RelationshipProtocol>(
        forRelationship keyPath: KeyPath<Entity, T>) -> Bool
    {
        managedObject.hasFault(forRelationshipNamed: keyPath.propertyName)
    }

    public func changedValues() -> [String: Any] {
        managedObject.changedValues()
    }

    public func changedValuesForCurrentEvent() -> [String: Any] {
        managedObject.changedValuesForCurrentEvent()
    }

    public func commitedValues(forKeys keys: [String]?) -> [String: Any] {
        managedObject.committedValues(forKeys: keys)
    }
}
