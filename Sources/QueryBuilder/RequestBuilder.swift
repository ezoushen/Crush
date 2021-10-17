//
//  RequestBuilder.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/20.
//

import CoreData

public protocol QueryerProtocol {
    func fetch<T: Entity>(for type: T.Type) -> FetchBuilder<T, ManagedObject<T>, ManagedObject<T>>
}

public protocol ReadOnlyQueryerProtocol {
    func fetch<T: Entity>(for type: T.Type) -> FetchBuilder<T, ManagedObject<T>, T.ReadOnly>
}

public protocol MutableQueryerProtocol {
    func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T>
    func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T>
    func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T>
}

protocol RequestConfig {
    associatedtype Request

    var predicate: NSPredicate? { get set }
    func createStoreRequest() -> Request
}

protocol RequestBuilder: AnyObject {
    typealias Context = Crush.SessionContext & RawContextProviderProtocol

    associatedtype Target: Entity
    associatedtype Config: RequestConfig
    
    var config: Config { get set }
}

extension RequestBuilder {
    public func `where`(_ predicate: TypedPredicate<Target>) -> Self {
        config.predicate = predicate
        return self
    }

    public func andWhere(_ predicate: TypedPredicate<Target>) -> Self {
        guard let oldPredicate = config.predicate else {
            config.predicate = predicate
            return self
        }
        config.predicate = oldPredicate && predicate
        return self
    }

    public func orWhere(_ predicate: TypedPredicate<Target>) -> Self {
        guard let oldPredicate = config.predicate else {
            config.predicate = predicate
            return self
        }
        config.predicate = oldPredicate || predicate
        return self
    }
}
