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
    func wrapped(in session: Session) -> Safe
}

extension MutableSet: UnsafeSessionPropertyProtocol where Element: RuntimeObject { }
extension MutableSet: UnsafeSessionProperty where Element: RuntimeObject {
    public typealias Entity = Element.Entity
    public typealias Safe = Set<Entity.ReadOnly>

    public func wrapped(in session: Session) -> Set<Entity.ReadOnly> {
        Set(self.map { session.present($0 as! ManagedObject<Entity>) })
    }
}

extension MutableOrderedSet: UnsafeSessionPropertyProtocol where Element: RuntimeObject { }
extension MutableOrderedSet: UnsafeSessionProperty where Element: RuntimeObject {
    public typealias Entity = Element.Entity
    public typealias Safe = OrderedSet<Entity.ReadOnly>

    public func wrapped(in session: Session) -> OrderedSet<Entity.ReadOnly> {
        OrderedSet(self.map { session.present($0 as! ManagedObject<Entity>) })
    }
}

extension Array: UnsafeSessionPropertyProtocol where Element: RuntimeObject { }
extension Array: UnsafeSessionProperty where Element: RuntimeObject {
    public typealias Entity = Element.Entity
    public typealias Safe = Array<Entity.ReadOnly>

    public func wrapped(in session: Session) -> Array<Entity.ReadOnly> {
        self.map { session.present($0 as! ManagedObject<Entity>) }
    }
}

extension Set: UnsafeSessionPropertyProtocol where Element: RuntimeObject { }
extension Set: UnsafeSessionProperty where Element: RuntimeObject {
    public typealias Entity = Element.Entity
    public typealias Safe = Set<Entity.ReadOnly>

    public func wrapped(in session: Session) -> Set<Entity.ReadOnly> {
        Set<Entity.ReadOnly>(map { session.present($0 as! ManagedObject<Entity>) })
    }
}

extension Swift.Optional: UnsafeSessionPropertyProtocol where Wrapped: UnsafeSessionPropertyProtocol { }
extension Swift.Optional: UnsafeSessionProperty where Wrapped: UnsafeSessionProperty {
    public typealias Entity = Wrapped.Entity
    public typealias Safe = Wrapped.Safe?
    public func wrapped(in session: Session) -> Wrapped.Safe? {
        guard case .some(let value) = self else { return nil }
        return value.wrapped(in: session)
    }
}

extension ManagedObject: UnsafeSessionProperty {
    public typealias Safe = ReadOnly<Entity>

    public func wrapped(in session: Session) -> ReadOnly<Entity> {
        session.present(self)
    }
}
