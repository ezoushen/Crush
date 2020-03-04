//
//  Transaction.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol AsynchronousContextProtocol { }

public protocol RawContextProviderProtocol {
    typealias Proxy = RuntimeObject.Proxy
    
    var proxyType: Proxy.Type { get }
    var context: NSManagedObjectContext { get }
    var targetContext: NSManagedObjectContext { get }
}

public protocol TransactionContextProtocol { }

internal extension TransactionContextProtocol where Self: RawContextProviderProtocol {
    func receive<T: Entity>(_ object: T) -> T {
        let newObject = context.receive(runtimeObject: object)
        return T.init(newObject, proxyType: proxyType)
    }
}

public protocol QueryerProtocol {
    func query<T: Entity>(for type: T.Type) -> QueryBuilder<T, NSManagedObject, T>
}

public protocol ReadOnlyTransactionContext: TransactionContextProtocol, QueryerProtocol {
    func count<T: Entity>(type: T.Type, predicate: NSPredicate?) -> Int
    func fetch<T: Entity>(_ type: T.Type, request: NSFetchRequest<NSFetchRequestResult>) -> [T]
    func fetch<T: TracableKeyPathProtocol>(property: T, predicate: NSPredicate?) -> [T.Value.EntityType?]
    func fetch<T: TracableKeyPathProtocol>(properties: [T], predicate: NSPredicate?) -> [[String: Any]]
}

extension ReadOnlyTransactionContext where Self: RawContextProviderProtocol {
    public var proxyType: Proxy.Type {
        return ReadOnlyValueMapper.self
    }
}

extension ReadOnlyTransactionContext {
    public func count<T: Entity>(type: T.Type) -> Int {
        count(type: type, predicate: nil)
    }
    
    public func fetch<T: TracableKeyPathProtocol>(property: T) -> [T.Value.EntityType?] {
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

extension ReadOnlyTransactionContext where Self: RawContextProviderProtocol {
    public func query<T: Entity>(for type: T.Type) -> QueryBuilder<T, NSManagedObject, T> {
        return QueryBuilder<T, NSManagedObject, T>(config: .init(), context: self)
    }
}

public protocol ReadWriteTransactionContext: ReadOnlyTransactionContext {
    func create<T: Entity>(entiy: T.Type) -> T
    func delete<T: Entity>(_ object: T)
    
    func commit()
    func stash()
}

extension ReadWriteTransactionContext where Self: RawContextProviderProtocol {
    public var proxyType: Proxy.Type {
        return ReadWriteValueMapper.self
    }
}
