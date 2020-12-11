//
//  ManagedObject.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/27.
//

import CoreData

@objc
protocol ManagedObjectDelegate: AnyObject {
    
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

final class ManagedObjectDelegateProxy: ManagedObjectDelegate {
    
    var parent: ManagedObjectDelegate?
    
    weak var delegate: ManagedObjectDelegate!

    init(delegate: ManagedObjectDelegate, parent: ManagedObjectDelegate?) {
        self.delegate = delegate
        self.parent = parent
    }
    
    func awakeFromFetch() {
        parent?.awakeFromFetch()
        delegate?.awakeFromFetch()
    }
    
    func awakeFromInsert() {
        parent?.awakeFromInsert()
        delegate?.awakeFromInsert()
    }
    
    func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        parent?.awake(fromSnapshotEvents: flags)
        delegate?.awake(fromSnapshotEvents: flags)
    }
    
    func prepareForDeletion() {
        parent?.prepareForDeletion()
        delegate?.prepareForDeletion()
    }
    
    func willSave() {
        parent?.willSave()
        delegate?.willSave()
    }
    
    func didSave() {
        parent?.didSave()
        delegate?.didSave()
    }
    
    func willTurnIntoFault() {
        parent?.willTurnIntoFault()
        delegate?.willTurnIntoFault()
    }
    
    func didTurnIntoFault() {
        parent?.didTurnIntoFault()
        delegate?.didTurnIntoFault()
    }
}

public final class ManagedObject: NSManagedObject {
    
    var delegate: ManagedObjectDelegate?
    
    private lazy var dummyDelegate: ManagedObjectDelegate? = {
        guard let typeString = entity.userInfo?[kEntityTypeKey] as? String,
              let type = NSClassFromString(typeString) as? EntityObject.Type else { return nil }
        return type.init(proxy: UnownedReadWritePropertyProxy(rawObject: self))
    }()
    
    private func getDelegate() -> ManagedObjectDelegate? {
        delegate ?? dummyDelegate
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        getDelegate()?.awakeFromFetch()
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        getDelegate()?.awakeFromInsert()
    }
    
    public override func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)
        getDelegate()?.awake(fromSnapshotEvents: flags)
    }
    
    public override func prepareForDeletion() {
        super.prepareForDeletion()
        getDelegate()?.prepareForDeletion()
    }
    
    public override func willSave() {
        super.willSave()
        getDelegate()?.willSave()
    }
    
    public override func didSave() {
        super.didSave()
        getDelegate()?.didSave()
    }
    
    public override func willTurnIntoFault() {
        super.willTurnIntoFault()
        getDelegate()?.willTurnIntoFault()
    }
    
    public override func didTurnIntoFault() {
        super.didTurnIntoFault()
        getDelegate()?.didTurnIntoFault()
    }
}
