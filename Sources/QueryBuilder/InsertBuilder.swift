//
//  InsertionBuilder.swift
//  Crush
//
//  Created by ezou on 2020/3/20.
//

import CoreData

struct InsertionConfig<Target: Entity> {
    var predicate: NSPredicate?
    var objects: [[String: Any]] = []
    let batch: Bool

    var managedObjectHandler: ((ManagedObject<Target>) -> Bool)?
    var dictionaryHandler: ((NSMutableDictionary) -> Bool)?
}

extension InsertionConfig: RequestConfig {
    func createStoreRequest() -> NSPersistentStoreRequest {
        let entity = Target.entity()
        if #available(iOS 14.0, watchOS 7.0, macOS 11.0, tvOS 14.0, *), batch,
            let managedObjectHandler = managedObjectHandler
        {
            let description = NSBatchInsertRequest(entity: entity, managedObjectHandler: {
                managedObjectHandler($0 as! ManagedObject<Target>)
            })
            description.resultType = .objectIDs
            return description
        } else if #available(iOS 14.0, watchOS 7.0, macOS 11.0, tvOS 14.0, *), batch,
            let dictionaryHandler = dictionaryHandler
        {
            let description = NSBatchInsertRequest(entity: entity, dictionaryHandler: {
                dictionaryHandler($0)
            })
            description.resultType = .objectIDs
            return description
        } else if #available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *), batch {
            let description = NSBatchInsertRequest(entity: entity, objects: objects)
            description.resultType = .objectIDs
            return description
        } else {
            return Target.fetchRequest()
        }
    }
}

/// InsertBuilder provides a simple interface for creating a new managed object for a specific entity.
public final class InsertBuilder<Target: Entity>:
    PredicateRequestBuilder<Target>,
    RequestExecutor
{
    let context: Context
    var config: InsertionConfig<Target> {
        get { requestConfig as! InsertionConfig<Target> }
        set { requestConfig = newValue }
    }
    
    required init(config: InsertionConfig<Target>, context: Context) {
        self.context = context
        super.init(config: config)
    }
}

extension InsertBuilder {
    /// Adds a new object to the configuration.
    /// - Parameter value: The dictionary that describes the object to create.
    public func object(_ value: [String: Any]) -> Self {
        let objects = config.objects
        config.objects = objects + [value]
        return self
    }

    /// Adds multiple objects to the configuration.
    /// - Parameter values: The array of dictionaries that describes the objects to create.
    public func objects(contentsOf values: [[String: Any]]) -> Self {
        let objects = config.objects
        config.objects = objects + values
        return self
    }

    /// Adds a new object to the configuration.
    /// - Parameter object: The partial object to create.
    public func object(_ object: PartialObject<Target>) -> Self {
        let objects = config.objects
        config.objects = objects + [object.store]
        return self
    }

    /// Adds multiple objects to the configuration.
    /// - Parameter values: The array of partial objects to create.
    public func objects(contentsOf values: [PartialObject<Target>]) -> Self {
        let objects = config.objects
        config.objects = objects + values.map(\.store)
        return self
    }
}

@available(iOS 14.0, watchOS 7.0, macOS 11.0, tvOS 14.0, *)
extension InsertBuilder {
    /// The batch insert request will keep inserting objects into the persistent store until the handler return true.
    public func objectHandler(
        _ handler: @escaping (ManagedObject<Target>) -> Bool) -> any RequestExecutor<Received>
    {
        config.managedObjectHandler = handler
        return self
    }

    /// The batch insert request builder will insert all elements int the given source into the persistent store.
    public func objects<Source: Sequence>(
        from: Source,
        handler: @escaping (Source.Element, ManagedObject<Target>) -> Void
    ) -> any RequestExecutor<Received> {
        var iterator = from.makeIterator()
        return objectHandler { (object: ManagedObject<Target>) in
            guard let element = iterator.next() else { return true }
            handler(element, object)
            return false
        }
    }

    /// The batch insert request will keep inserting objects into the persistent store until the handler return true.
    /// - Note: The dictionary handler would be ignored if the managed object handler is set.
    public func objectHandler(
        _ handler: @escaping (NSMutableDictionary) -> Bool) -> any RequestExecutor<Received>
    {
        config.dictionaryHandler = handler
        return self
    }

    /// The batch insert request builder will insert all elements int the given source into the persistent store.
    /// - Note: The dictionary handler would be ignored if the managed object handler is set.
    public func objects<Source: Sequence>(
        from: Source,
        handler: @escaping (Source.Element, NSMutableDictionary) -> Void
    ) -> any RequestExecutor<Received> {
        var iterator = from.makeIterator()
        return objectHandler { dictionary in
            guard let element = iterator.next() else { return true }
            handler(element, dictionary)
            return false
        }
    }
}

extension InsertBuilder {
    public func exec() throws -> [NSManagedObjectID] {
        if #available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *), config.batch {
            return try executeBatchInsert()
        } else {
            return try executeLegacyBatchInsert()
        }
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

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
    private func executeBatchInsert() throws -> [NSManagedObjectID] {
        let result: NSBatchInsertResult = try context.execute(request: config.createStoreRequest())
        context.executionContext.reset()
        return result.result as! [NSManagedObjectID]
    }

    private func executeLegacyBatchInsert() throws -> [NSManagedObjectID] {
        let entity = Target.entity()
        let context = context.rootContext
        return try context.performSync {
            let result = config.objects.map { object -> NSManagedObject in
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
