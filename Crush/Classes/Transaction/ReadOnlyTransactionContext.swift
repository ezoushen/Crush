//
//  ReadOnlyTransactionContext.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

internal struct _ReadOnlyTransactionContext: ReadOnlyTransactionContext, RawContextProviderProtocol {
    internal let context: NSManagedObjectContext
    internal let writerContext: NSManagedObjectContext
    internal let readerContext: NSManagedObjectContext
    
    internal init(context: NSManagedObjectContext, readOnlyContext: NSManagedObjectContext, writerContext: NSManagedObjectContext) {
        self.context = context
        self.readerContext = readOnlyContext
        self.writerContext = writerContext
    }
}

extension ReadOnlyTransactionContext where Self: RawContextProviderProtocol {
    private func transferToContext<T: NSManagedObject>(object: T) -> T {
        return context.object(with: object.objectID) as! T
    }
    
    public func count<T: Entity>(type: T.Type, predicate: NSPredicate? = nil) -> Int {
        let request = T.fetchRequest()
        request.resultType = .countResultType
        request.predicate = predicate
        
        var result: Int? = nil
        
        writerContext.performAndWait {
            do {
                result = try writerContext.count(for: request)
            } catch {
                print("Unabled to count the records, error:", error.localizedDescription)
            }
        }
        
        return result ?? 0
    }
    
    public func fetch<T: TracableKeyPathProtocol>(property: T, predicate: NSPredicate?) -> [T.Value.EntityType?] {
        let request = NSFetchRequest<NSDictionary>(entityName: T.Root.entityCacheKey)
        request.predicate = predicate
        request.propertiesToFetch = [property.fullPath]
        request.returnsDistinctResults = true
        request.resultType = .dictionaryResultType
        
        var results: [[String: Any]] = []
        
        writerContext.performAndWait {
            do {
                results = try writerContext.fetch(request) as! [[String: Any]]
            } catch {
                print("Unabled to fetch property of records, error:", error.localizedDescription)
            }
        }
        
        return results.flatMap{$0.values}.map{$0 as? T.Value.EntityType}
    }
    
    public func fetch<T: TracableKeyPathProtocol>(properties: [T], predicate: NSPredicate?) -> [[String: Any]] {
        let request = NSFetchRequest<NSDictionary>.init(entityName: T.Root.entityCacheKey)
        request.predicate = predicate
        request.propertiesToFetch = properties.map{ $0.fullPath }
        request.returnsDistinctResults = true
        request.resultType = .dictionaryResultType
        
        var results: [[String: Any]] = []
        
        writerContext.performAndWait {
            do {
                results = try writerContext.fetch(request) as! [[String: Any]]
            } catch {
                print("Unabled to fetch properties of records, error:", error.localizedDescription)
            }
        }
        
        return results
    }
    
    public func fetch<T: Entity>(_ type: T.Type, request: NSFetchRequest<NSFetchRequestResult>) -> [T] {
        writerContext.processPendingChanges()

        var results: [NSManagedObject] = []
        
        writerContext.performAndWait {
            do{
                results = try writerContext.fetch(request) as! [NSManagedObject]
            } catch {
                print("Unable to fetch data in private context, error:",
                      error.localizedDescription)
            }
        }
        
        if T.self is NSManagedObject.Type {
            return results.map(transferToContext) as! [T]
        } else {
            return results.map(transferToContext).map{ T.init($0, proxyType: proxyType) }
        }
    }
    
    func count(request: NSFetchRequest<NSFetchRequestResult>) -> Int {
        var result: Int? = nil
        
        writerContext.performAndWait {
            do {
                result = try writerContext.count(for: request)
            } catch {
                print("Unabled to count the records, error:", error.localizedDescription)
            }
        }
        
        return result ?? 0
    }
    
    func execute<T>(request: NSFetchRequest<NSFetchRequestResult>) -> [T] {
        writerContext.processPendingChanges()

        var results: [T] = []
        
        writerContext.performAndWait {
            do{
                results = try writerContext.fetch(request) as! [T]
            } catch {
                print("Unable to fetch data in private context, error:",
                      error.localizedDescription)
            }
        }
        return results
    }
}
