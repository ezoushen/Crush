//
//  ReadOnly+HashableEntity.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/5/6.
//

import CoreData

@dynamicMemberLookup
public final class ReadOnly<Value: HashableEntity>: ObservableObject {
    public let value: Value
    
    private var cancellable: Any?
    
    public init(_ rawObject: NSManagedObject) {
        self.value = Value.init(rawObject)
        setupBindings()
    }
    
    public init(_ value: Value) {
        self.value = value
        setupBindings()
    }
    
    func setupBindings() {
        guard #available(iOS 13.0, watchOS 6.0, macOS 10.15, *) else { return }
        cancellable = (value as? NeutralEntityObject)?
            .objectWillChange
            .sink { [unowned self] in
                self.objectWillChange.send()
            }
    }
    
    public func edit(in transaction: Transaction) -> Editable<Value> {
        .init(self, transaction: transaction)
    }
    
    public subscript<Subject: FieldAttribute>(dynamicMember keyPath: KeyPath<Value, Subject?>) -> Subject? {
        value[keyPath: keyPath]
    }
    
    public subscript<Subject: FieldAttribute>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
        value[keyPath: keyPath]
    }
    
    public subscript<Subject: HashableEntity>(dynamicMember keyPath: KeyPath<Value, Subject?>) -> ReadOnly<Subject>? {
        guard let value = value[keyPath: keyPath] else {
            return nil
        }
        return ReadOnly<Subject>(value)
    }
    
    public subscript<Subject: HashableEntity>(dynamicMember keyPath: KeyPath<Value, Set<Subject>>) -> Set<Subject.ReadOnly> {
        Set<Subject.ReadOnly>(value[keyPath: keyPath].map{ .init($0) })
    }
}

extension ReadOnly: Equatable where Value: Equatable {
    public static func == (lhs: ReadOnly, rhs: ReadOnly) -> Bool {
        lhs.value == rhs.value
    }
}

extension ReadOnly: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension Entity where Self: Hashable {
    public typealias ReadOnly = Crush.ReadOnly<Self>
}

#if canImport(Combine)
import Combine
import SwiftUI

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension ReadOnly {
    public func observe<T: NullableProperty & ObservableObject>(_ keyPath: KeyPath<Value, T>, containsCurrent: Bool = false) -> AnyPublisher<T.PropertyValue, Never>{
        let property = self.value[keyPath: keyPath]
        guard containsCurrent else {
            return property.objectWillChange.map{ _ in property.wrappedValue }.eraseToAnyPublisher()
        }
        return property.objectWillChange.map{ _ in property.wrappedValue }.prepend(property.wrappedValue).eraseToAnyPublisher()
    }
}
#endif
