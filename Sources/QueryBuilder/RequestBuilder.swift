//
//  RequestBuilder.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/20.
//

import CoreData

public protocol QueryerProtocol {
    /**
     Returns a builder for a fetch request on a given Entity type.

     - Parameter type: The type of Entity being fetched.

     - Returns: A `ManagedFetchBuilder` for the given Entity type.
     */
    func fetch<T: Entity>(for type: T.Type) -> ManagedFetchBuilder<T>
}

public protocol ReadOnlyQueryerProtocol {
    /**
     Returns a builder for a read-only fetch request on a given Entity type.

     - Parameter type: The type of Entity being fetched.

     - Returns: A `ReadOnlyFetchBuilder` for the given Entity type.
     */
    func fetch<T: Entity>(for type: T.Type) -> ReadOnlyFetchBuilder<T>
}

public protocol MutableQueryerProtocol {
    /**
     Returns a builder for an insert operation on a given Entity type.

     The changes will be committed into persistent store.

     - Parameter type: The type of Entity being inserted.

     - Returns: An `InsertBuilder` for the given Entity type.
     */
    func insert<T: Entity>(for type: T.Type) -> InsertBuilder<T>

    /**
     Returns a builder for an update operation on a given Entity type.

     The changes will be committed into persistent store.

     - Parameter type: The type of Entity being updated.

     - Returns: An `UpdateBuilder` for the given Entity type.
     */
    func update<T: Entity>(for type: T.Type) -> UpdateBuilder<T>

    /**
     Returns a builder for a delete operation on a given Entity type.

     The changes will be committed into persistent store.

     - Parameter type: The type of Entity being deleted.

     - Returns: A `DeleteBuilder` for the given Entity type.
     */
    func delete<T: Entity>(for type: T.Type) -> DeleteBuilder<T>
}

protocol RequestConfig {
    var predicate: NSPredicate? { get set }
    func createStoreRequest() -> NSPersistentStoreRequest
}

public protocol RequestExecutor: AnyObject {
    associatedtype Received

    /// Executes the persisten store request and returns the result.
    func exec() throws -> Received
    /// Executes the persisten store request asynchronously and calls the completion handler with the result.
    func execAsync(completion: @escaping (Received?, Error?) -> Void)
}

/// A protocol defining an executor for a Core Data fetch request that does not throw an error.
public protocol NonThrowingRequestExecutor: RequestExecutor {
    /// Executes the fetch request and returns the result without throwing an error.
    func exec() -> Received
    /// Executes the fetch request asynchronously and calls the completion handler with the result.
    func execAsync(completion: @escaping (Received) -> Void)
}

extension NonThrowingRequestExecutor {
    public func exec() throws -> Received {
        return exec()
    }

    public func execAsync(completion: @escaping (Received?, Error?) -> Void) {
        execAsync { received in
            completion(received, nil)
        }
    }
}

protocol RequestBuilder: AnyObject {
    typealias Context = SessionContext
    associatedtype Target: Entity
}

/**
 A builder class for constructing `NSPersistentStoreRequest` instances with a predicate.

 The `PredicateRequestBuilder` class is used to create instances of `NSPersistentStoreRequest` with a predicate. It conforms to the `RequestBuilder` protocol, which defines the basic interface for constructing `NSPersistentStoreRequest` instances.
*/
public class PredicateRequestBuilder<Target: Entity>: RequestBuilder {
    internal var requestConfig: RequestConfig

    internal init(config: RequestConfig) {
        self.requestConfig = config
    }

    /**
     Adds a predicate to the request being built by creating a `NSPredicate` from the given format string and arguments.

     - Parameter predicateString: The format string for the predicate.
     - Parameter args: The arguments to use when creating the predicate.
     */
    public func `where`(_ predicateString: String, _ args: CVarArg...) -> Self {
        return `where`(NSPredicate(format: predicateString, argumentArray: args))
    }

    /**
     Adds a typed predicate to the request being built.

     - Parameter predicate: The typed predicate to add to the request.
     */
    public func `where`(_ predicate: TypedPredicate<Target>) -> Self {
        return `where`(predicate as NSPredicate)
    }

    /**
     Adds a predicate to the request being built.

     - Parameter predicate: The predicate to add to the request.
     */
    public func `where`(_ predicate: NSPredicate) -> Self {
        requestConfig.predicate = predicate
        return self
    }

    /**
     Adds a predicate to the request being built using an `AND` operator.

     If there is no existing predicate on the request, the given predicate is added directly.

     If there is an existing predicate, the given predicate is combined with the existing predicate using an `AND` operator.

     - Parameter predicateString: The format string for the predicate.
     - Parameter args: The arguments to use when creating the predicate.
     */
    public func andWhere(_ predicateString: String, _ args: CVarArg...) -> Self {
        return andWhere(TypedPredicate(format: predicateString))
    }

    /**
     Adds a typed predicate to the request being built using an `AND` operator.

     If there is no existing predicate on the request, the given predicate is added directly.

     If there is an existing predicate, the given predicate is combined with the existing predicate using an `AND` operator.

     - Parameter predicate: The typed predicate to add to the request.
     */
    public func andWhere(_ predicate: TypedPredicate<Target>) -> Self {
        return andWhere(predicate as NSPredicate)
    }


    /**
     A method that adds a new predicate to the current builder by logically combining it with the previous predicate using `AND` operation.

     If there is no previous predicate, then the provided predicate is simply set as the current predicate.

     - Parameter predicate: The new predicate that needs to be combined with the existing predicate using the `AND` operation.
     */
    public func andWhere(_ predicate: NSPredicate) -> Self {
        guard let oldPredicate = requestConfig.predicate else {
            requestConfig.predicate = predicate
            return self
        }
        requestConfig.predicate = oldPredicate && predicate
        return self
    }

    /**
    A method that adds a new predicate to the current builder by logically combining it with the previous predicate using `OR` operation.

    If there is no previous predicate, then the provided predicate is simply set as the current predicate.

    - Parameters predicateString: The format string for the new predicate that needs to be combined with the existing predicate using the `OR` operation.
    - Parameters args: The arguments that are used in the format string.
    */
    public func orWhere(_ predicateString: String, _ args: CVarArg...) -> Self {
        return orWhere(TypedPredicate(format: predicateString))
    }

    /**
    A method that adds a new predicate to the current builder by logically combining it with the previous predicate using `OR` operation.

    If there is no previous predicate, then the provided predicate is simply set as the current predicate.

    - Parameters predicate: The new predicate that needs to be combined with the existing predicate using the `OR` operation.
     */
    public func orWhere(_ predicate: TypedPredicate<Target>) -> Self {
        return orWhere(predicate as NSPredicate)
    }

    /**
     A method that adds a new predicate to the current builder by logically combining it with the previous predicate using `OR` operation.

     If there is no previous predicate, then the provided predicate is simply set as the current predicate.

     - Parameters predicate: The new predicate that needs to be combined with the existing predicate using the `OR` operation.
     */
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
#if canImport(_Concurrency) && compiler(>=5.5.2)
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension RequestExecutor {
    /// Executes the persisten store request asynchronously and calls the completion handler with the result.
    public func execAsync() async throws -> Received {
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Received, Error>) in
            self.execAsync { value, error in
                if let error = error {
                    return continuation.resume(throwing: error)
                }
                continuation.resume(returning: value!)
            }
        }
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
extension NonThrowingRequestExecutor {
    /// Executes the persisten store request asynchronously
    public func execAsync() async -> Received {
        return await withCheckedContinuation {
            (continuation: CheckedContinuation<Received, Never>) in
            self.execAsync { value in
                continuation.resume(returning: value)
            }
        }
    }
}
#endif
