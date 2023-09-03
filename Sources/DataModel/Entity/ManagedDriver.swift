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
    internal subscript<Property: RelationshipProtocol>(
        toMany keyPath: KeyPath<Entity, Property>
    ) -> MutableSet<ManagedDriver<Property.Destination>>
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
    ) -> MutableOrderedSet<ManagedDriver<Property.Destination>>
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
    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> MutableSet<ManagedDriver<Property.Destination>>
    where
        Property.Mapping == ToMany<Property.Destination>
    {
        self[toMany: keyPath]
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: WritableKeyPath<Entity, Property>
    ) -> MutableSet<ManagedDriver<Property.Destination>>
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
    ) -> MutableOrderedSet<ManagedDriver<Property.Destination>>
    where
        Property.Mapping == ToOrdered<Property.Destination>
    {
        self[toManyOrdered: keyPath]
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: WritableKeyPath<Entity, Property>
    ) -> MutableOrderedSet<ManagedDriver<Property.Destination>>
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
    ) -> Property.ManagedValue {
        self[rawValue: keyPath]
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: WritableKeyPath<Entity, Property>
    ) -> Property.ManagedValue {
        get {
            self[rawValue: keyPath]
        }
        set {
            managedObject.setValue(newValue, key: keyPath.propertyName)
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

public class DriverBase<Entity: Crush.Entity>: ObjectDriver, Hashable, CustomDebugStringConvertible {
    public let managedObject: NSManagedObject
    
    public var debugDescription: String {
        managedObject.debugDescription
    }

    public init?(_ managedObject: NSManagedObject) {
        guard let type = managedObject.entity.entityType,
              type is Entity.Type else { return nil }
        self.managedObject = managedObject
    }
    
    public static func == (lhs: DriverBase<Entity>, rhs: DriverBase<Entity>) -> Bool {
        lhs.managedObject == rhs.managedObject
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(managedObject)
    }

    public init(unsafe managedObject: NSManagedObject) {
        self.managedObject = managedObject
    }

    @inlinable public func driver() -> Entity.Driver {
        ManagedDriver(unsafe: managedObject)
    }

    @inlinable public func rawDriver() -> Entity.RawDriver {
        ManagedRawDriver(unsafe: managedObject)
    }
    
    @inlinable public var raw: Entity.RawDriver {
        rawDriver()
    }
    
    func fireFault() {
        managedObject.fireFault()
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
///     // Use `ManagedDriver` to safely access the data.
///     // ~> is the operator that equals `runtimeDriver(type: Animal.self)`
///     guard let animal = managedObject ~> Animal.self else { return }
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
    
    /// Casts the managed driver to the specified entity type.
    @inlinable public func cast<T: Crush.Entity>(to type: T.Type) -> T.Driver? {
        T.Driver(managedObject)
    }

    /// Unsafely casts the managed driver to the specified entity type.
    @inlinable public func unsafeCast<T: Crush.Entity>(to entity: T.Type) -> T.Driver {
        T.Driver(unsafe: managedObject)
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
/// let rawDriver = driver.raw
/// print(rawDriver.size) // prints 0, not .small
/// ```
///
public class ManagedRawDriver<Entity: Crush.Entity>: DriverBase<Entity>, ObjectRawDriver {
    @inlinable public override func rawDriver() -> Entity.RawDriver {
        self
    }
    
    /// Casts the raw managed driver to the specified entity type.
    @inlinable public func cast<T: Crush.Entity>(to type: T.Type) -> T.RawDriver? {
        T.RawDriver(managedObject)
    }

    /// Unsafely casts the raw managed driver to the specified entity type.
    @inlinable public func unsafeCast<T: Crush.Entity>(to entity: T.Type) -> T.RawDriver {
        T.RawDriver(unsafe: managedObject)
    }
}

extension NSManagedObject {
    /// Casts the managed driver to the specified entity type.
    @inlinable public func cast<T: Entity>(to type: T.Type) -> T.Driver? {
        ManagedDriver(self)
    }

    /// Unsafely casts the managed driver to the specified entity type.
    @inlinable public func unsafeCast<T: Entity>(to type: T.Type) -> T.Driver {
        ManagedDriver(unsafe: self)
    }
}

infix operator =>
infix operator =>?

@inlinable public func => <T: Crush.Entity, S: Crush.Entity>(lhs: S.RawDriver, rhs: T.Type) -> T.RawDriver {
    lhs.unsafeCast(to: rhs)
}

@inlinable public func => <T: Crush.Entity, S: Crush.Entity>(lhs: S.Driver, rhs: T.Type) -> T.Driver {
    lhs.unsafeCast(to: rhs)
}

@inlinable public func => <T: Crush.Entity>(lhs: NSManagedObject, rhs: T.Type) -> T.Driver {
    lhs.unsafeCast(to: rhs)
}

@inlinable public func =>? <T: Crush.Entity, S: Crush.Entity>(lhs: S.RawDriver?, rhs: T.Type) -> T.RawDriver? {
    lhs?.unsafeCast(to: rhs)
}

@inlinable public func =>? <T: Crush.Entity, S: Crush.Entity>(lhs: S.Driver?, rhs: T.Type) -> T.Driver? {
    lhs?.unsafeCast(to: rhs)
}

@inlinable public func =>? <T: Crush.Entity>(lhs: NSManagedObject?, rhs: T.Type) -> T.Driver? {
    lhs?.unsafeCast(to: rhs)
}

infix operator ~>

@inlinable public func ~> <T: Crush.Entity, S: Crush.Entity>(lhs: S.Driver?, rhs: T.Type) -> T.Driver? {
    lhs?.cast(to: rhs)
}

@inlinable public func ~> <T: Crush.Entity, S: Crush.Entity>(lhs: S.RawDriver?, rhs: T.Type) -> T.RawDriver? {
    lhs?.cast(to: rhs)
}

@inlinable public func ~> <T: Crush.Entity>(lhs: NSManagedObject?, rhs: T.Type) -> T.Driver? {
    lhs?.cast(to: rhs)
}
