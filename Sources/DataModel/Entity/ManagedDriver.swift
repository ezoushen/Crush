//
//  ManagedDriver.swift
//  
//
//  Created by ezou on 2021/10/24.
//

import CoreData
import Foundation

public protocol ObjectDriver<Entity>: AnyObject {
    associatedtype Entity: Crush.Entity
    
    var managedObject: NSManagedObject { get }
    func driver() -> Entity.Driver
    func rawDriver() -> Entity.RawDriver
}

extension ObjectDriver {
    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> MutableSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToMany<Property.Destination>
    {
        self[toMany: keyPath]
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: WritableKeyPath<Entity, Property>
    ) -> MutableSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToMany<Property.Destination>
    {
        get {
            self[toMany: keyPath]
        }
        set {
            self[toMany: keyPath] = newValue
        }
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> MutableOrderedSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToOrdered<Property.Destination>
    {
        self[toManyOrdered: keyPath]
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: WritableKeyPath<Entity, Property>
    ) -> MutableOrderedSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToOrdered<Property.Destination>
    {
        get {
            self[toManyOrdered: keyPath]
        }
        set {
            self[toManyOrdered: keyPath] = newValue
        }
    }

    public subscript<Value>(
        dynamicMember keyPath: KeyPath<NSManagedObject, Value>) -> Value
    {
        managedObject[keyPath: keyPath]
    }

    internal subscript<Property: RelationshipProtocol>(
        toMany keyPath: KeyPath<Entity, Property>
    ) -> MutableSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToMany<Property.Destination>
    {
        get {
            let key = keyPath.propertyName
            let mutableSet = managedObject.getMutableSet(key: key)
            return Property.Mapping.convert(managedValue: mutableSet)
        }
        set {
            managedObject.setValue(
                Property.PropertyType.convert(runtimeValue: newValue),
                key: keyPath.propertyName)
        }
    }

    internal subscript<Property: RelationshipProtocol>(
        toManyOrdered keyPath: KeyPath<Entity, Property>
    ) -> MutableOrderedSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToOrdered<Property.Destination>
    {
        get {
            let key = keyPath.propertyName
            let mutableOrderedSet = managedObject.getMutableOrderedSet(key: key)
            return Property.Mapping.convert(managedValue: mutableOrderedSet)
        }
        set {
            managedObject.setValue(
                Property.PropertyType.convert(runtimeValue: newValue),
                key: keyPath.propertyName)
        }
    }

    internal subscript<Property: Crush.Property>(
        value keyPath: KeyPath<Entity, Property>
    ) -> Property.RuntimeValue {
        guard let managedValue: Property.PropertyType.ManagedValue =
                managedObject.getValue(key: keyPath.propertyName) else {
            return Property.PropertyType.defaultRuntimeValue
        }
        return Property.PropertyType.convert(managedValue: managedValue)
    }
}

@dynamicMemberLookup
public protocol ObjectRuntimeDriver<Entity>: ObjectDriver { }

extension ObjectRuntimeDriver {
    public subscript<Property: Crush.Property>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.RuntimeValue {
        self[value: keyPath]
    }

    public subscript<Property: FetchedPropertyProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.RuntimeValue {
        NSManagedObject.$currentFetchSource.withValue(managedObject) {
            self[value: keyPath]
        }
    }

    public subscript<Property: WritableProperty>(
        dynamicMember keyPath: WritableKeyPath<Entity, Property>
    ) -> Property.RuntimeValue {
        get {
            self[value: keyPath]
        }
        set {
            managedObject.setValue(
                Property.PropertyType.convert(runtimeValue: newValue),
                key: keyPath.propertyName)
        }
    }
}

@dynamicMemberLookup
public protocol ObjectRawDriver: ObjectDriver { }

extension ObjectRawDriver {
    public subscript<Property: FetchedPropertyProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.ManagedValue {
        NSManagedObject.$currentFetchSource.withValue(managedObject) {
            self[rawValue: keyPath]
        }
    }

    public subscript<Property: AttributeProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.ManagedValue {
        self[rawValue: keyPath]
    }

    public subscript<Property: AttributeProtocol>(
        dynamicMember keyPath: WritableKeyPath<Entity, Property>
    ) -> Property.ManagedValue {
        get {
            self[rawValue: keyPath]
        }
        set {
            managedObject.setValue(newValue, key: keyPath.propertyName)
        }
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.RuntimeValue {
        self[value: keyPath]
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: WritableKeyPath<Entity, Property>
    ) -> Property.RuntimeValue {
        get {
            self[value: keyPath]
        }
        set {
            managedObject.setValue(
                Property.PropertyType.convert(runtimeValue: newValue),
                key: keyPath.propertyName)
        }
    }

    internal subscript<Property: Crush.Property>(
        rawValue keyPath: KeyPath<Entity, Property>
    ) -> Property.ManagedValue {
        guard let managedValue: Property.PropertyType.ManagedValue =
                managedObject.getValue(key: keyPath.propertyName) else {
            return Property.PropertyType.defaultManagedValue
        }
        return managedValue
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

public class DriverBase<Entity: Crush.Entity>: ObjectDriver {
    public let managedObject: NSManagedObject

    public init?(_ managedObject: NSManagedObject) {
        guard let type = managedObject.entity.entityType,
              type is Entity.Type else { return nil }
        self.managedObject = managedObject
    }

    public init(unsafe managedObject: NSManagedObject) {
        self.managedObject = managedObject
    }

    public func unwrap<T: Crush.Entity>(_ type: T.Type) -> T.Managed {
        managedObject as! T.Managed
    }

    @inlinable public func driver() -> Entity.Driver {
        ManagedDriver(unsafe: managedObject)
    }

    @inlinable public func rawDriver() -> Entity.RawDriver {
        ManagedRawDriver(unsafe: managedObject)
    }
}

/// Access `NSManagedObject` data flexibly, especially when dealing with inheritance relationships.
///
/// This class provides a convenient way to access data in lifecycle functions, such as ``Entity/willSave(_:)``,
/// when you have entities with inheritance relationships. It can be particularly useful when attempting to access data as a parent class.
///  Consider the following example with three entity types: `Animal`, `Dog`, and `Cat`.
///
/// ```swift
/// class Animal: Entity {
///   @Optional
///   var activeDate = Value.Date("activeDate")
///
///   override func willSave(_ managedObject: NSManagedObject) {
///     // You cannot perform the following cast directly, as it may cause a crash.
///     // `let animal = managedObject as! ManagedObject<Animal>`
///
///     // Instead, use `ManagedDriver` to safely access the data.
///     guard let animal = ManagedDriver<Animal>(managedObject) else {
///       return
///     }
///     animal.activeDate = Date()
///   }
/// }
///
/// class Dog: Animal { }
/// class Cat: Animal { }
/// ```
///
/// ## See Also
/// - ``ManagedObject``
/// - ``ManagedRawDriver``
public class ManagedDriver<Entity: Crush.Entity>: DriverBase<Entity>, ObjectRuntimeDriver, ManagedStatus {
    @inlinable public override func driver() -> Entity.Driver {
        self
    }
}

/// Like ``ManagedDriver``, but you can access raw data directly from `NSManagedObject` by this class.
///
/// Use this class for performance-sensitive code to avoid data wrapping and access read/write data directly.
///
/// Example:
///
/// ```swift
/// enum Size: Int16, EnumerableAttributeType {
///   case small, medium, large
/// }
///
/// class MyEntity: Entity {
///   @Default(.small)
///   var size = Value.Enum<Size>("size")
/// }
/// let rawDriver = managedObject.rawDriver()
/// print(rawDriver.size) // prints 0, not .small
/// ```
///
public class ManagedRawDriver<Entity: Crush.Entity>: DriverBase<Entity>, ObjectRawDriver {
    @inlinable public override func rawDriver() -> Entity.RawDriver {
        self
    }
}

extension NSManagedObject {
    @inlinable public func runtimeDriver<T: Entity>(entity: T.Type) -> ManagedDriver<T>? {
        ManagedDriver(self)
    }

    @inlinable public func unsafeDriver<T: Entity>(entity: T.Type) -> ManagedDriver<T> {
        ManagedDriver(unsafe: self)
    }

    @inlinable public func rawDriver<T: Entity>(entity: T.Type) -> ManagedRawDriver<T>? {
        ManagedRawDriver(self)
    }

    @inlinable public func unsafeRawDriver<T: Entity>(entity: T.Type) -> ManagedRawDriver<T> {
        ManagedRawDriver(unsafe: self)
    }
}
