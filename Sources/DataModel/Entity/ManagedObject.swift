//
//  ManagedObject.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/27.
//

import CoreData

public protocol RuntimeObject {
    associatedtype Entity: Crush.Entity
}

@dynamicMemberLookup
public class ManagedObject<Entity: Crush.Entity>: NSManagedObject, RuntimeObject {
    public override func willSave() {
        super.willSave()
        Entity.willSave(self)
    }
    
    public override func didSave() {
        super.didSave()
        Entity.didSave(self)
    }
    
    public override func prepareForDeletion() {
        super.prepareForDeletion()
        Entity.prepareForDeletion(self)
    }
    
    public override func willTurnIntoFault() {
        super.willTurnIntoFault()
        Entity.willTurnIntoFault(self)
    }
    
    public override func didTurnIntoFault() {
        super.didTurnIntoFault()
        Entity.didTurnIntoFault(self)
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        Entity.awakeFromFetch(self)
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        Entity.awakeFromInsert(self)
    }
    
    public override func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)
        Entity.awake(self, fromSnapshotEvents: flags)
    }
}

extension ManagedObject {
    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> MutableSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToMany<Property.Destination>
    {
        let property = Entity.init()[keyPath: keyPath]
        let key = property.name
        let mutableSet = getMutableSet(key: key)
        return Property.Mapping.convert(value: mutableSet)
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> MutableOrderedSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToOrderedMany<Property.Destination>
    {
        let property = Entity.init()[keyPath: keyPath]
        let key = property.name
        let mutableOrderedSet = getMutableOrderedSet(key: key)
        return Property.Mapping.convert(value: mutableOrderedSet)
    }

    public subscript<Property: ValuedProperty>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.PropertyValue {
        get {
            return self[immutable: keyPath]
        }
        set {
            let property = Entity.init()[keyPath: keyPath]
            setValue(Property.FieldConvertor.convert(value: newValue), key: property.name)
        }
    }

    public subscript<Property: ValuedProperty>(
        immutable keyPath: KeyPath<Entity, Property>
    ) -> Property.PropertyValue {
        let property = Entity.init()[keyPath: keyPath]
        return Property.FieldConvertor.convert(
            value: getValue(key: property.name))
    }
}

extension NSManagedObject {
    @inline(__always)
    internal func getValue<T>(key: String) -> T {
        willAccessValue(forKey: key)
        defer {
            didAccessValue(forKey: key)
        }
        return primitiveValue(forKey: key) as! T
    }

    @inline(__always)
    internal func setValue(_ value: Any?, key: String) {
        willChangeValue(forKey: key)
        defer {
            didChangeValue(forKey: key)
        }
        value.isNil
            ? setNilValueForKey(key)
            : setPrimitiveValue(value, forKey: key)
    }

    @inline(__always)
    internal func getMutableSet(key: String) -> NSMutableSet {
        willAccessValue(forKey: key)
        defer {
            didAccessValue(forKey: key)
        }
        return mutableSetValue(forKey: key)
    }

    @inline(__always)
    internal func getMutableOrderedSet(key: String) -> NSMutableOrderedSet {
        willAccessValue(forKey: key)
        defer {
            didAccessValue(forKey: key)
        }
        return mutableOrderedSetValue(forKey: key)
    }
}
