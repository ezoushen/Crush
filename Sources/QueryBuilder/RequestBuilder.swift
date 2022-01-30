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
    var predicate: NSPredicate? { get set }
    func createStoreRequest() -> NSPersistentStoreRequest
}

protocol RequestBuilder: AnyObject {
    typealias Context = Crush.SessionContext & RawContextProviderProtocol

    associatedtype Target: Entity
}

public class PredicateRequestBuilder<Target: Entity>: RequestBuilder {
    internal var requestConfig: RequestConfig

    internal init(config: RequestConfig) {
        self.requestConfig = config
    }

    public func `where`(_ predicateString: String) -> Self {
        return `where`(TypedPredicate(format: predicateString))
    }

    public func `where`(_ predicate: TypedPredicate<Target>) -> Self {
        return `where`(predicate as NSPredicate)
    }

    public func `where`(_ predicate: NSPredicate) -> Self {
        requestConfig.predicate = predicate
        return self
    }

    public func andWhere(_ predicateString: String) -> Self {
        return andWhere(TypedPredicate(format: predicateString))
    }

    public func andWhere(_ predicate: TypedPredicate<Target>) -> Self {
        return andWhere(predicate as NSPredicate)
    }

    public func andWhere(_ predicate: NSPredicate) -> Self {
        guard let oldPredicate = requestConfig.predicate else {
            requestConfig.predicate = predicate
            return self
        }
        requestConfig.predicate = oldPredicate && predicate
        return self
    }

    public func orWhere(_ predicateString: String) -> Self {
        return orWhere(TypedPredicate(format: predicateString))
    }

    public func orWhere(_ predicate: TypedPredicate<Target>) -> Self {
        return orWhere(predicate as NSPredicate)
    }

    public func orWhere(_ predicate: NSPredicate) -> Self {
        guard let oldPredicate = requestConfig.predicate else {
            requestConfig.predicate = predicate
            return self
        }
        requestConfig.predicate = oldPredicate || predicate
        return self
    }

    public func createRequest() -> NSPersistentStoreRequest {
        requestConfig.createStoreRequest()
    }
}
