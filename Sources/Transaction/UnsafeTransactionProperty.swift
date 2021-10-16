//
//  UnsafeTransactionProperty.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import Combine
import Foundation

public protocol UnsafeTransactionPropertyProtocol { }

public protocol UnsafeTransactionProperty: UnsafeTransactionPropertyProtocol {
    associatedtype Entity: Crush.Entity
    associatedtype Safe
    func wrapped(in transaction: Transaction) -> Safe
}

extension MutableSet: UnsafeTransactionPropertyProtocol where Element: RuntimeObject { }
extension MutableSet: UnsafeTransactionProperty where Element: RuntimeObject {
    public typealias Entity = Element.Entity
    public typealias Safe = Set<Entity.ReadOnly>

    public func wrapped(in transaction: Transaction) -> Set<Entity.ReadOnly> {
        Set(self.map { transaction.present($0 as! ManagedObject<Entity>) })
    }
}

extension MutableOrderedSet: UnsafeTransactionPropertyProtocol where Element: RuntimeObject { }
extension MutableOrderedSet: UnsafeTransactionProperty where Element: RuntimeObject {
    public typealias Entity = Element.Entity
    public typealias Safe = OrderedSet<Entity.ReadOnly>

    public func wrapped(in transaction: Transaction) -> OrderedSet<Entity.ReadOnly> {
        OrderedSet(self.map { transaction.present($0 as! ManagedObject<Entity>) })
    }
}

extension Array: UnsafeTransactionPropertyProtocol where Element: RuntimeObject { }
extension Array: UnsafeTransactionProperty where Element: RuntimeObject {
    public typealias Entity = Element.Entity
    public typealias Safe = Array<Entity.ReadOnly>

    public func wrapped(in transaction: Transaction) -> Array<Entity.ReadOnly> {
        self.map { transaction.present($0 as! ManagedObject<Entity>) }
    }
}

extension Set: UnsafeTransactionPropertyProtocol where Element: RuntimeObject { }
extension Set: UnsafeTransactionProperty where Element: RuntimeObject {
    public typealias Entity = Element.Entity
    public typealias Safe = Set<Entity.ReadOnly>

    public func wrapped(in transaction: Transaction) -> Set<Entity.ReadOnly> {
        Set<Entity.ReadOnly>(map { transaction.present($0 as! ManagedObject<Entity>) })
    }
}

extension Swift.Optional: UnsafeTransactionPropertyProtocol where Wrapped: UnsafeTransactionPropertyProtocol { }
extension Swift.Optional: UnsafeTransactionProperty where Wrapped: UnsafeTransactionProperty {
    public typealias Entity = Wrapped.Entity
    public typealias Safe = Wrapped.Safe?
    public func wrapped(in transaction: Transaction) -> Wrapped.Safe? {
        guard case .some(let value) = self else { return nil }
        return value.wrapped(in: transaction)
    }
}

extension ManagedObject: UnsafeTransactionProperty {
    public typealias Safe = ReadOnly<Entity>

    public func wrapped(in transaction: Transaction) -> ReadOnly<Entity> {
        transaction.present(self)
    }
}
