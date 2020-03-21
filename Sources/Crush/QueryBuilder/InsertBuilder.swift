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

class LegacyBatchInsertRequest: NSPersistentStoreRequest {
    let objects: [[String: Any]]
    let entity: NSEntityDescription
    
    required init(entity: NSEntityDescription, objects: [[String: Any]]) {
        self.objects = objects
        self.entity = entity
    }
}

struct InsertionConfig<Target: Entity> {
    var predicate: NSPredicate?
    var objects: [[String: Any]] = []
}

extension InsertionConfig: RequestConfig {
    func createFetchRequest() -> NSPersistentStoreRequest {
        createFetchRequest(options: [:])
    }
    
    func createFetchRequest(options: [String: Any]) -> NSPersistentStoreRequest {
        let entity = Target.entity()

        if #available(iOS 13.0, *) {
            let description = NSBatchInsertRequest(entity: entity, objects: objects)
            description.resultType = .objectIDs
            return description
        } else {
            // dummy
            let description = LegacyBatchInsertRequest(entity: entity, objects: objects)
            return description
        }
    }
}

public final class InsertBuilder<Target: Entity>: RequestBuilder {
    var _config: InsertionConfig<Target>
    let _context: ReadWriteContext
    
    required init(config: Config, context: ReadWriteContext) {
        _context = context
        _config = config
    }
}

extension InsertBuilder where Target: NeutralEntityObject {
    private func transform<Value: AttributeProtocol>(object: [(KeyPath<Target, Value>, Value.PropertyValue)]) -> [String: Any] {
        var dict = Dictionary<String, Any>(minimumCapacity: object.count)
        object.forEach{ dict[$0.0.fullPath] = $0.1 }
        return dict
    }
    
    public func object<Value: AttributeProtocol>(_ value: [(KeyPath<Target, Value>, Value.PropertyValue)]) -> Self {
        let objects = _config.objects
        let dict = transform(object: value)
        _config = _config.updated(\.objects, value: objects + [dict])
        return self
    }
    
    public func object<Value: AttributeProtocol>(contentsOf values: [[(KeyPath<Target, Value>, Value.PropertyValue)]]) -> Self {
        let objects = _config.objects
        let dicts = values.map(transform(object:))
        _config = _config.updated(\.objects, value: objects + dicts)
        return self
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
    
    public func exec() throws -> [NSManagedObjectID] {
        let request = _config.createFetchRequest()
        if #available(iOS 13.0, *) {
            let result: NSBatchInsertResult = try _context.execute(request: request)
            _context.context.reset()
            return result.result as! [NSManagedObjectID]
        } else if let request = request as? LegacyBatchInsertRequest {
            let entity = request.entity
            let context = _context.targetContext
            context.reset()
            return try context.performAndWait {
                autoreleasepool { () -> [NSManagedObjectID] in
                    request.objects.map { object -> NSManagedObjectID in
                        let rawObject = NSManagedObject(entity: entity, insertInto: context)
                        let proxy = ReadWritePropertyProxy(rawObject: rawObject)
                        object.forEach {
                            proxy.setValue($0.1, key: $0.0)
                        }
                        return rawObject.objectID
                    }
                }
            }
        }
        throw BatchInsertionError.invalidRequest
    }
}
