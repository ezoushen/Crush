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

/// A class that builds a deletion request for a given target entity.
public final class DeleteBuilder<Target: Entity>: PredicateRequestBuilder<Target> {
    let context: Context
    var config: DeletionConfig<Target> {
        get { requestConfig as! DeletionConfig<Target> }
        set { requestConfig = newValue }
    }
    
    required init(config: DeletionConfig<Target>, context: Context) {
        self.context = context
        super.init(config: config)
    }
}

extension DeleteBuilder: RequestExecutor {
    public func exec() throws -> [NSManagedObjectID] {
        return try config.batch
            ? executeBatchDelete()
            : executeLegacyBatchDelete()
    }

    public func execAsync(completion: @escaping ([NSManagedObjectID]?, Error?) -> Void) {
        context.rootContext.performAsync {
            do {
                let result = try self.exec()
                completion(result, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    private func executeBatchDelete() throws -> [NSManagedObjectID] {
        let request = config.createStoreRequest()
        let result: NSBatchDeleteResult = try context.execute(request: request)
        return result.result as! [NSManagedObjectID]
    }

    private func executeLegacyBatchDelete() throws -> [NSManagedObjectID] {
        let request = config.createStoreRequest()
        let context = context.rootContext
        return try context.performSync {
            let request = request as! NSFetchRequest<NSManagedObject>
            let objects = try context.fetch(request)
            objects.forEach(context.delete)
            try context.save()
            return objects.map(\.objectID)
        }
    }
}
