//
//  PartialObject.swift
//  
//
//  Created by ezou on 2021/10/16.
//

import Foundation

@dynamicMemberLookup
public final class PartialObject<T: Entity> {
    
    internal var store: [String: Any] = [:]

    public init(_ pairs: EntityKeyValuePair<T>...) {
        store = pairs.reduce(into: [String: Any]()) {
            $0[$1.key] = $1.value
        }
    }
    
    public subscript<S: AttributeProtocol>(
        dynamicMember keyPath: KeyPath<T, S>
    ) -> S.PropertyValue
    where S.PropertyValue: OptionalProtocol
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
        keyPath: KeyPath<T, S>,
        value: S.FieldConvertor.RuntimeObjectValue)
    {
        self.key = keyPath.propertyName
        self.value = S.FieldConvertor.convert(value: value)
    }
}
