//
//  Property+Type.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation

public typealias Fetched<T: Entity> = FetchedProperty<T>

public enum Relation {
    public typealias ToOne<D: Entity> = Relationship<Crush.ToOne<D>>
    public typealias ToMany<D: Entity> = Relationship<Crush.ToMany<D>>
    public typealias ToOrdered<D: Entity> = Relationship<Crush.ToOrdered<D>>
}

public enum Value {
    public typealias Transformable<T: TransformableAttributeType> = TransformableAttribute<Attribute<T>>
    public typealias Codable<T: CodableAttributeType> = Attribute<T>
    public typealias Enum<E: EnumerableAttributeType> = Attribute<E>
    public typealias Int16 = Attribute<Int16AttributeType>
    public typealias Int32 = Attribute<Int32AttributeType>
    public typealias Int64 = Attribute<Int64AttributeType>
    public typealias Double = Attribute<DoubleAttributeType>
    public typealias Float = Attribute<FloatAttributeType>
    public typealias String = Attribute<StringAttributeType>
    public typealias Bool = Attribute<BoolAttributeType>
    public typealias Data = Attribute<BinaryDataAttributeType>
    public typealias Date = Attribute<DateAttributeType>
    public typealias Decimal = Attribute<DecimalAttributeType>
    public typealias UUID = Attribute<UUIDAttributeType>
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public enum Derived {
    public typealias Transformable<T: TransformableAttributeType> = TransformableAttribute<DerivedAttribute<T>>
    public typealias Codable<T: CodableAttributeType> = DerivedAttribute<T>
    public typealias Enum<E: EnumerableAttributeType> = DerivedAttribute<E>
    public typealias Int16 = DerivedAttribute<Int16AttributeType>
    public typealias Int32 = DerivedAttribute<Int32AttributeType>
    public typealias Int64 = DerivedAttribute<Int64AttributeType>
    public typealias Double = DerivedAttribute<DoubleAttributeType>
    public typealias Float = DerivedAttribute<FloatAttributeType>
    public typealias String = DerivedAttribute<StringAttributeType>
    public typealias Bool = DerivedAttribute<BoolAttributeType>
    public typealias Data = DerivedAttribute<BinaryDataAttributeType>
    public typealias Date = DerivedAttribute<DateAttributeType>
    public typealias Decimal = DerivedAttribute<DecimalAttributeType>
    public typealias UUID = DerivedAttribute<UUIDAttributeType>
}
