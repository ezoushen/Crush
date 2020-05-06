//
//  InsertionBuilder.swift
//  Crush
//
//  Created by ezou on 2020/3/20.
//

import CoreData

struct UpdateConfig<Target: Entity>: RequestConfig {
    var predicate: NSPredicate?
    var propertiesToUpdate: [AnyHashable: Any]?
}

extension UpdateConfig {
    func createFetchRequest() -> NSBatchUpdateRequest {
        let description = NSBatchUpdateRequest(entity: Target.entity())
        description.predicate = predicate
        description.propertiesToUpdate = propertiesToUpdate
        return description
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
    public func `where`(_ predicate: NSPredicate) -> Self {
        _config = _config.updated(\.predicate, value: predicate)
        return self
    }
    
    public func andWhere(_ predicate: NSPredicate) -> Self {
        let newPredicate: NSPredicate = {
            if let pred = _config.predicate {
                return NSCompoundPredicate(andPredicateWithSubpredicates: [pred, predicate])
            }
            return predicate
        }()
        _config = _config.updated(\.predicate, value: newPredicate)
        return self
    }
    
    public func orWhere(_ predicate: NSPredicate) -> Self {
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
        var properties = _config.propertiesToUpdate ?? [:]
        properties[key] = value
        _config = _config.updated(\.propertiesToUpdate, value: properties)
        return self
    }
}

extension UpdateBuilder where Target: NeutralEntityObject {
    public func update<Value: AttributeProtocol>(_ keyPath: KeyPath<Target, Value>, value: Value.PropertyValue) -> Self {
        update(key: keyPath.fullPath, value: value)
    }
}

extension UpdateBuilder where Target: NSManagedObject {
    public func update<Value: AttributeProtocol>(_ keyPath: KeyPath<Target, Value>, value: Value.PropertyValue) -> Self {
        update(key: keyPath.stringValue, value: value)
    }
}

extension UpdateBuilder: RequestBuilder {
    public func exec() throws -> NSBatchUpdateResult {
        try _context.execute(request: _config.createFetchRequest())
    }
}
