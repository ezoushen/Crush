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
