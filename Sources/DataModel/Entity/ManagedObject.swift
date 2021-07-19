//
//  ManagedObject.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/27.
//

import CoreData

@dynamicMemberLookup
public class ManagedObject<T: Entity>: NSManagedObject {
    public subscript<Property: ValuedProperty>(dynamicMember keyPath: ReferenceWritableKeyPath<T, Property>) -> Property.PropertyValue {
        get {
            let property = T.init()[keyPath: keyPath]
            return Property.FieldConvertor.convert(value: getValue(key: property.name))
        }
        set {
            let property = T.init()[keyPath: keyPath]
            setValue(Property.FieldConvertor.convert(value: newValue, with: getValue(key: property.name)), key: property.name)
        }
    }

    public subscript<Property: ValuedProperty>(dynamicMember keyPath: KeyPath<T, Property>) -> Property.PropertyValue {
        get {
            let property = T.init()[keyPath: keyPath]
            return Property.FieldConvertor.convert(value: getValue(key: property.name))
        }
    }
}

extension NSManagedObject {
    @inline(__always)
    func getValue<T>(key: String) -> T {
        willAccessValue(forKey: key)
        defer {
            didAccessValue(forKey: key)
        }
        return primitiveValue(forKey: key) as! T
    }

    @inline(__always)
    func setValue(_ value: Any?, key: String) {
        let value = value.isNil ? nil : value
        willChangeValue(forKey: key)
        defer {
            didChangeValue(forKey: key)
        }
        setPrimitiveValue(value, forKey: key)
    }
}
