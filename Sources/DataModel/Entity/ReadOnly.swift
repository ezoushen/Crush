//
//  ReadOnly.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/5/6.
//

import CoreData

protocol ReadOnlyObjectProxy: ObjectProxy {
    associatedtype Driver: DriverBase<Entity>
    var driver: Driver { get }
}

extension ReadOnlyObjectProxy {

}

@dynamicMemberLookup
public struct ReadOnly<T: Crush.Entity>: ReadOnlyObjectProxy {
    @dynamicMemberLookup
    public struct Raw: ReadOnlyObjectProxy {
        public typealias Driver = ManagedRawDriver<T>
        public typealias Entity = T

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

        public subscript<T: AttributeProtocol>(
            dynamicMember keyPath: KeyPath<Entity, T>) -> T.ManagedValue
        {
            context.performSync { driver[rawValue: keyPath] }
        }

        public subscript<T: RelationshipProtocol>(
            dynamicMember keyPath: KeyPath<Entity, T>
        ) -> T.RuntimeValue.Safe
        where
            T.RuntimeValue: UnsafeSessionProperty
        {
            context.performSync { driver[value: keyPath].wrapped() }
        }
    }

    public typealias Entity = T
    public typealias Driver = ManagedDriver<T>
    
    internal var managedObject: NSManagedObject { driver.managedObject }
    internal let driver: ManagedDriver<Entity>
    internal let context: NSManagedObjectContext

    public var raw: ReadOnly<T>.Raw {
        Raw(driver: driver.rawDriver())
    }
    
    public init(_ value: ManagedObject<Entity>) {
        self.init(driver: value.driver())
    }
    
    internal init(object: NSManagedObject) {
        self.init(driver: object.unsafeDriver(entity: Entity.self))
    }
    
    internal init(driver: ManagedDriver<Entity>) {
        guard let context = driver.managedObject.managedObjectContext else {
            fatalError("Accessing stale object is dangerous")
        }
        self.driver = driver
        self.context = context
    }

    public func access<T: Property>(
        keyPath: KeyPath<Entity, T>) -> T.RuntimeValue
    {
        context.performSync { driver[value: keyPath] }
    }

    public subscript<T: Property>(
        dynamicMember keyPath: KeyPath<Entity, T>) -> T.RuntimeValue
    {
        access(keyPath: keyPath)
    }

    public subscript<T: Property>(
        dynamicMember keyPath: KeyPath<Entity, T>
    ) -> T.RuntimeValue.Safe
    where
        T.RuntimeValue: UnsafeSessionProperty
    {
        context.performSync { driver[value: keyPath].wrapped() }
    }
}

extension ReadOnly: ManagedStatus {
    public var propertyHashValue: Int {
        managedObject.propertyHashValue
    }

    public var isInaccessible: Bool {
        managedObject.managedObjectContext == nil
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<NSManagedObject, T>) -> T {
        managedObject[keyPath: keyPath]
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<ManagedDriver<Entity>, T>) -> T {
        driver[keyPath: keyPath]
    }

    public func hasFault<T: RelationshipProtocol>(
        forRelationship keyPath: KeyPath<Entity, T>) -> Bool
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

public protocol ReadaleObject { }

extension Entity: ReadaleObject { }

extension ReadaleObject where Self: Entity {
    public typealias ReadOnly = Crush.ReadOnly<Self>
}

#if canImport(Combine)
import Combine

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public final class ObservableReadOnly<Entity: Crush.Entity>: ObservableObject {

    internal let readOnly: ReadOnly<Entity>
    internal var cancellable: AnyCancellable!

    internal init(_ readOnly: ReadOnly<Entity>) {
        self.readOnly = readOnly
        self.cancellable = readOnly.managedObject
            .objectWillChange
            .sink { [unowned self] in objectWillChange.send() }
    }

    public subscript<T: Property>(
        dynamicMember keyPath: KeyPath<Entity, T>) -> T.RuntimeValue
    {
        readOnly.access(keyPath: keyPath)
    }

    public subscript<T: Property>(
        dynamicMember keyPath: KeyPath<Entity, T>
    ) -> T.RuntimeValue.Safe
    where
        T.RuntimeValue: UnsafeSessionProperty
    {
        readOnly[dynamicMember: keyPath]
    }
}
#endif
