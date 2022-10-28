//
//  PartialObject.swift
//  
//
//  Created by ezou on 2021/10/16.
//

import Foundation

@dynamicMemberLookup
public final class PartialObject<T> {
    internal var store: [String: Any] = [:]

    internal init(store: [String: Any]) {
        self.store = store
    }
}

extension PartialObject where T: Entity {
    public convenience init(_ pairs: EntityKeyValuePair<T>...) {
        let store = pairs.reduce(into: [String: Any]()) {
            $0[$1.key] = $1.value
        }
        self.init(store: store)
    }

    public subscript<S: AttributeProtocol>(
        dynamicMember keyPath: KeyPath<T, S>) -> S.PropertyValue
    {
        get {
            let value = store[keyPath.propertyName]
            guard let result = value as? S.FieldConvertor.ManagedObjectValue
            else { return .null }
            return S.FieldConvertor.convert(value: result)
        }
        set {
            let value: S.FieldConvertor.ManagedObjectValue =
                    S.FieldConvertor.convert(value: newValue)
            store[keyPath.propertyName] = value
        }
    }
}

public struct EntityKeyValuePair<T: Entity> {
    public let key: String
    public let value: Any

    public init<S: AttributeProtocol>(
        _ keyPath: KeyPath<T, S>,
        _ value: S.FieldConvertor.RuntimeObjectValue)
    {
        self.key = keyPath.propertyName
        self.value = S.FieldConvertor.convert(value: value)
    }
}
