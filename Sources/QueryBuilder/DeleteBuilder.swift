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

public final class DeleteBuilder<Target: Entity>: PredicateRequestBuilder<Target> {
    let context: Context
    var config: DeletionConfig<Target> {
        @inline(__always) get { requestConfig as! DeletionConfig<Target> }
        @inline(__always) set { requestConfig = newValue }
    }
    
    required init(config: DeletionConfig<Target>, context: Context) {
        self.context = context
        super.init(config: config)
    }
}

extension DeleteBuilder {
    public func exec() throws -> [NSManagedObjectID] {
        return try config.batch
            ? executeBatchDelete()
            : executeLegacyBatchDelete()
    }

    private func executeBatchDelete() throws -> [NSManagedObjectID] {
        let request = config.createStoreRequest()
        let result: NSBatchDeleteResult = try context
            .execute(request: request, on: \.rootContext)
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
