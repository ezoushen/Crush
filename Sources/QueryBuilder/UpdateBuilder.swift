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
    func createFetchRequest() -> NSPersistentStoreRequest {
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
    internal let _context: Context
    internal var _config: UpdateConfig<Target>
    
    internal init(config: Config, context: Context) {
        self._context = context
        self._config = config
    }
}

extension UpdateBuilder {
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
    
    private func update(key: String, value: Any) -> Self {
        var properties = _config.propertiesToUpdate
        properties[key] = value
        _config = _config.updated(\.propertiesToUpdate, value: properties)
        return self
    }
}

extension UpdateBuilder where Target: Entity {
    public func update<Value: AttributeProtocol>(_ keyPath: KeyPath<Target, Value>, value: Value.PropertyValue) -> Self {
        update(key: keyPath.propertyName, value: Value.FieldConvertor.convert(value: value))
    }
}

extension UpdateBuilder: RequestBuilder {
    public func exec() throws -> [NSManagedObjectID] {
        try _config.batch
            ? executeBatchUpdate()
            : executeLegacyBatchUpdate()
    }

    private func executeBatchUpdate() throws -> [NSManagedObjectID] {
        let request = _config.createFetchRequest()
        let result: NSBatchUpdateResult = try _context
            .execute(request: request, on: \.rootContext)
        return result.result as! [NSManagedObjectID]
    }

    private func executeLegacyBatchUpdate() throws -> [NSManagedObjectID] {
        let context = _context.rootContext

        return try context.performSync {
            let request = _config
                .createFetchRequest() as! NSFetchRequest<NSManagedObject>
            let objects = try context.fetch(request)

            for object in objects {
                for (key, value) in _config.propertiesToUpdate {
                    object.setValue(value, key: key as! String)
                }
            }

            try _context.rootContext.save()

            return objects.map(\.objectID)
        }
    }
}
