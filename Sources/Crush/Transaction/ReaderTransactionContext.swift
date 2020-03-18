//
//  ReadOnlyTransactionContext.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

internal struct _ReadOnlyTransactionContext: ReaderTransactionContext, RawContextProviderProtocol {
    internal let context: NSManagedObjectContext
    internal let targetContext: NSManagedObjectContext
    
    internal init(context: NSManagedObjectContext, targetContext: NSManagedObjectContext) {
        self.context = context
        self.targetContext = targetContext
    }
}

extension TransactionContextProtocol where Self: RawContextProviderProtocol {
    func count(request: NSFetchRequest<NSFetchRequestResult>) -> Int {
        var result: Int? = nil
        
        targetContext.performAndWait {
            do {
                result = try targetContext.count(for: request)
            } catch {
                print("Unabled to count the records, error:", error.localizedDescription)
            }
        }
        
        return result ?? 0
    }
    
    func execute<T>(request: NSFetchRequest<NSFetchRequestResult>) -> [T] {
        targetContext.processPendingChanges()

        var results: [T] = []
        
        targetContext.performAndWait {
            do{
                results = try targetContext.fetch(request) as! [T]
            } catch {
                print("Unable to fetch data in private context, error:",
                      error.localizedDescription)
            }
        }
        return results
    }
}

extension ReaderTransactionContext where Self: RawContextProviderProtocol {
    private func transferToContext<T: NSManagedObject>(object: T) -> T {
        return context.object(with: object.objectID) as! T
    }
    
    public func count<T: Entity>(type: T.Type, predicate: NSPredicate? = nil) -> Int {
        let request = T.fetchRequest()
        request.resultType = .countResultType
        request.predicate = predicate
        
        return count(request: request)
    }
    
    public func fetch<T: TracableKeyPathProtocol>(property: T, predicate: NSPredicate?) -> [T.Value.PropertyValue?] {
        let request = NSFetchRequest<NSDictionary>(entityName: T.Root.entityCacheKey)
        request.predicate = predicate
        request.propertiesToFetch = [property.fullPath]
        request.returnsDistinctResults = true
        request.resultType = .dictionaryResultType
        
        var results: [[String: Any]] = []
        
        targetContext.performAndWait {
            do {
                results = try targetContext.fetch(request) as! [[String: Any]]
            } catch {
                print("Unabled to fetch property of records, error:", error.localizedDescription)
            }
        }
        
        return results.flatMap{$0.values}.map{$0 as? T.Value.PropertyValue}
    }

    public func fetch<T: TracableKeyPathProtocol>(properties: [T], predicate: NSPredicate?) -> [[String: Any]] {
        let request = NSFetchRequest<NSDictionary>.init(entityName: T.Root.entityCacheKey)
        request.predicate = predicate
        request.propertiesToFetch = properties.map{ $0.fullPath }
        request.returnsDistinctResults = true
        request.resultType = .dictionaryResultType
        
        var results: [[String: Any]] = []
        
        targetContext.performAndWait {
            do {
                results = try targetContext.fetch(request) as! [[String: Any]]
            } catch {
                print("Unabled to fetch properties of records, error:", error.localizedDescription)
            }
        }
        
        return results
    }
    
    public func fetch<T: Entity>(_ type: T.Type, request: NSFetchRequest<NSFetchRequestResult>) -> [T] {
        targetContext.processPendingChanges()

        var results: [NSManagedObject] = []
        
        targetContext.performAndWait {
            do{
                results = try targetContext.fetch(request) as! [NSManagedObject]
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
}


extension ReaderTransactionContext {
    public func count<T: Entity>(type: T.Type) -> Int {
        count(type: type, predicate: nil)
    }
    
    public func fetch<T: TracableKeyPathProtocol>(property: T) -> [T.Value.PropertyValue?] {
        fetch(property: property, predicate: nil)
    }
    
    public func fetch<T: TracableKeyPathProtocol>(properties: T..., predicate: NSPredicate? = nil) -> [[String: Any]] {
        fetch(properties: properties, predicate: predicate)
    }
    
    public func fetch<T: Entity>(_ type: T.Type,
                                         fetchLimit: Int? = nil,
                                         fetchOffset: Int = 0,
                                         returnsAsFaults: Bool = true,
                                         predicate: NSPredicate? = nil,
                                         sortDescriptors: [NSSortDescriptor] = [] ) -> [T] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: type.fetchKey)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = fetchLimit == nil ? .max : fetchLimit!
        request.fetchOffset = fetchOffset
        request.returnsObjectsAsFaults = returnsAsFaults
        request.includesPendingChanges = true
        request.includesSubentities = true
        
        return fetch(type, request: request)
    }
}
