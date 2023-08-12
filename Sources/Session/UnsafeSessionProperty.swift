//
//  UnsafeSessionProperty.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import Combine
import Foundation

public protocol UnsafeSessionPropertyProtocol { }

public protocol UnsafeSessionProperty: UnsafeSessionPropertyProtocol {
    associatedtype Entity: Crush.Entity
    associatedtype Safe
    func wrapped(in session: Session?) -> Safe
}

extension UnsafeSessionProperty {
    public func wrapped() -> Safe { wrapped(in: nil) }

    public func wrap<T: ObjectDriver>(
        object: T, in session: Session?) -> ReadOnly<Entity> where T.Entity == Entity
    {
        guard let session = session else {
            return ReadOnly(driver: object.driver())
        }
        return ReadOnly<T.Entity>(object: session.context.present(object.managedObject))
    }
}

extension MutableSet: UnsafeSessionPropertyProtocol where Element: ObjectDriver { }
extension MutableSet: UnsafeSessionProperty where Element: ObjectDriver {
    public typealias Entity = Element.Entity
    public typealias Safe = Set<Entity.ReadOnly>

    public func wrapped(in session: Session?) -> Set<Entity.ReadOnly> {
        if let moc = first?.managedObject.managedObjectContext,
           session != nil && session?.context.uiContext != moc
       {
            try? moc.obtainPermanentIDs(for: map { $0.managedObject })
        }
        return Set(map { wrap(object: $0, in: session) })
    }
}

extension MutableOrderedSet: UnsafeSessionPropertyProtocol where Element: ObjectDriver { }
extension MutableOrderedSet: UnsafeSessionProperty where Element: ObjectDriver {
    public typealias Entity = Element.Entity
    public typealias Safe = OrderedSet<Entity.ReadOnly>

    public func wrapped(in session: Session?) -> OrderedSet<Entity.ReadOnly> {
        if let moc = first?.managedObject.managedObjectContext,
           session != nil && session?.context.uiContext != moc
        {
            try? moc.obtainPermanentIDs(for: map { $0.managedObject })
        }
        return OrderedSet(map { wrap(object: $0, in: session) })
    }
}

extension Array: UnsafeSessionPropertyProtocol where Element: ObjectDriver { }
extension Array: UnsafeSessionProperty where Element: ObjectDriver {
    public typealias Entity = Element.Entity
    public typealias Safe = Array<Entity.ReadOnly>

    public func wrapped(in session: Session?) -> Array<Entity.ReadOnly> {
        if let moc = first?.managedObject.managedObjectContext,
           session != nil && session?.context.uiContext != moc
        {
            try? moc.obtainPermanentIDs(for: map { $0.managedObject })
        }
        return map { wrap(object: $0, in: session) }
    }
}

extension Set: UnsafeSessionPropertyProtocol where Element: ObjectDriver { }
extension Set: UnsafeSessionProperty where Element: ObjectDriver {
    public typealias Entity = Element.Entity
    public typealias Safe = Set<Entity.ReadOnly>

    public func wrapped(in session: Session?) -> Set<Entity.ReadOnly> {
        if let moc = first?.managedObject.managedObjectContext,
            session != nil && session?.context.uiContext != moc
        {
            try? moc.obtainPermanentIDs(for: map { $0.managedObject })
        }
        return Set<Entity.ReadOnly>(map { wrap(object: $0, in: session) })
    }
}

extension ReadOnly: UnsafeSessionPropertyProtocol { }
extension ReadOnly: UnsafeSessionProperty {
    public typealias Safe = ReadOnly<Entity>
    public func wrapped(in session: Session?) -> ReadOnly<Entity> {
        // Rewrap the object if its managedObjectContext is not ui context
        guard let session = session,
              session.context.uiContext !== context else { return self }
        try? context.obtainPermanentIDs(for: [managedObject])
        return ReadOnly(object: session.context.present(managedObject))
    }
}

extension Swift.Optional: UnsafeSessionPropertyProtocol where Wrapped: UnsafeSessionProperty { }
extension Swift.Optional: UnsafeSessionProperty where Wrapped: UnsafeSessionProperty {
    public typealias Entity = Wrapped.Entity
    public typealias Safe = Wrapped.Safe?

    public func wrapped(in session: Session?) -> Wrapped.Safe? {
        guard case .some(let value) = self else { return nil }
        return value.wrapped(in: session)
    }
}

extension ObjectDriver where Self: UnsafeSessionProperty {
    public typealias Safe = ReadOnly<Entity>
    public func wrapped(in session: Session?) -> ReadOnly<Entity> {
        if session != nil && session?.context.uiContext != managedObject.managedObjectContext {
            try? managedObject.managedObjectContext?.obtainPermanentIDs(for: [managedObject])
        }
        return wrap(object: self, in: session)
    }
}

extension ManagedObject: UnsafeSessionPropertyProtocol { }
extension ManagedObject: UnsafeSessionProperty { }

extension ManagedDriver: UnsafeSessionPropertyProtocol { }
extension ManagedDriver: UnsafeSessionProperty { }
