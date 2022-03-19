//
//  ManagedDriver.swift
//  
//
//  Created by ezou on 2021/10/24.
//

import CoreData
import Foundation

@dynamicMemberLookup
public protocol ObjectDriver: AnyObject {
    associatedtype Entity: Crush.Entity
    var managedObject: NSManagedObject { get }
}

extension ObjectDriver {
    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> MutableSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToMany<Property.Destination>
    {
        let key = keyPath.propertyName
        let mutableSet = managedObject.getMutableSet(key: key)
        return Property.Mapping.convert(value: mutableSet)
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> MutableOrderedSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToOrdered<Property.Destination>
    {
        let key = keyPath.propertyName
        let mutableOrderedSet = managedObject.getMutableOrderedSet(key: key)
        return Property.Mapping.convert(value: mutableOrderedSet)
    }

    public subscript<Property: ValuedProperty>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.PropertyValue {
        self[immutable: keyPath]
    }

    public subscript<Property: WritableValuedProperty>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.PropertyValue {
        get {
            self[immutable: keyPath]
        }
        set {
            managedObject.setValue(
                Property.FieldConvertor.convert(value: newValue),
                key: keyPath.propertyName)
        }
    }

    internal subscript<Property: ValuedProperty>(
        immutable keyPath: KeyPath<Entity, Property>
    ) -> Property.PropertyValue {
        guard let managedValue: Property.FieldConvertor.ManagedObjectValue =
                managedObject.getValue(key: keyPath.propertyName) else {
            return Property.FieldConvertor.defaultRuntimeValue
        }
        return Property.FieldConvertor.convert(value: managedValue)
    }

    public subscript<Value>(
        dynamicMember keyPath: KeyPath<NSManagedObject, Value>) -> Value
    {
        managedObject[keyPath: keyPath]
    }
}

extension NSManagedObject {
    @inlinable
    internal func getValue<T>(key: String) -> T? {
        willAccessValue(forKey: key)
        defer {
            didAccessValue(forKey: key)
        }
        return primitiveValue(forKey: key) as? T
    }

    @inlinable
    internal func setValue(_ value: Any?, key: String) {
        willChangeValue(forKey: key)
        defer {
            didChangeValue(forKey: key)
        }
        value.isNil
        ? setNilValueForKey(key)
        : setPrimitiveValue(value, forKey: key)
    }

    @inlinable
    internal func getMutableSet(key: String) -> NSMutableSet {
        willAccessValue(forKey: key)
        defer {
            didAccessValue(forKey: key)
        }
        return mutableSetValue(forKey: key)
    }

    @inlinable
    internal func getMutableOrderedSet(key: String) -> NSMutableOrderedSet {
        willAccessValue(forKey: key)
        defer {
            didAccessValue(forKey: key)
        }
        return mutableOrderedSetValue(forKey: key)
    }
}

public class ManagedDriver<Entity: Crush.Entity>: ObjectDriver, ManagedStatus {

    public let managedObject: NSManagedObject

    public init?(_ managedObject: NSManagedObject) {
        guard let type = managedObject.entity.entityType,
              type is Entity.Type else { return nil }
        self.managedObject = managedObject
    }

    public init(unsafe managedObject: NSManagedObject) {
        self.managedObject = managedObject
    }
}

extension NSManagedObject {
    public func driver<T: Entity>(entity: T.Type) -> ManagedDriver<T>? {
        ManagedDriver(self)
    }

    public func unsafeDriver<T: Entity>(entity: T.Type) -> ManagedDriver<T> {
        ManagedDriver(unsafe: self)
    }
}
