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
    
    var contentHashValue: Int { get }

    func hasFault<T: RelationshipProtocol>(
        forRelationship keyPath: KeyPath<Entity, T>) -> Bool
    func changedValues() -> [String: Any]
    func changedValuesForCurrentEvent() -> [String: Any]
    func commitedValues(forKeys keys: [String]?) -> [String: Any]
}

extension ManagedStatus where Self: ObjectDriver {
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

    public var contentHashValue: Int {
        managedObject.contentHashValue
    }
}

extension NSManagedObject {
    public var contentHashValue: Int {
        entity
            .properties
            .compactMap { value(forKey: $0.name) as? AnyHashable }
            .reduce(into: Hasher()) { $0.combine($1) }
            .finalize()
    }
}
