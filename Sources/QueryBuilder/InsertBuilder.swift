//
//  InsertionBuilder.swift
//  Crush
//
//  Created by ezou on 2020/3/20.
//

import CoreData

enum BatchInsertionError: Error {
    case invalidRequest
}

struct InsertionConfig<Target: Entity> {
    var predicate: NSPredicate?
    var objects: [[String: Any]] = []
    let batch: Bool
}

extension InsertionConfig: RequestConfig {
    func createStoreRequest() -> NSPersistentStoreRequest {
        let entity = Target.entityDescription()
        if #available(iOS 13.0, watchOS 6.0, macOS 10.15, *), batch {
            let description = NSBatchInsertRequest(entity: entity, objects: objects)
            description.resultType = .objectIDs
            return description
        } else {
            return Target.fetchRequest()
        }
    }
}

public final class InsertBuilder<Target: Entity>: RequestBuilder {
    var _config: InsertionConfig<Target>
    let _context: Context
    
    required init(config: Config, context: Context) {
        _context = context
        _config = config
    }
}

extension InsertBuilder {
    public func object(_ value: [String: Any]) -> Self {
        let objects = _config.objects
        _config = _config.updated(\.objects, value: objects + [value])
        return self
    }
    
    public func object(contentsOf values: [[String: Any]]) -> Self {
        let objects = _config.objects
        _config = _config.updated(\.objects, value: objects + values)
        return self
    }

    public func object(_ object: PartialObject<Target>) -> Self {
        let objects = _config.objects
        _config = _config.updated(\.objects, value: objects + [object.store])
        return self
    }

    public func object(contentsOf values: [PartialObject<Target>]) -> Self {
        let objects = _config.objects
        _config = _config.updated(\.objects, value: objects + values.map(\.store))
        return self
    }
    
    public func exec() throws -> [NSManagedObjectID] {
        if #available(iOS 13.0, watchOS 6.0, macOS 10.15, *), _config.batch {
            return try executeBatchInsert()
        } else {
            return try executeLegacyBatchInsert()
        }
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    private func executeBatchInsert() throws -> [NSManagedObjectID] {
        let result: NSBatchInsertResult = try _context.execute(
            request: _config.createStoreRequest(), on: \.rootContext)
        _context.executionContext.reset()
        return result.result as! [NSManagedObjectID]
    }

    private func executeLegacyBatchInsert() throws -> [NSManagedObjectID] {
        let entity = Target.entityDescription()
        let context = _context.rootContext
        return try context.performSync {
            let result = _config.objects.map { object -> NSManagedObject in
                let rawObject = NSManagedObject(entity: entity, insertInto: context)
                object.forEach { rawObject.setValue($0.1, key: $0.0) }
                return rawObject
            }
            try context.save()
            try context.obtainPermanentIDs(for: result)
            return result.map(\.objectID)
        }
    }
}
