//
//  RequestBuilder.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/20.
//

import CoreData

public protocol QueryerProtocol {
    func fetch<T: Entity>(for type: T.Type) -> ManagedFetchBuilder<T>
}

public protocol ReadOnlyQueryerProtocol {
    func fetch<T: Entity>(for type: T.Type) -> ReadOnlyFetchBuilder<T>
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

protocol RequestExecutor: AnyObject {
    associatedtype Received
    func exec() throws -> [Received]
    func execAsync(completion: @escaping ([Received]?, Error?) -> Void)
}

protocol NonThrowingRequestExecutor: RequestExecutor {
    func exec() -> [Received]
    func execAsync(completion: @escaping ([Received]) -> Void)
}

extension NonThrowingRequestExecutor {
    public func exec() throws -> [Received] {
        return exec()
    }

    public func execAsync(completion: @escaping ([Received]?, Error?) -> Void) {
        execAsync { received in
            completion(received, nil)
        }
    }
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

    public func `where`(_ predicateString: String, _ args: CVarArg...) -> Self {
        return `where`(NSPredicate(format: predicateString, argumentArray: args))
    }

    public func `where`(_ predicate: TypedPredicate<Target>) -> Self {
        return `where`(predicate as NSPredicate)
    }

    public func `where`(_ predicate: NSPredicate) -> Self {
        requestConfig.predicate = predicate
        return self
    }

    public func andWhere(_ predicateString: String, _ args: CVarArg...) -> Self {
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

    public func orWhere(_ predicateString: String, _ args: CVarArg...) -> Self {
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

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension RequestExecutor {
    public func execAsync() async throws -> [Received] {
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<[Received], Error>) in
            self.execAsync { value, error in
                guard let value = value else {
                    return continuation.resume(throwing: error!)
                }
                continuation.resume(returning: value)
            }
        }
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension NonThrowingRequestExecutor {
    public func execAsync() async -> [Received] {
        return await withCheckedContinuation {
            (continuation: CheckedContinuation<[Received], Never>) in
            self.execAsync { value in
                continuation.resume(returning: value)
            }
        }
    }
}

