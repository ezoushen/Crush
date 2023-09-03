//
//  EntityManagedObject.swift
//  Crush
//
//  Created by EZOU on 2020/3/27.
//

import CoreData

class EntityManagedObject: NSManagedObject {
    
    lazy var entityType: Entity.Type = {
        guard let entityClassName = entity.userInfo?[UserInfoKey.entityClassName] as? String,
              let entityType = NSClassFromString(entityClassName) as? Entity.Type
        else { fatalError("Internal Error, please file a bug.") }
        return entityType
    }()
    
    func originalValidateValue(_ value: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKey: String) throws {
        try super.validateValue(value, forKey: forKey)
    }

    func originalValidateForDelete() throws {
        try super.validateForDelete()
    }

    func originalValidateForUpdate() throws {
        try super.validateForUpdate()
    }

    func originalValidateForInsert() throws {
        try super.validateForInsert()
    }
    
    override func willSave() {
        super.willSave()
        entityType.willSave(self)
    }
    
    override func didSave() {
        super.didSave()
        entityType.didSave(self)
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        entityType.prepareForDeletion(self)
    }
    
    override func willTurnIntoFault() {
        super.willTurnIntoFault()
        entityType.willTurnIntoFault(self)
    }
    
    override func didTurnIntoFault() {
        super.didTurnIntoFault()
        entityType.didTurnIntoFault(self)
    }
    
    override func awakeFromFetch() {
        super.awakeFromFetch()
        entityType.awakeFromFetch(self)
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        entityType.awakeFromInsert(self)
    }
    
    override func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)
        entityType.awake(self, fromSnapshotEvents: flags)
    }

    override func validateValue(
        _ value: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKey key: String) throws
    {
        try entityType.validateValue(self, value: value, forKey: key)
    }

    override func validateForDelete() throws {
        try entityType.validateForDelete(self)
    }
    
    override func validateForInsert() throws {
        try entityType.validateForInsert(self)
    }

    override func validateForUpdate() throws {
        try entityType.validateForUpdate(self)
    }
}
