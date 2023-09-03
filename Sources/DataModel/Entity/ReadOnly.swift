//
//  ReadOnly.swift
//  Crush
//
//  Created by EZOU on 2020/5/6.
//

import CoreData

/// A class responsible for thread-safe data access of the managed object.
///
/// It is used to safely read data from the managed object without worrying about concurrency issues. Besides properties defined in
/// `Entity`, you can access all other instance properties of `NSManagedObject` in read-only mode. Moreover, it guarantees
/// that all data access would be executed on the same given thread.
///
/// - Note: You should only use `ReadOnly` objects when you need to access the data outside of a `Session`'s callback block .
/// 
/// Example:
///
///     var readOnlyEntity: ReadOnly<Entity> = ...
///     let property = readOnlyEntity.property // ✅ OK!!
///     readOnlyEntity.property = newValue // ❌ Compiler error!!
///
@dynamicMemberLookup
public struct ReadOnly<Entity: Crush.Entity> {
    /// This struct is used to access the raw data of the `ReadOnly` object. It's useful especially while you're
    /// trying to read the wrapper property and get the underlying value for multiple times
    ///
    /// Example:
    ///
    ///     /*
    ///     enum TodoStatus: Int16, EnumerableAttributeType {
    ///         typealias RawAttributeType = Int16AttributeType
    ///         case finished, undone
    ///     }
    ///     */
    ///     print(todo.status)     // TodoStatus.undone
    ///     print(todo.raw.status) // 0
    @dynamicMemberLookup
    public struct Raw {
        public typealias Driver = Entity.RawDriver

        internal var managedObject: NSManagedObject { driver.managedObject }
        internal let driver: Driver
        internal let context: NSManagedObjectContext

        internal init(driver: Driver) {
            guard let context = driver.managedObject.managedObjectContext else {
                fatalError("Accessing stale object is dangerous")
            }
            self.driver = driver
            self.context = context
        }

        /// Refresh the `managedObject` to keep it up to date
        public func refresh(mergeChanges flag: Bool = true) {
            context.performSync { context.refresh(managedObject, mergeChanges: flag) }
        }

        /// Read the attribute from the `managedObject` through dynamic callable api
        public subscript<Attribute: AttributeProtocol>(
            dynamicMember keyPath: KeyPath<Entity, Attribute>) -> Attribute.ManagedValue
        {
            context.performSync { driver[rawValue: keyPath] }
        }

        /// Read the relationship from the `managedObject` through dynamic callable api
        public subscript<Relationship: RelationshipProtocol>(
            dynamicMember keyPath: KeyPath<Entity, Relationship>
        ) -> Relationship.RuntimeValue.Safe
        where
            Relationship.RuntimeValue: UnsafeSessionProperty
        {
            context.performSync { driver[value: keyPath].wrapped() }
        }

        /// Read the fetched property from the `managedObject` through dynamic callable api
        public subscript<Relationship: FetchedPropertyProtocol>(
            dynamicMember keyPath: KeyPath<Entity, Relationship>) -> Relationship.RuntimeValue
        {
            context.performSync {
                NSManagedObject.$currentFetchSource.withValue(managedObject) {
                    driver[value: keyPath]
                }
            }
        }
    }

    public typealias Driver = Entity.Driver

    internal var managedObject: NSManagedObject { driver.managedObject }
    internal let driver: Entity.Driver
    internal let context: NSManagedObjectContext

    /// Wrap the `ReadOnly` object to `ReadOnly.Raw`
    public var raw: ReadOnly<Entity>.Raw {
        Raw(driver: driver.rawDriver())
    }
    
    internal init(object: NSManagedObject) {
        self.init(object.unsafeCast(to: Entity.self))
    }
    
    public init(_ driver: Entity.Driver) {
        guard let context = driver.managedObject.managedObjectContext else {
            fatalError("Accessing stale object is dangerous")
        }
        self.driver = driver
        self.context = context
    }

    /// Access properties of the underlying `managedObject`
    public func access<Property: Crush.Property>(
        keyPath: KeyPath<Entity, Property>) -> Property.RuntimeValue
    {
        context.performSync { driver[value: keyPath] }
    }

    /// Access properties of the underlying `managedObject`
    public subscript<Property: Crush.Property>(
        dynamicMember keyPath: KeyPath<Entity, Property>) -> Property.RuntimeValue
    {
        access(keyPath: keyPath)
    }

    /// Access the fetched property of the underlying `managedObject`.
    public subscript<FetchedProperty: FetchedPropertyProtocol>(
        dynamicMember keyPath: KeyPath<Entity, FetchedProperty>) -> FetchedProperty.RuntimeValue
    {
        context.performSync {
            NSManagedObject.$currentFetchSource.withValue(managedObject) {
                driver[value: keyPath]
            }
        }
    }

    /// Access properties of the underlying `managedObject`
    public subscript<Property: Crush.Property>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.RuntimeValue.Safe
    where
        Property.RuntimeValue: UnsafeSessionProperty
    {
        context.performSync { driver[value: keyPath].wrapped() }
    }
}

extension ReadOnly {
    /// Check is the underlying object stale
    public var isInaccessible: Bool {
        managedObject.managedObjectContext == nil
    }

    /// Read properties of `NSManagedObject` through dyncmic callable API.
    public subscript<T>(dynamicMember keyPath: KeyPath<NSManagedObject, T>) -> T {
        managedObject[keyPath: keyPath]
    }

    /// Read properties of `Entity.Driver` through dyncmic callable API.
    public subscript<T>(dynamicMember keyPath: KeyPath<Entity.Driver, T>) -> T {
        driver[keyPath: keyPath]
    }
}

extension ReadOnly: ManagedStatus {
    public var propertyHashValue: Int {
        managedObject.propertyHashValue
    }

    public func hasFault<Relationship: RelationshipProtocol>(
        forRelationship keyPath: KeyPath<Entity, Relationship>) -> Bool
    {
        managedObject.hasFault(forRelationshipNamed: keyPath.propertyName)
    }

    public func changedValues() -> [String: Any] {
        context.performSync { managedObject.changedValues() }
    }

    public func changedValuesForCurrentEvent() -> [String: Any] {
        context.performSync { managedObject.changedValuesForCurrentEvent() }
    }

    public func commitedValues(forKeys keys: [String]?) -> [String: Any] {
        context.performSync { managedObject.committedValues(forKeys: keys) }
    }
    
    public func refresh(mergeChanges flag: Bool = true) {
        context.refresh(managedObject, mergeChanges: flag)
    }
}

extension ReadOnly: Equatable {
    public static func == (lhs: ReadOnly, rhs: ReadOnly) -> Bool {
        lhs.managedObject == rhs.managedObject
    }
}

extension ReadOnly: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(managedObject)
    }
}

extension ReadOnly {
    public func cast<T: Crush.Entity>(to type: T.Type) -> T.ReadOnly? {
        guard let driver = managedObject.cast(to: type) else { return nil }
        return T.ReadOnly(driver)
    }
    
    public func unsafeCast<T: Crush.Entity>(to type: T.Type) -> T.ReadOnly {
        T.ReadOnly(object: managedObject)
    }
}

@inlinable public func => <T: Crush.Entity, S: Crush.Entity>(lhs: S.ReadOnly, rhs: T.Type) -> T.ReadOnly {
    lhs.unsafeCast(to: rhs)
}

@inlinable public func => <T: Crush.Entity, S: Crush.Entity>(lhs: S.ReadOnly?, rhs: T.Type) -> T.ReadOnly? {
    lhs?.unsafeCast(to: rhs)
}

@inlinable public func ~> <T: Crush.Entity, S: Crush.Entity>(lhs: S.ReadOnly?, rhs: T.Type) -> T.ReadOnly? {
    lhs?.cast(to: rhs)
}

public protocol ReadaleObject { }

extension Entity: ReadaleObject { }

extension ReadaleObject where Self: Entity {
    public typealias ReadOnly = Crush.ReadOnly<Self>
}

#if canImport(Combine)
import Combine

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
@propertyWrapper
public final class ObservableEntity<Entity: Crush.Entity>: ObservableObject {
    public var wrappedValue: ReadOnly<Entity> {
        readOnly
    }

    internal let readOnly: ReadOnly<Entity>
    internal var cancellable: AnyCancellable!

    public init(wrappedValue readOnly: ReadOnly<Entity>) {
        self.readOnly = readOnly
        self.cancellable = readOnly.managedObject
            .objectWillChange
            .sink { [unowned self] in objectWillChange.send() }
    }
}
#endif
