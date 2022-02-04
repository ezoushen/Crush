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
    public typealias Transform<T: NSCoding & FieldAttribute> = Attribute<T>
    public typealias Codable<T: CodableProperty> = Attribute<T>
    public typealias Int16 = Attribute<Swift.Int16>
    public typealias Int32 = Attribute<Swift.Int32>
    public typealias Int64 = Attribute<Swift.Int64>
    public typealias DecimalNumber = Attribute<NSDecimalNumber>
    public typealias Double = Attribute<Swift.Double>
    public typealias Float = Attribute<Swift.Float>
    public typealias String = Attribute<Swift.String>
    public typealias Bool = Attribute<Swift.Bool>
    public typealias Date = Attribute<Foundation.Date>
    public typealias Data = Attribute<Foundation.Data>
    public typealias UUID = Attribute<Foundation.UUID>
    public typealias Enum<E: Enumerator> = Attribute<E>
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public enum Derived {
    public typealias Transform<T: NSCoding & FieldAttribute> = DerivedAttribute<T>
    public typealias Codable<T: CodableProperty> = DerivedAttribute<T>
    public typealias Int16 = DerivedAttribute<Swift.Int16>
    public typealias Int32 = DerivedAttribute<Swift.Int32>
    public typealias Int64 = DerivedAttribute<Swift.Int64>
    public typealias DecimalNumber = DerivedAttribute<NSDecimalNumber>
    public typealias Double = DerivedAttribute<Swift.Double>
    public typealias Float = DerivedAttribute<Swift.Float>
    public typealias String = DerivedAttribute<Swift.String>
    public typealias Bool = DerivedAttribute<Swift.Bool>
    public typealias Date = DerivedAttribute<Foundation.Date>
    public typealias Data = DerivedAttribute<Foundation.Data>
    public typealias UUID = DerivedAttribute<Foundation.UUID>
    public typealias Enum<E: Enumerator> = DerivedAttribute<E>
}
