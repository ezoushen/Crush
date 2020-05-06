//
//  RequestBuilder.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/20.
//

import CoreData

public protocol QueryerProtocol {
    func fetch<T: Entity>(for type: T.Type) -> FetchBuilder<T, ManagedObject, T>
}

public protocol ReadOnlyQueryerProtocol {
    func fetch<T: HashableEntity>(for type: T.Type) -> FetchBuilder<T, ManagedObject, T.ReadOnly>
}

public protocol MutableQueryerProtocol {
    func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T>
    func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T>
    func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T>
}

protocol RequestConfig {
    associatedtype Request
    
    func updated<V>(_ keyPath: KeyPath<Self, V>, value: V) -> Self
    func createFetchRequest() -> Request
}

protocol PredicatibleRequestConfig: RequestConfig {
    var predicate: NSPredicate? { get set }
}

extension RequestConfig {
    func updated<V>(_ keyPath: KeyPath<Self, V>, value: V) -> Self {
        guard let keyPath = keyPath as? WritableKeyPath<Self, V> else { return self }
        var config = self
        config[keyPath: keyPath] = value
        return config
    }
}

protocol RequestBuilder: AnyObject {
    typealias Context = Crush.TransactionContext & RawContextProviderProtocol
    
    associatedtype Config: RequestConfig
    
    var _config: Config { get set }
}
