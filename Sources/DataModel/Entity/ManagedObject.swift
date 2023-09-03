//
//  ManagedObject.swift
//  Crush
//
//  Created by EZOU on 2020/3/27.
//

import CoreData

public class ManagedObjectBase: NSManagedObject {
    
    lazy var entityType: Entity.Type = {
        guard let entityClassName = entity.userInfo?[UserInfoKey.entityClassName] as? String,
              let entityType = NSClassFromString(entityClassName) as? Entity.Type
        else { fatalError("Internal Error, please file a bug.") }
        return entityType
    }()
    
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
    
    public override func willSave() {
        super.willSave()
        entityType.willSave(self)
    }
    
    public override func didSave() {
        super.didSave()
        entityType.didSave(self)
    }
    
    public override func prepareForDeletion() {
        super.prepareForDeletion()
        entityType.prepareForDeletion(self)
    }
    
    public override func willTurnIntoFault() {
        super.willTurnIntoFault()
        entityType.willTurnIntoFault(self)
    }
    
    public override func didTurnIntoFault() {
        super.didTurnIntoFault()
        entityType.didTurnIntoFault(self)
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        entityType.awakeFromFetch(self)
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        entityType.awakeFromInsert(self)
    }
    
    public override func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)
        entityType.awake(self, fromSnapshotEvents: flags)
    }

    public override func validateValue(
        _ value: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKey key: String) throws
    {
        try entityType.validateValue(self, value: value, forKey: key)
    }

    public override func validateForDelete() throws {
        try entityType.validateForDelete(self)
    }
    
    public override func validateForInsert() throws {
        try entityType.validateForInsert(self)
    }

    public override func validateForUpdate() throws {
        try entityType.validateForUpdate(self)
    }
}
