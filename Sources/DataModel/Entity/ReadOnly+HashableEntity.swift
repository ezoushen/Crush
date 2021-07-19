//
//  ReadOnly+Entity.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/5/6.
//

import CoreData

@dynamicMemberLookup
public struct ReadOnly<Value: Entity> {
    public let value: ManagedObject<Value>
    
    public var managedObjectID: NSManagedObjectID {
        value.objectID
    }
    
    public init(_ value: ManagedObject<Value>) {
        self.value = value
    }

    public func access<T: ValuedProperty>(keyPath: KeyPath<Value, T>) -> T.PropertyValue {
        guard let context = value.managedObjectContext else {
            fatalError("Accessing stale object is dangerous")
        }
        return context.performSync { value[dynamicMember: keyPath] }
    }

    public subscript<T: ValuedProperty>(dynamicMember keyPath: KeyPath<Value, T>) -> T.PropertyValue {
        access(keyPath: keyPath)
    }

    public subscript<T: RelationshipProtocol>(dynamicMember keyPath: KeyPath<Value, T>) -> ReadOnly<T.Mapping.EntityType>?
    where
        T.Mapping.RuntimeObjectValue == ManagedObject<T.Mapping.EntityType>?,
        T.PropertyValue == T.Mapping.RuntimeObjectValue
    {
        guard let value = access(keyPath: keyPath) else { return nil }
        return ReadOnly<T.Mapping.EntityType>(value)
    }

    public subscript<T: RelationshipProtocol>(dynamicMember keyPath: KeyPath<Value, T>) -> Set<T.Mapping.EntityType.ReadOnly>
    where
        T.Mapping.RuntimeObjectValue == Set<ManagedObject<T.Mapping.EntityType>>,
        T.PropertyValue == T.Mapping.RuntimeObjectValue
    {
        guard let context = value.managedObjectContext else {
            fatalError("Accessing stale object is dangerous")
        }
        return context.performSync {
            Set<T.Mapping.EntityType.ReadOnly>(value[dynamicMember: keyPath].map{ .init($0) })
        }
    }
}

extension ReadOnly: Equatable where Value: Equatable {
    public static func == (lhs: ReadOnly, rhs: ReadOnly) -> Bool {
        lhs.value == rhs.value
    }
}

extension ReadOnly: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension Entity {
    public typealias ReadOnly = Crush.ReadOnly<Self>
}

public protocol ObservableProtocol {
    associatedtype ObservableType: FieldConvertible
}
