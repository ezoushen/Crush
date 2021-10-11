//
//  Property+Type.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation

public typealias Value = Required.Value
public typealias Relation = Required.Relation

public enum Optional {
    public struct Relation {
        public typealias ToOne<S: Entity, D: Entity> = Relationship<Nullable, S, Crush.ToOne<D>>
        public typealias ToMany<S: Entity, D: Entity> = Relationship<Nullable, S, Crush.ToMany<D>>
        public typealias ToOrderedMany<S: Entity, D: Entity> = Relationship<Nullable, S, Crush.ToOrderedMany<D>>
    }
    
    public struct Value {
        public typealias Transform<T: NSCoding & FieldAttribute & Hashable> = Attribute<Nullable, T>
        public typealias Codable<T: CodableProperty> = Attribute<Nullable, T>
        public typealias Int16 = Attribute<Nullable, Swift.Int16>
        public typealias Int32 = Attribute<Nullable, Swift.Int32>
        public typealias Int64 = Attribute<Nullable, Swift.Int64>
        public typealias DecimalNumber = Attribute<Nullable, NSDecimalNumber>
        public typealias Double = Attribute<Nullable, Swift.Double>
        public typealias Float = Attribute<Nullable, Swift.Float>
        public typealias String = Attribute<Nullable, Swift.String>
        public typealias Bool = Attribute<Nullable, Swift.Bool>
        public typealias Date = Attribute<Nullable, Foundation.Date>
        public typealias Data = Attribute<Nullable, Foundation.Data>
        public typealias UUID = Attribute<Nullable, Foundation.UUID>
        public typealias Enum<E: Enumerator> = Attribute<Nullable, E>
    }
}

public enum Required {
    public struct Relation {
        public typealias ToOne<S: Entity, D: Entity> = Relationship<NotNull, S, Crush.ToOne<D>>
        public typealias ToMany<S: Entity, D: Entity> = Relationship<NotNull, S, Crush.ToMany<D>>
        public typealias ToOrderedMany<S: Entity, D: Entity> = Relationship<NotNull, S, Crush.ToOrderedMany<D>>
    }

    public struct Value {
        public typealias Transform<T: NSCoding & FieldAttribute & Hashable> = Attribute<NotNull, T>
        public typealias Codable<T: CodableProperty> = Attribute<NotNull, T>
        public typealias Int16 = Attribute<NotNull, Swift.Int16>
        public typealias Int32 = Attribute<NotNull, Swift.Int32>
        public typealias Int64 = Attribute<NotNull, Swift.Int64>
        public typealias DecimalNumber = Attribute<NotNull, NSDecimalNumber>
        public typealias Double = Attribute<NotNull, Swift.Double>
        public typealias Float = Attribute<NotNull, Swift.Float>
        public typealias String = Attribute<NotNull, Swift.String>
        public typealias Bool = Attribute<NotNull, Swift.Bool>
        public typealias Date = Attribute<NotNull, Foundation.Date>
        public typealias Data = Attribute<NotNull, Foundation.Data>
        public typealias UUID = Attribute<NotNull, Foundation.UUID>
        public typealias Enum<E: Enumerator> = Attribute<NotNull, E>
    }
}

enum Transient {
    public typealias Value = Required.Value
    public typealias Relation = Required.Relation
    
    public enum Optional {
        public struct Relation {
            public typealias ToOne<S: Entity, D: Entity> = Temporary<Relationship<Nullable, S, Crush.ToOne<D>>>
            public typealias ToMany<S: Entity, D: Entity> = Temporary<Relationship<Nullable, S, Crush.ToMany<D>>>
            public typealias ToOrderedMany<S: Entity, D: Entity> = Temporary<Relationship<Nullable, S, Crush.ToOrderedMany<D>>>
        }
        
        public struct Value {
            public typealias Transform<T: NSCoding & FieldAttribute & Hashable> = Temporary<Attribute<Nullable, T>>
            public typealias Codable<T: CodableProperty> = Temporary<Attribute<Nullable, T>>
            public typealias Int16 = Temporary<Attribute<Nullable, Swift.Int16>>
            public typealias Int32 = Temporary<Attribute<Nullable, Swift.Int32>>
            public typealias Int64 = Temporary<Attribute<Nullable, Swift.Int64>>
            public typealias DecimalNumber = Temporary<Attribute<Nullable, NSDecimalNumber>>
            public typealias Double = Temporary<Attribute<Nullable, Swift.Double>>
            public typealias Float = Temporary<Attribute<Nullable, Swift.Float>>
            public typealias String = Temporary<Attribute<Nullable, Swift.String>>
            public typealias Bool = Temporary<Attribute<Nullable, Swift.Bool>>
            public typealias Date = Temporary<Attribute<Nullable, Foundation.Date>>
            public typealias Data = Temporary<Attribute<Nullable, Foundation.Data>>
            public typealias UUID = Temporary<Attribute<Nullable, Foundation.UUID>>
            public typealias Enum<E: Enumerator> = Temporary<Attribute<Nullable, E>>

        }
    }

    public enum Required {
        public struct Relation {
            public typealias ToOne<S: Entity, D: Entity> = Temporary<Relationship<NotNull, S, Crush.ToOne<D>>>
            public typealias ToMany<S: Entity, D: Entity> = Temporary<Relationship<NotNull, S, Crush.ToMany<D>>>
            public typealias ToOrderedMany<S: Entity, D: Entity> = Temporary<Relationship<NotNull, S, Crush.ToOrderedMany<D>>>
        }

        public struct Value {
            public typealias Transform<T: NSCoding & FieldAttribute & Hashable> = Temporary<Attribute<NotNull, T>>
            public typealias Codable<T: CodableProperty> = Temporary<Attribute<NotNull, T>>
            public typealias Int16 = Temporary<Attribute<NotNull, Swift.Int16>>
            public typealias Int32 = Temporary<Attribute<NotNull, Swift.Int32>>
            public typealias Int64 = Temporary<Attribute<NotNull, Swift.Int64>>
            public typealias DecimalNumber = Temporary<Attribute<NotNull, NSDecimalNumber>>
            public typealias Double = Temporary<Attribute<NotNull, Swift.Double>>
            public typealias Float = Temporary<Attribute<NotNull, Swift.Float>>
            public typealias String = Temporary<Attribute<NotNull, Swift.String>>
            public typealias Bool = Temporary<Attribute<NotNull, Swift.Bool>>
            public typealias Date = Temporary<Attribute<NotNull, Foundation.Date>>
            public typealias Data = Temporary<Attribute<NotNull, Foundation.Data>>
            public typealias UUID = Temporary<Attribute<NotNull, Foundation.UUID>>
            public typealias Enum<E: Enumerator> = Temporary<Attribute<NotNull, E>>
        }
    }
}
