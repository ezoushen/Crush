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
    internal lazy var canTriggerEvent: Bool = {
        managedObjectContext?.name?.hasPrefix(DefaultContextPrefix) != true
    }()

    public override func willSave() {
        super.willSave()
        if canTriggerEvent {
            Entity.willSave(self)
        }
    }
    
    public override func didSave() {
        super.didSave()
        if canTriggerEvent {
            Entity.didSave(self)
        }
    }
    
    public override func prepareForDeletion() {
        super.prepareForDeletion()
        if canTriggerEvent {
            Entity.prepareForDeletion(self)
        }
    }
    
    public override func willTurnIntoFault() {
        super.willTurnIntoFault()
        if canTriggerEvent {
            Entity.willTurnIntoFault(self)
        }
    }
    
    public override func didTurnIntoFault() {
        super.didTurnIntoFault()
        if canTriggerEvent {
            Entity.didTurnIntoFault(self)
        }
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        if canTriggerEvent {
            Entity.awakeFromFetch(self)
        }
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        if canTriggerEvent {
            Entity.awakeFromInsert(self)
        }
    }
    
    public override func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)
        if canTriggerEvent {
            Entity.awake(self, fromSnapshotEvents: flags)
        }
    }
}

extension ManagedObject {
    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> MutableSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToMany<Property.Destination>
    {
        let key = keyPath.propertyName
        let mutableSet = getMutableSet(key: key)
        return Property.Mapping.convert(value: mutableSet)
    }

    public subscript<Property: RelationshipProtocol>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> MutableOrderedSet<ManagedObject<Property.Destination>>
    where
        Property.Mapping == ToOrdered<Property.Destination>
    {
        let key = keyPath.propertyName
        let mutableOrderedSet = getMutableOrderedSet(key: key)
        return Property.Mapping.convert(value: mutableOrderedSet)
    }

    public subscript<Property: ValuedProperty>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.PropertyValue {
        return self[immutable: keyPath]
    }

    public subscript<Property: WritableValuedProperty>(
        dynamicMember keyPath: KeyPath<Entity, Property>
    ) -> Property.PropertyValue {
        get {
            return self[immutable: keyPath]
        }
        set {
            setValue(Property.FieldConvertor.convert(value: newValue), key: keyPath.propertyName)
        }
    }

    public subscript<Property: ValuedProperty>(
        immutable keyPath: KeyPath<Entity, Property>
    ) -> Property.PropertyValue {
        return Property.FieldConvertor.convert(
            value: getValue(key: keyPath.propertyName))
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
