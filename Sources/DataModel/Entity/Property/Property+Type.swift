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
    public enum Transient {
        public enum Relation {
            public typealias ToOne<S: Entity, D: Entity> = Relationship<Nullable, S, Crush.ToOne<D>, Crush.Transient>
            public typealias ToMany<S: Entity, D: Entity> = Relationship<Nullable, S, Crush.ToMany<D>, Crush.Transient>
            public typealias ToOrderedMany<S: Entity, D: Entity> = Relationship<Nullable, S, Crush.ToOrderedMany<D>, Crush.Transient>
        }

        public enum Value {
            public typealias Transform<T: NSCoding & FieldAttribute & Hashable> = Attribute<Nullable, T, Crush.Transient>
            public typealias Codable<T: CodableProperty> = Attribute<Nullable, T, Crush.Transient>
            public typealias Int16 = Attribute<Nullable, Swift.Int16, Crush.Transient>
            public typealias Int32 = Attribute<Nullable, Swift.Int32, Crush.Transient>
            public typealias Int64 = Attribute<Nullable, Swift.Int64, Crush.Transient>
            public typealias DecimalNumber = Attribute<Nullable, NSDecimalNumber, Crush.Transient>
            public typealias Double = Attribute<Nullable, Swift.Double, Crush.Transient>
            public typealias Float = Attribute<Nullable, Swift.Float, Crush.Transient>
            public typealias String = Attribute<Nullable, Swift.String, Crush.Transient>
            public typealias Bool = Attribute<Nullable, Swift.Bool, Crush.Transient>
            public typealias Date = Attribute<Nullable, Foundation.Date, Crush.Transient>
            public typealias Data = Attribute<Nullable, Foundation.Data, Crush.Transient>
            public typealias UUID = Attribute<Nullable, Foundation.UUID, Crush.Transient>
            public typealias Enum<E: Enumerator> = Attribute<Nullable, E, Crush.Transient>
        }
    }

    public enum Relation {
        public typealias ToOne<S: Entity, D: Entity> = Relationship<Nullable, S, Crush.ToOne<D>, NonTransient>
        public typealias ToMany<S: Entity, D: Entity> = Relationship<Nullable, S, Crush.ToMany<D>, NonTransient>
        public typealias ToOrderedMany<S: Entity, D: Entity> = Relationship<Nullable, S, Crush.ToOrderedMany<D>, NonTransient>
    }

    public enum Value {
        public typealias Transform<T: NSCoding & FieldAttribute & Hashable> = Attribute<Nullable, T, NonTransient>
        public typealias Codable<T: CodableProperty> = Attribute<Nullable, T, NonTransient>
        public typealias Int16 = Attribute<Nullable, Swift.Int16, NonTransient>
        public typealias Int32 = Attribute<Nullable, Swift.Int32, NonTransient>
        public typealias Int64 = Attribute<Nullable, Swift.Int64, NonTransient>
        public typealias DecimalNumber = Attribute<Nullable, NSDecimalNumber, NonTransient>
        public typealias Double = Attribute<Nullable, Swift.Double, NonTransient>
        public typealias Float = Attribute<Nullable, Swift.Float, NonTransient>
        public typealias String = Attribute<Nullable, Swift.String, NonTransient>
        public typealias Bool = Attribute<Nullable, Swift.Bool, NonTransient>
        public typealias Date = Attribute<Nullable, Foundation.Date, NonTransient>
        public typealias Data = Attribute<Nullable, Foundation.Data, NonTransient>
        public typealias UUID = Attribute<Nullable, Foundation.UUID, NonTransient>
        public typealias Enum<E: Enumerator> = Attribute<Nullable, E, NonTransient>
    }
}

public enum Required {
    public enum Transient {
        public enum Relation {
            public typealias ToOne<S: Entity, D: Entity> = Relationship<NotNull, S, Crush.ToOne<D>, Crush.Transient>
            public typealias ToMany<S: Entity, D: Entity> = Relationship<NotNull, S, Crush.ToMany<D>, Crush.Transient>
            public typealias ToOrderedMany<S: Entity, D: Entity> = Relationship<NotNull, S, Crush.ToOrderedMany<D>, Crush.Transient>
        }

        public enum Value {
            public typealias Transform<T: NSCoding & FieldAttribute & Hashable> = Attribute<NotNull, T, Crush.Transient>
            public typealias Codable<T: CodableProperty> = Attribute<NotNull, T, Crush.Transient>
            public typealias Int16 = Attribute<NotNull, Swift.Int16, Crush.Transient>
            public typealias Int32 = Attribute<NotNull, Swift.Int32, Crush.Transient>
            public typealias Int64 = Attribute<NotNull, Swift.Int64, Crush.Transient>
            public typealias DecimalNumber = Attribute<NotNull, NSDecimalNumber, Crush.Transient>
            public typealias Double = Attribute<NotNull, Swift.Double, Crush.Transient>
            public typealias Float = Attribute<NotNull, Swift.Float, Crush.Transient>
            public typealias String = Attribute<NotNull, Swift.String, Crush.Transient>
            public typealias Bool = Attribute<NotNull, Swift.Bool, Crush.Transient>
            public typealias Date = Attribute<NotNull, Foundation.Date, Crush.Transient>
            public typealias Data = Attribute<NotNull, Foundation.Data, Crush.Transient>
            public typealias UUID = Attribute<NotNull, Foundation.UUID, Crush.Transient>
            public typealias Enum<E: Enumerator> = Attribute<NotNull, E, Crush.Transient>
        }
    }

    public enum Relation {
        public typealias ToOne<S: Entity, D: Entity> = Relationship<NotNull, S, Crush.ToOne<D>, NonTransient>
        public typealias ToMany<S: Entity, D: Entity> = Relationship<NotNull, S, Crush.ToMany<D>, NonTransient>
        public typealias ToOrderedMany<S: Entity, D: Entity> = Relationship<NotNull, S, Crush.ToOrderedMany<D>, NonTransient>
    }

    public enum Value {
        public typealias Transform<T: NSCoding & FieldAttribute & Hashable> = Attribute<NotNull, T, NonTransient>
        public typealias Codable<T: CodableProperty> = Attribute<NotNull, T, NonTransient>
        public typealias Int16 = Attribute<NotNull, Swift.Int16, NonTransient>
        public typealias Int32 = Attribute<NotNull, Swift.Int32, NonTransient>
        public typealias Int64 = Attribute<NotNull, Swift.Int64, NonTransient>
        public typealias DecimalNumber = Attribute<NotNull, NSDecimalNumber, NonTransient>
        public typealias Double = Attribute<NotNull, Swift.Double, NonTransient>
        public typealias Float = Attribute<NotNull, Swift.Float, NonTransient>
        public typealias String = Attribute<NotNull, Swift.String, NonTransient>
        public typealias Bool = Attribute<NotNull, Swift.Bool, NonTransient>
        public typealias Date = Attribute<NotNull, Foundation.Date, NonTransient>
        public typealias Data = Attribute<NotNull, Foundation.Data, NonTransient>
        public typealias UUID = Attribute<NotNull, Foundation.UUID, NonTransient>
        public typealias Enum<E: Enumerator> = Attribute<NotNull, E, NonTransient>
    }
}
