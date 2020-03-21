//
//  TransactionContext.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol ContextProtocol {
    var proxyType: PropertyProxyType { get }
}

public protocol RawContextProviderProtocol: ContextProtocol {
    var context: NSManagedObjectContext { get }
    var targetContext: NSManagedObjectContext { get }
}

public protocol TransactionContextProtocol: QueryerProtocol, ContextProtocol {
    func receive<T: Entity>(_ object: T) -> T
    func receive<T: NSManagedObject>(_ object: T) -> T
}

internal extension TransactionContextProtocol where Self: RawContextProviderProtocol {
    func receive<T: Entity>(_ object: T) -> T {
        let newObject = context.receive(runtimeObject: object)
        return T.init(newObject, proxyType: proxyType)
    }
    
    func receive<T: NSManagedObject>(_ object: T) -> T {
        return context.receive(runtimeObject: object) as! T
    }
}

public protocol ReaderTransactionContext: TransactionContextProtocol {
    func count<T: Entity>(type: T.Type, predicate: NSPredicate?) -> Int
    func fetch<T: Entity>(_ type: T.Type, request: NSFetchRequest<NSFetchRequestResult>) -> [T]
    func fetch<T: TracableKeyPathProtocol>(property: T, predicate: NSPredicate?) -> [T.Value.PropertyValue?]
    func fetch<T: TracableKeyPathProtocol>(properties: [T], predicate: NSPredicate?) -> [[String: Any]]
}

extension ReaderTransactionContext {
    public var proxyType: PropertyProxyType {
        return .readOnly
    }
}

extension ReaderTransactionContext where Self: RawContextProviderProtocol {
    public func fetch<T: Entity>(for type: T.Type) -> FetchBuilder<T, NSManagedObject, T> {
        .init(config: .init(), context: self)
    }
}

public protocol WriterTransactionContext: TransactionContextProtocol {
    func create<T: Entity>(entiy: T.Type) -> T
    func delete<T: Entity>(_ object: T)
    
    func commit()
}

extension WriterTransactionContext where Self: RawContextProviderProtocol & ReaderTransactionContext {
    
    public func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T> {
        .init(config: .init(), context: self)
    }
    
    public func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T> {
        .init(config: .init(), context: self)
    }
    
    public func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T> {
        .init(config: .init(), context: self)
    }
}

public typealias ReadWriteTransactionContext = ReaderTransactionContext & WriterTransactionContext
