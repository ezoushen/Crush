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

public class ManagedObjectBase: NSManagedObject {
    internal func originalValidateValue(_ value: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKey: String) throws {
        try super.validateValue(value, forKey: forKey)
    }

    internal func originalValidateForDelete() throws {
        try super.validateForDelete()
    }

    internal func originalValidateForUpdate() throws {
        try super.validateForUpdate()
    }

    internal func originalValidateForInsert() throws {
        try super.validateForInsert()
    }
}

public class ManagedObject<Entity: Crush.Entity>: ManagedObjectBase, RuntimeObject, ObjectRuntimeDriver, ObjectProxy, ManagedStatus {
    internal lazy var canTriggerEvent: Bool = {
        managedObjectContext?.name?.hasPrefix(DefaultContextPrefix) != true
    }()

    @inlinable public var managedObject: NSManagedObject { self }

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

    public override func validateValue(
        _ value: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKey key: String) throws
    {
        if canTriggerEvent {
            try Entity.validateValue(self, value: value, forKey: key)
        } else {
            try super.validateValue(value, forKey: key)
        }
    }

    public override func validateForDelete() throws {
        if canTriggerEvent {
            try Entity.validateForDelete(self)
        } else {
            try super.validateForDelete()
        }
    }
    
    public override func validateForInsert() throws {
        if canTriggerEvent {
            try Entity.validateForInsert(self)
        } else {
            try super.validateForInsert()
        }
    }

    public override func validateForUpdate() throws {
        if canTriggerEvent {
            try Entity.validateForUpdate(self)
        } else {
            try super.validateForUpdate()
        }
    }
}

extension ManagedObject {
    @inlinable public func driver() -> ManagedDriver<Entity> {
        ManagedDriver(unsafe: self)
    }

    @inlinable public func rawDriver() -> Entity.RawDriver {
        ManagedRawDriver(unsafe: self)
    }

    @inlinable public var raw: Entity.RawDriver {
        rawDriver()
    }
}
