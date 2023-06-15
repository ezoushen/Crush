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
        let description = NSBatchUpdateRequest(entity: Target.entity())
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


/// `UpdateBuilder` is a request builder for creating update requests for a given Target entity type.
public final class UpdateBuilder<Target: Entity>:
    PredicateRequestBuilder<Target>,
    RequestExecutor
{
    internal let context: Context
    internal var config: UpdateConfig<Target> {
        get { requestConfig as! UpdateConfig<Target> }
        set { requestConfig = newValue }
    }
    
    internal init(config: UpdateConfig<Target>, context: Context) {
        self.context = context
        super.init(config: config)
    }
}

extension UpdateBuilder where Target: Entity {
    /**
    Adds an attribute and value to the list of properties to update for the request.

     - Parameters:
         - keyPath: The attribute key path for the value to update.
         - value: The new value for the attribute.
     */
    public func update<Value: AttributeProtocol>(
        _ keyPath: WritableKeyPath<Target, Value>,
        value: Value.RuntimeValue) -> Self
    {
        config.propertiesToUpdate[keyPath.propertyName] =
            Value.PropertyType.convert(runtimeValue: value)
        return self
    }
}

extension UpdateBuilder {
    /// Executes the update request synchronously and returns an array of NSManagedObjectID objects for the updated entities.
    public func exec() throws -> [NSManagedObjectID] {
        try config.batch
            ? executeBatchUpdate()
            : executeLegacyBatchUpdate()
    }

    /// Executes the update request asynchronously and returns the updated entities as an array of `NSManagedObjectID` objects.
    public func execAsync(completion: @escaping ([NSManagedObjectID]?, Error?) -> Void) {
        context.executionContext.performAsync {
            do {
                let result = try self.exec()
                completion(result, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    private func executeBatchUpdate() throws -> [NSManagedObjectID] {
        let request = config.createStoreRequest()
        let result: NSBatchUpdateResult = try context.execute(request: request)
        return result.result as! [NSManagedObjectID]
    }

    private func executeLegacyBatchUpdate() throws -> [NSManagedObjectID] {
        let context = context.executionContext
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
