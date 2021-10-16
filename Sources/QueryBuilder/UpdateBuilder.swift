//
//  InsertionBuilder.swift
//  Crush
//
//  Created by ezou on 2020/3/20.
//

import CoreData

struct UpdateConfig<Target: Entity>: RequestConfig {
    var predicate: NSPredicate?
    var propertiesToUpdate: [AnyHashable: Any] = [:]

    let batch: Bool
}

extension UpdateConfig {
    func createStoreRequest() -> NSPersistentStoreRequest {
        batch
            ? batchRequest()
            : fetchRequest()
    }

    private func batchRequest() -> NSBatchUpdateRequest {
        let description = NSBatchUpdateRequest(entity: Target.entityDescription())
        description.predicate = predicate
        description.propertiesToUpdate = propertiesToUpdate
        description.resultType = .updatedObjectIDsResultType
        return description
    }

    private func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let request = Target.fetchRequest()
        request.predicate = predicate
        request.resultType = .managedObjectResultType
        request.propertiesToFetch = propertiesToUpdate
            .compactMap{ $0.key as? String }
        return request
    }
}

public final class UpdateBuilder<Target: Entity> {
    internal let context: Context
    internal var config: UpdateConfig<Target>
    
    internal init(config: Config, context: Context) {
        self.context = context
        self.config = config
    }
}

extension UpdateBuilder where Target: Entity {
    public func update<Value: AttributeProtocol>(
        _ keyPath: KeyPath<Target, Value>,
        value: Value.PropertyValue) -> Self
    {
        config.propertiesToUpdate[keyPath.propertyName] =
            Value.FieldConvertor.convert(value: value)
        return self
    }
}

extension UpdateBuilder: RequestBuilder {
    public func exec() throws -> [NSManagedObjectID] {
        try config.batch
            ? executeBatchUpdate()
            : executeLegacyBatchUpdate()
    }

    private func executeBatchUpdate() throws -> [NSManagedObjectID] {
        let request = config.createStoreRequest()
        let result: NSBatchUpdateResult = try context
            .execute(request: request, on: \.rootContext)
        return result.result as! [NSManagedObjectID]
    }

    private func executeLegacyBatchUpdate() throws -> [NSManagedObjectID] {
        let context = context.rootContext
        return try context.performSync {
            let request = config
                .createStoreRequest() as! NSFetchRequest<NSManagedObject>
            let objects = try context.fetch(request)

            for object in objects {
                for (key, value) in config.propertiesToUpdate {
                    object.setValue(value, key: key as! String)
                }
            }

            try context.save()

            return objects.map(\.objectID)
        }
    }
}
