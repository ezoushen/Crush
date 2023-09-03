//
//  Deprecated.swift
//  
//
//  Created by EZOU on 2023/2/23.
//

import Foundation

@available(*, deprecated, renamed: "EnumerableAttributeType")
public typealias Enumerator = EnumerableAttributeType

@available(*, deprecated, renamed: "CodableAttributeType")
public typealias CodableProperty = CodableAttributeType

extension TypedPredicate {
    @available(*, deprecated, renamed: "subquery(_:predicate:)")
    public static func join<Property: RelationshipProtocol>(
        _ keyPath: KeyPath<T, Property>, predicate: TypedPredicate<Property.Destination>
    ) -> Self
    where
    Property.Mapping == ToOne<Property.Destination>
    {
        subquery(keyPath, predicate: predicate)
    }
}

extension DriverBase {
    @available(*, deprecated, renamed: "cast(to:)")
    @inlinable public func runtimeDriver<T: Crush.Entity>(entity: T.Type) -> T.Driver? {
        ManagedDriver(managedObject)
    }

    @available(*, deprecated, renamed: "cast(to:)")
    @inlinable public func unsafeDriver<T: Crush.Entity>(entity: T.Type) -> T.Driver {
        ManagedDriver(unsafe: managedObject)
    }

    @available(*, deprecated, renamed: "cast(to:)")
    @inlinable public func rawDriver<T: Crush.Entity>(entity: T.Type) -> T.RawDriver? {
        ManagedRawDriver(managedObject)
    }

    @available(*, deprecated, renamed: "cast(to:)")
    @inlinable public func unsafeRawDriver<T: Crush.Entity>(entity: T.Type) -> T.RawDriver {
        ManagedRawDriver(unsafe: managedObject)
    }
}

extension ManagableObject where Self: Entity {
    @available(*, deprecated, renamed: "Driver", message: "ManagedObject is obsolete, please use ManagedDriver instead.")
    public typealias Managed = ManagedDriver<Self>
}
