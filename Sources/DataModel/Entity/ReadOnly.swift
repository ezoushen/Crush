//
//  ReadOnly.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/5/6.
//

import CoreData

@dynamicMemberLookup
public struct ReadOnly<Entity: Crush.Entity> {
    
    internal let managedObject: ManagedObject<Entity>
    internal let context: NSManagedObjectContext
    
    public init(_ value: ManagedObject<Entity>) {
        guard let context = value.managedObjectContext else {
            fatalError("Accessing stale object is dangerous")
        }
        self.managedObject = value
        self.context = context
    }

    public func access<T: ValuedProperty>(
        keyPath: KeyPath<Entity, T>) -> T.PropertyValue
    {
        context.performSync { managedObject[immutable: keyPath] }
    }

    public subscript<T: ValuedProperty>(
        dynamicMember keyPath: KeyPath<Entity, T>) -> T.PropertyValue
    {
        access(keyPath: keyPath)
    }

    public subscript<T: ValuedProperty>(
        dynamicMember keyPath: KeyPath<Entity, T>
    ) -> T.PropertyValue.Safe
    where
        T.PropertyValue: UnsafeSessionProperty
    {
        context.performSync { managedObject[immutable: keyPath].wrapped() }
    }
}

extension ReadOnly: ManagedStatus {
    public var contentHashValue: Int {
        managedObject.contentHashValue
    }

    public var isInaccessible: Bool {
        managedObject.managedObjectContext == nil
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<ManagedObject<Entity>, T>) -> T {
        managedObject[keyPath: keyPath]
    }

    public func hasFault<T: RelationshipProtocol>(
        forRelationship keyPath: KeyPath<Entity, T>) -> Bool
    {
        managedObject.hasFault(forRelationshipNamed: keyPath.propertyName)
    }
    
    public func changedValues() -> [String: Any] {
        context.performSync { managedObject.changedValues() }
    }
    
    public func changedValuesForCurrentEvent() -> [String: Any] {
        context.performSync { managedObject.changedValuesForCurrentEvent() }
    }
    
    public func commitedValues(forKeys keys: [String]?) -> [String: Any] {
        context.performSync { managedObject.committedValues(forKeys: keys) }
    }
}

extension ReadOnly: Equatable {
    public static func == (lhs: ReadOnly, rhs: ReadOnly) -> Bool {
        lhs.managedObject == rhs.managedObject
    }
}

extension ReadOnly: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(managedObject)
    }
}

public protocol ReadaleObject { }

extension Entity: ReadaleObject { }

extension ReadaleObject where Self: Entity {
    public typealias ReadOnly = Crush.ReadOnly<Self>
}

#if canImport(SwiftUI) && canImport(Combine)
import Combine
import SwiftUI

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public final class ObservableReadOnly<Entity: Crush.Entity>: ObservableObject {

    internal let readOnly: ReadOnly<Entity>
    internal var cancellable: AnyCancellable!

    internal init(_ readOnly: ReadOnly<Entity>) {
        self.readOnly = readOnly
        self.cancellable = readOnly.managedObject
            .objectWillChange
            .sink { [unowned self] in objectWillChange.send() }
    }

    public subscript<T: ValuedProperty>(
        dynamicMember keyPath: KeyPath<Entity, T>) -> T.PropertyValue
    {
        readOnly.access(keyPath: keyPath)
    }

    public subscript<T: ValuedProperty>(
        dynamicMember keyPath: KeyPath<Entity, T>
    ) -> T.PropertyValue.Safe
    where
        T.PropertyValue: UnsafeSessionProperty
    {
        readOnly[dynamicMember: keyPath]
    }
}
#endif
