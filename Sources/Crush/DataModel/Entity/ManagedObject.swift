//
//  ManagedObject.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/27.
//

import CoreData

@objc
protocol ManagedObjectDelegate: AnyObject {
    func willAccessValue(forKey key: String?) // read notification

    func didAccessValue(forKey key: String?) // read notification (together with willAccessValueForKey used to maintain inverse relationships, to fire faults, etc.) - each read access has to be wrapped in this method pair (in the same way as each write access has to be wrapped in the KVO method pair)

    
    // KVO change notification
    func willChangeValue(forKey key: String)

    func didChangeValue(forKey key: String)

    func willChangeValue(forKey inKey: String, withSetMutation inMutationKind: NSKeyValueSetMutationKind, using inObjects: Set<AnyHashable>)

    func didChangeValue(forKey inKey: String, withSetMutation inMutationKind: NSKeyValueSetMutationKind, using inObjects: Set<AnyHashable>)

    
    // invoked after a fetch or after unfaulting (commonly used for computing derived values from the persisted properties)
    func awakeFromFetch()

    
    // invoked after an insert (commonly used for initializing special default/initial settings)
    func awakeFromInsert()

    
    /* Callback for undo, redo, and other multi-property state resets */
    func awake(fromSnapshotEvents flags: NSSnapshotEventType)

    
    /* Callback before delete propagation while the object is still alive.  Useful to perform custom propagation before the relationships are torn down or reconfigure KVO observers. */
    func prepareForDeletion()

    
    // commonly used to compute persisted values from other transient/scratchpad values, to set timestamps, etc. - this method can have "side effects" on the persisted values
    func willSave()

    
    // commonly used to notify other objects after a save
    func didSave()

    
    // invoked automatically by the Core Data framework before receiver is converted (back) to a fault.  This method is the companion of the -didTurnIntoFault method, and may be used to (re)set state which requires access to property values (for example, observers across keypaths.)  The default implementation does nothing.
    @available(iOS 3.0, *)
    func willTurnIntoFault()

    
    // commonly used to clear out additional transient values or caches
    func didTurnIntoFault()
}

struct Weak<Element: AnyObject> {
    weak var element: Element?
}

public final class ManagedObject: NSManagedObject {
    var delegates: [Weak<ManagedObjectDelegate>] = []
    
    public override func willAccessValue(forKey key: String?) {
        super.willAccessValue(forKey: key)
        delegates.forEach{ $0.element?.willAccessValue(forKey: key) }
    }
    
    public override func didAccessValue(forKey key: String?) {
        super.didAccessValue(forKey: key)
        delegates.forEach{ $0.element?.willAccessValue(forKey: key) }
    }
    
    public override func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        delegates.forEach{ $0.element?.willChangeValue(forKey: key) }
    }
    
    public override func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)
        delegates.forEach{ $0.element?.didChangeValue(forKey: key) }
    }
    
    public override func willChangeValue(forKey inKey: String, withSetMutation inMutationKind: NSKeyValueSetMutationKind, using inObjects: Set<AnyHashable>) {
        super.willChangeValue(forKey: inKey, withSetMutation: inMutationKind, using: inObjects)
        delegates.forEach{ $0.element?.willChangeValue(forKey: inKey, withSetMutation: inMutationKind, using: inObjects) }
    }
    
    public override func didChangeValue(forKey inKey: String, withSetMutation inMutationKind: NSKeyValueSetMutationKind, using inObjects: Set<AnyHashable>) {
        super.didChangeValue(forKey: inKey, withSetMutation: inMutationKind, using: inObjects)
        delegates.forEach{ $0.element?.didChangeValue(forKey: inKey, withSetMutation: inMutationKind, using: inObjects) }
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        delegates.forEach{ $0.element?.awakeFromFetch() }
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        delegates.forEach{ $0.element?.awakeFromInsert() }
    }
    
    public override func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)
        delegates.forEach{ $0.element?.awake(fromSnapshotEvents: flags) }
    }
    
    public override func prepareForDeletion() {
        super.prepareForDeletion()
        delegates.forEach{ $0.element?.prepareForDeletion() }
    }
    
    public override func willSave() {
        super.willSave()
        delegates.forEach{ $0.element?.willSave() }
    }
    
    public override func didSave() {
        super.didSave()
        delegates.forEach{ $0.element?.didSave() }
    }
    
    public override func willTurnIntoFault() {
        super.willTurnIntoFault()
        delegates.forEach{ $0.element?.willTurnIntoFault() }
    }
    
    public override func didTurnIntoFault() {
        super.didTurnIntoFault()
        delegates.forEach{ $0.element?.didTurnIntoFault() }
    }
}
