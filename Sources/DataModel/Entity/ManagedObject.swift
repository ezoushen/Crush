//
//  ManagedObject.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/27.
//

import CoreData

public protocol RuntimeObject {
    associatedtype Entity: Crush.Entity
}

@dynamicMemberLookup
public class ManagedObject<T: Crush.Entity>: NSManagedObject, RuntimeObject {
    public typealias Entity = T
    
    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<T, Property>
    ) -> MutableSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToMany<Property.Destination>
    {
        let property = T.init()[keyPath: keyPath]
        let key = property.name
        let mutableSet = getMutableSet(key: key)
        return Property.Mapping.convert(value: mutableSet)
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<T, Property>
    ) -> MutableOrderedSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToOrderedMany<Property.Destination>
    {
        let property = T.init()[keyPath: keyPath]
        let key = property.name
        let mutableOrderedSet = getMutableOrderedSet(key: key)
        return Property.Mapping.convert(value: mutableOrderedSet)
    }

    public subscript<Property: ValuedProperty>(
        dynamicMember keyPath: KeyPath<T, Property>
    ) -> Property.PropertyValue {
        get {
            return self[immutable: keyPath]
        }
        set {
            let property = T.init()[keyPath: keyPath]
            setValue(Property.FieldConvertor.convert(value: newValue), key: property.name)
        }
    }

    public subscript<Property: ValuedProperty>(
        immutable keyPath: KeyPath<T, Property>
    ) -> Property.PropertyValue {
        let property = T.init()[keyPath: keyPath]
        return Property.FieldConvertor.convert(
            value: getValue(key: property.name))
    }
}

extension NSManagedObject {
    @inline(__always)
    func getValue<T>(key: String) -> T {
        willAccessValue(forKey: key)
        defer {
            didAccessValue(forKey: key)
        }
        return primitiveValue(forKey: key) as! T
    }

    @inline(__always)
    func setValue(_ value: Any?, key: String) {
        let value = value.isNil ? nil : value
        willChangeValue(forKey: key)
        defer {
            didChangeValue(forKey: key)
        }
        setPrimitiveValue(value, forKey: key)
    }

    func getMutableSet(key: String) -> NSMutableSet {
        willAccessValue(forKey: key)
        defer {
            didAccessValue(forKey: key)
        }
        return mutableSetValue(forKey: key)
    }

    func getMutableOrderedSet(key: String) -> NSMutableOrderedSet {
        willAccessValue(forKey: key)
        defer {
            didAccessValue(forKey: key)
        }
        return mutableOrderedSetValue(forKey: key)
    }
}

extension Entity {
    public typealias ManagedObject = Crush.ManagedObject<Self>
}
