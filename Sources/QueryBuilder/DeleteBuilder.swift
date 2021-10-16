//
//  DeletionBuilder.swift
//  Crush
//
//  Created by ezou on 2020/3/20.
//

import CoreData

struct DeletionConfig<Target: Entity> {
    var predicate: NSPredicate?
    let batch: Bool
}

extension DeletionConfig: RequestConfig {
    func createStoreRequest() -> NSPersistentStoreRequest {
        let fetchRequest = Target.fetchRequest()
        fetchRequest.predicate = predicate
        if batch {
            let description = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            description.resultType = .resultTypeObjectIDs
            return description
        }
        fetchRequest.resultType = .managedObjectResultType
        return fetchRequest
    }
}

public final class DeleteBuilder<Target: Entity> {
    var _config: DeletionConfig<Target>
    let _context: Context
    
    required init(config: Config, context: Context) {
        _config = config
        _context = context
    }
}

extension DeleteBuilder: RequestBuilder {
    public func `where`(_ predicate: TypedPredicate<Target>) -> Self {
        _config = _config.updated(\.predicate, value: predicate)
        return self
    }
    
    public func andWhere(_ predicate: TypedPredicate<Target>) -> Self {
        let newPredicate: NSPredicate = {
            if let pred = _config.predicate {
                return NSCompoundPredicate(andPredicateWithSubpredicates: [pred, predicate])
            }
            return predicate
        }()
        _config = _config.updated(\.predicate, value: newPredicate)
        return self
    }
    
    public func orWhere(_ predicate: TypedPredicate<Target>) -> Self {
        let newPredicate: NSPredicate = {
            if let pred = _config.predicate {
                return NSCompoundPredicate(orPredicateWithSubpredicates: [pred, predicate])
            }
            return predicate
        }()
        _config = _config.updated(\.predicate, value: newPredicate)
        return self
    }
}

extension DeleteBuilder {
    public func exec() throws -> [NSManagedObjectID] {
        return try _config.batch
            ? executeBatchDelete()
            : executeLegacyBatchDelete()
    }

    private func executeBatchDelete() throws -> [NSManagedObjectID] {
        let request = _config.createStoreRequest()
        let result: NSBatchDeleteResult = try _context
            .execute(request: request, on: \.rootContext)
        return result.result as! [NSManagedObjectID]
    }

    private func executeLegacyBatchDelete() throws -> [NSManagedObjectID] {
        let request = _config.createStoreRequest()
        let context = _context.rootContext
        return try context.performSync {
            let request = request as! NSFetchRequest<NSManagedObject>
            let objects = try context.fetch(request)
            objects.forEach(_context.rootContext.delete)
            try context.save()
            return objects.map(\.objectID)
        }
    }
}
