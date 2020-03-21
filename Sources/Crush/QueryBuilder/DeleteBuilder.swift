//
//  DeletionBuilder.swift
//  Crush
//
//  Created by ezou on 2020/3/20.
//

import CoreData

struct DeletionConfig<Target: Entity> {
    var predicate: NSPredicate?
}

extension DeletionConfig: RequestConfig {
    func createFetchRequest() -> NSBatchDeleteRequest {
        let name = Target.entity().name ?? String(describing: Self.self)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        fetchRequest.predicate = predicate
        let description = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        return description
    }
}

public final class DeleteBuilder<Target: Entity> {
    var _config: DeletionConfig<Target>
    let _context: ReadWriteContext
    
    required init(config: Config, context: ReadWriteContext) {
        _config = config
        _context = context
    }
}

extension DeleteBuilder: RequestBuilder {
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
}

extension DeleteBuilder {
    public func exec() throws -> NSBatchDeleteResult {
        try _context.execute(request: _config.createFetchRequest())
    }
}
