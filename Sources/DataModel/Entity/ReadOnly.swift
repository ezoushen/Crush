//
//  ReadOnly.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/5/6.
//

import CoreData

@dynamicMemberLookup
public struct ReadOnly<Value: Entity> {
    
    internal let value: ManagedObject<Value>
    internal let context: NSManagedObjectContext
    
    public init(_ value: ManagedObject<Value>) {
        guard let context = value.managedObjectContext else {
            fatalError("Accessing stale object is dangerous")
        }
        self.value = value
        self.context = context
    }

    @inline(__always)
    private func access<T: ValuedProperty>(
        keyPath: KeyPath<Value, T>) -> T.PropertyValue
    {
        context.performSync { value[immutable: keyPath] }
    }

    public subscript<T: AttributeProtocol>(
        dynamicMember keyPath: KeyPath<Value, T>) -> T.PropertyValue
    {
        access(keyPath: keyPath)
    }

    public subscript<T: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Value, T>
    ) -> T.Mapping.EntityType.ReadOnly?
    where
        T.Mapping == ToOne<T.Destination>
    {
        guard let value = access(keyPath: keyPath)
        else { return nil }
        return ReadOnly<T.Destination>(value)
    }

    public subscript<T: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Value, T>
    ) -> Set<T.Destination.ReadOnly>
    where
        T.Mapping == ToMany<T.Destination>
    {
        context.performSync {
            let set = value[immutable: keyPath]
            return Set(set.map { ReadOnly<T.Destination>($0) })
        }
    }
    
    public subscript<T: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Value, T>
    ) -> OrderedSet<T.Destination.ReadOnly>
    where
        T.Mapping == ToOrdered<T.Destination>
    {
        context.performSync {
            let orderedSet = value[immutable: keyPath]
            return OrderedSet(
                orderedSet.map{ ReadOnly<T.Destination>($0) })
        }
    }
}

extension ReadOnly {
    public var hasChanges: Bool {
        value.hasChanges
    }
    
    public var managedObjectID: NSManagedObjectID {
        value.objectID
    }
    
    public var hasPersistentChangedValues: Bool {
        value.hasPersistentChangedValues
    }
    
    public var isInserted: Bool {
        value.isInserted
    }
    
    public var isDeleted: Bool {
        value.isDeleted
    }
    
    public var isUpdated: Bool {
        value.isUpdated
    }
    
    public var isFault: Bool {
        value.isFault
    }
    
    public var faultingState: Int {
        value.faultingState
    }
    
    public func hasFault<T: RelationshipProtocol>(
        forRelationship keyPath: KeyPath<Value, T>) -> Bool
    {
        value.hasFault(forRelationshipNamed: keyPath.propertyName)
    }
    
    public func changedValues() -> [String: Any] {
        value.changedValues()
    }
    
    public func changedValuesForCurrentEvent() -> [String: Any] {
        value.changedValuesForCurrentEvent()
    }
    
    public func commitedValues(forKeys keys: [String]?) -> [String: Any] {
        value.committedValues(forKeys: keys)
    }
}

extension ReadOnly: Equatable {
    public static func == (lhs: ReadOnly, rhs: ReadOnly) -> Bool {
        lhs.value == rhs.value
    }
}

extension ReadOnly: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

public protocol ReadaleObject { }

extension Entity: ReadaleObject { }

extension ReadaleObject where Self: Entity {
    public typealias ReadOnly = Crush.ReadOnly<Self>
}
