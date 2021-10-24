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

public class ManagedObject<Entity: Crush.Entity>: NSManagedObject, RuntimeObject, ObjectDriver, ManagedStatus {
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
}
