//
//  ReadOnly+HashableEntity.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/5/6.
//

import CoreData

@dynamicMemberLookup
public struct ReadOnly<Value: HashableEntity> {
    public let value: Value
    
    public var managedObjectID: NSManagedObjectID {
        value.rawObject.objectID
    }
    
    public init(_ value: Value) {
        self.value = value
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

extension ReadOnly where Value: NeutralEntityObject {
    public func validateForDelete() throws {
        try value.validateForDelete()
    }
    
    public func validateForInsert() throws {
        try value.validateForInsert()
    }
    
    public func validateForUpdate() throws {
        try value.validateForUpdate()
    }
}

extension HashableEntity {
    public typealias ReadOnly = Crush.ReadOnly<Self>
}

public protocol ObservableProtocol {
    associatedtype ObservableType: FieldConvertible
}

#if canImport(Combine)
import Combine
import SwiftUI

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension ReadOnly {
    public func observe<T: NullableProperty & ObservableProtocol>(_ keyPath: KeyPath<Value, T>, containsCurrent: Bool = false)
    -> AnyPublisher<T.PropertyValue, Never>
    where T.PropertyValue == T.ObservableType.RuntimeObjectValue {
        let name = self.value[keyPath: keyPath].name
        return KVOPublisher<NSManagedObject, T.ObservableType.ManagedObjectValue>(
            subject: value.rawObject,
            keyPath: name,
            options: containsCurrent ? [.initial, .new] : [.new]
        )
            .filter { _ in
                value.rawObject.faultingState == 0
            }
            .map(T.ObservableType.convert(value:))
            .eraseToAnyPublisher()
    }
}
#endif
