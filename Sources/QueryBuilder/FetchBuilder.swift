//
//  PartialQueryBuilder.swift
//  Crush
//
//  Created by ezou on 2020/1/17.
//  Copyright © 2020 ezou. All rights reserved.
//

import CoreData

public enum FetchSorterOption {
    case `default`
    case caseInsensitive
    case localized
    case localizedStandard
    case localizedCaseInsensitive
    
    var selector: Selector {
        switch self {
        case .default:                      return #selector(NSString.compare(_:))
        case .caseInsensitive:              return #selector(NSString.caseInsensitiveCompare(_:))
        case .localized:                    return #selector(NSString.localizedCompare(_:))
        case .localizedStandard:            return #selector(NSString.localizedStandardCompare(_:))
        case .localizedCaseInsensitive:     return #selector(NSString.localizedCaseInsensitiveCompare(_:))
        }
    }
}

public struct FetchConfig<Entity: Crush.Entity>: RequestConfig {
    typealias Modifier = (NSFetchRequest<NSFetchRequestResult>) -> Void

    var predicate: NSPredicate? = nil
    var includesPendingChanges: Bool = false
    var postPredicate: NSPredicate? = nil

    var modifier: (Modifier)? = nil

    func createStoreRequest() -> NSPersistentStoreRequest {
        createFetchRequest()
    }

    func createFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let request = Entity.fetchRequest()
        configureRequest(request)
        return request
    }

    func configureRequest(_ request: NSFetchRequest<NSFetchRequestResult>) {
        modifier?(request)
        request.includesPendingChanges = includesPendingChanges
        request.predicate = predicate
    }

    mutating func modify(_ block: @escaping Modifier) {
        let prevBlock = modifier
        modifier = {
            if let prevBlock = prevBlock {
                prevBlock($0)
            }
            block($0)
        }
    }
}

public class FetchBuilder<Target>: PredicateRequestBuilder<Target>
where
    Target: Entity
{
    internal let context: Context
    internal var config: FetchConfig<Target> {
        get { requestConfig as! FetchConfig<Target> }
        set { requestConfig = newValue }
    }

    internal required init(config: FetchConfig<Target>, context: Context) {
        self.context = context
        super.init(config: config)
    }

    /// Equivalent to `fetchLimit` to `NSFetchRequest.fetchLimit`
    public func limit(_ size: Int) -> Self {
        config.modify { $0.fetchLimit = size }
        return self
    }

    /// Equivalent to `fetchOffset` to `NSFetchRequest.fetchOffset`
    public func offset(_ step: Int) -> Self {
        config.modify { $0.fetchOffset = step }
        return self
    }

    /// Equivalent to `includesPendingChanges` to `NSFetchRequest.includesPendingChanges`
    public func includesPendingChanges(_ flag: Bool = true) -> Self {
        config.includesPendingChanges = flag
        return self
    }

    /// Prefetch related entities according to specified relationship
    public func prefetch<T: RelationshipProtocol>(relationship: KeyPath<Target, T>) -> Self {
        config.modify {
            $0.relationshipKeyPathsForPrefetching.initializeIfNeeded()
            $0.relationshipKeyPathsForPrefetching?.append(relationship.propertyName)
        }
        return self
    }

    /**
    Sorts the fetch result by given `keyPath`.

    - Parameters:
     - keyPath: The key path to sort fetch result by.
     - ascending: A Boolean value that determines whether fetch result should be sorted in ascending or descending order.
     - option: An option to control sorting behavior.
     */
    public func sort<V: WritableProperty>(
        _ keyPath: KeyPath<Target, V>,
        ascending: Bool,
        option: FetchSorterOption = .default) -> Self
    {
        config.modify {
            let descriptor = NSSortDescriptor(
                key: keyPath.propertyName,
                ascending: ascending,
                selector: option.selector)
            let sorters = ($0.sortDescriptors ?? []) + [descriptor]
            $0.sortDescriptors = sorters
        }
        return self
    }

    /// Equivalent to `returnsObjectsAsFaults` to `NSFetchRequest.returnsObjectsAsFaults`
    public func asFaults(_ flag: Bool = true) -> Self {
        config.modify { $0.returnsObjectsAsFaults = flag }
        return self
    }
    
    internal func _includesSubentities(_ flag: Bool = true) -> Self {
        config.modify { $0.includesSubentities = flag }
        return self
    }

    /// Adds one or more key paths to the select clause.
    /// - Parameter keyPaths: The key paths to add to the select clause.
    public func select(_ keyPaths: PartialKeyPath<Target>...) -> Self {
        select(keyPaths)
    }

    /// Adds an array of key paths to the select clause.
    /// - Parameter keyPaths: An array of key paths to add to the select clause.
    public func select(_ keyPaths: [PartialKeyPath<Target>]) -> Self {
        config.modify {
            for keyPath in keyPaths {
                guard let expressible = keyPath as? Expressible else { continue }
                $0.fetch(property: expressible)
            }
        }
        return self
    }
    /// Sets the flag indicating whether the refetched objects should be refreshed.
    /// - Parameter flag: A boolean value indicating whether to refresh refetched objects. Default is true.
    /// - Returns: The FetchBuilder instance.
    public func refreshRefetchedObjects(_ flag: Bool = true) -> Self {
        config.modify { $0.shouldRefreshRefetchedObjects = flag }
        return self
    }
}

extension FetchBuilder {
    /**
     Sets the predicate to be applied to the fetch request.

     - Note: This method only applies the predicate and has no effect on ``ExecutableFetchBuilder/count()``, ``ExecutableFetchBuilder/exists()``, and ``ArrayExecutableFetchBuilder/batch(_:)`` methods.

     - Parameters:
        - predicateString: A predicate string.
        - args: Arguments used to evaluate the predicate string.
     */
    public func predicate(_ predicateString: String, _ args: CVarArg...) -> Self {
        return predicate(NSPredicate(format: predicateString, argumentArray: args))
    }

    /**
     Sets the predicate to be applied to the fetch request.

     - Note: This method only applies the predicate and has no effect on ``ExecutableFetchBuilder/count()``, ``ExecutableFetchBuilder/exists()``, and ``ArrayExecutableFetchBuilder/batch(_:)`` methods.

     - Parameters pred: A predicate to be applied to the fetch request.
     */
    public func predicate(_ pred: TypedPredicate<Target>) -> Self {
        return predicate(pred as NSPredicate)
    }

    /**
     Sets the predicate to be applied to the fetch request.

     - Note: This method only applies the predicate and has no effect on ``ExecutableFetchBuilder/count()``, ``ExecutableFetchBuilder/exists()``, and ``ArrayExecutableFetchBuilder/batch(_:)`` methods.

     - Parameters pred: A predicate to be applied to the fetch request.
     */
    public func predicate(_ predicate: NSPredicate) -> Self {
        config.postPredicate = predicate
        return self
    }

    /**
    Sets the predicate to be applied to the fetch request using `AND` operator.

    - Note: This method only applies the predicate and has no effect on ``ExecutableFetchBuilder/count()``, ``ExecutableFetchBuilder/exists()``, and ``ArrayExecutableFetchBuilder/batch(_:)`` methods.

    - Parameters:
     - predicateString: A predicate string.
     - args: Arguments used to evaluate the predicate string.
     */
    public func andPredicate(_ predicateString: String, _ args: CVarArg...) -> Self {
        return andPredicate(NSPredicate(format: predicateString, argumentArray: args))
    }

    /**
     Sets the predicate to be applied to the fetch request using `AND` operator.

     - Note: This method only applies the predicate and has no effect on ``ExecutableFetchBuilder/count()``, ``ExecutableFetchBuilder/exists()``, and ``ArrayExecutableFetchBuilder/batch(_:)`` methods.

     - Parameters pred: A predicate to be applied to the fetch request.
     */
    public func andPredicate(_ predicate: TypedPredicate<Target>) -> Self {
        return andPredicate(predicate as NSPredicate)
    }

    /**
     Sets the predicate to be applied to the fetch request using `AND` operator.

     - Note: This method only applies the predicate and has no effect on ``ExecutableFetchBuilder/count()``, ``ExecutableFetchBuilder/exists()``, and ``ArrayExecutableFetchBuilder/batch(_:)`` methods.

     - Parameters pred: A predicate to be applied to the fetch request.
     */
    public func andPredicate(_ predicate: NSPredicate) -> Self {
        guard let oldPredicate = config.postPredicate else {
            config.postPredicate = predicate
            return self
        }
        config.postPredicate = oldPredicate && predicate
        return self
    }

    /**
    Sets the predicate to be applied to the fetch request using OR operator.

    - Note: This method only applies the predicate and has no effect on ``ExecutableFetchBuilder/count()``, ``ExecutableFetchBuilder/exists()``, and ``ArrayExecutableFetchBuilder/batch(_:)`` methods.

    - Parameters:
     - predicateString: A predicate string.
     - args: Arguments used to evaluate the predicate string.
     */
    public func orPredicate(_ predicateString: String, _ args: CVarArg...) -> Self {
        return orPredicate(NSPredicate(format: predicateString, argumentArray: args))
    }

    /**
     Sets the predicate to be applied to the fetch request using OR operator.

     - Note: This method only applies the predicate and has no effect on ``ExecutableFetchBuilder/count()``, ``ExecutableFetchBuilder/exists()``, and ``ArrayExecutableFetchBuilder/batch(_:)`` methods.

     - Parameters pred: A predicate to be applied to the fetch request.
     */
    public func orPredicate(_ predicate: TypedPredicate<Target>) -> Self {
        return orPredicate(predicate as NSPredicate)
    }

    /**
     Sets the predicate to be applied to the fetch request using OR operator.

     - Note: This method only applies the predicate and has no effect on ``ExecutableFetchBuilder/count()``, ``ExecutableFetchBuilder/exists()``, and ``ArrayExecutableFetchBuilder/batch(_:)`` methods.

     - Parameters pred: A predicate to be applied to the fetch request.
     */
    public func orPredicate(_ predicate: NSPredicate) -> Self {
        guard let oldPredicate = config.postPredicate else {
            config.postPredicate = predicate
            return self
        }
        config.postPredicate = oldPredicate || predicate
        return self
    }
}

public class ExecutableFetchBuilder<Target: Entity, Received: Collection>:
    FetchBuilder<Target>,
    NonThrowingRequestExecutor
{
    /// Fetch the first object matching the predicate
    @inlinable
    public func findOne() -> Received.Element? {
        let results: Received = limit(1).exec()
        return results.first
    }

    /// Count objects matching the predicate
    public func count() -> Int {
        config.modify { $0.resultType = .countResultType }
        return context.count(request: config.createFetchRequest())
    }

    /// Check if any object matching the predicate
    public func exists() -> Bool {
        limit(1).count() > 0
    }
    
    internal func wrap(object: NSManagedObject) -> Received.Element {
        fatalError("unimplemented")
    }

    public func exec() -> Received {
        fatalError("unimplemented")
    }

    public func execAsync(completion: @escaping (Received) -> Void) {
        let context = context.executionContext
        context.performAsync {
            let result: Received = self.exec()
            completion(result)
        }
    }
    
    /// Fetches only the `NSManagedObjectID` of the objects.
    ///
    /// - Parameter includesPropertyValues: A flag indicating whether property values should be included.
    public func objectIDs(includesPropertyValues flag: Bool = false) -> [NSManagedObjectID] {
        config.modify {
            $0.includesPropertyValues = flag
            $0.resultType = .managedObjectIDResultType
        }
        return try! context.execute(request: config.createFetchRequest())
    }
    
    fileprivate func received() -> [NSManagedObject] {
        let request = config.createFetchRequest()
        let objects: [NSManagedObject] = try! context.execute(request: request)
        if let predicate = config.postPredicate {
            let nsArray = objects as NSArray
            return nsArray.filtered(using: predicate) as! [NSManagedObject]
        }
        return objects
    }
}

public class ArrayExecutableFetchBuilder<Target: Entity, Result>:
    ExecutableFetchBuilder<Target, [Result]>
{
    /// Convert the fetch builder into ``LazyFetchBuilder``
    public func lazy() -> LazyFetchBuilder<Target, Result> {
        LazyFetchBuilder(builder: self)
    }

    /// Convert the fetch builder into ``LazyFetchBuilder`` with fetching batch size specified
    public func batch(_ size: Int) -> LazyFetchBuilder<Target, Received.Element> {
        config.modify { $0.fetchBatchSize = size }
        return LazyFetchBuilder(builder: self)
    }
    
    public override func exec() -> [Result] {
        received().map(wrap(object:))
    }
}

public final class ManagedFetchBuilder<Target: Entity>:
    ArrayExecutableFetchBuilder<Target, Target.Driver>
{
    /**
     Sets whether subentities should be included in the fetch request.

     - Parameters flag: A boolean indicating whether subentities should be included. Defaults to `true`.
     */
    public func includesSubentities(_ flag: Bool = true) -> DriverFetchBuilder<Target> {
        DriverFetchBuilder(config: config, context: context)
            ._includesSubentities(flag)
    }
    
    override func wrap(object: NSManagedObject) -> Target.Driver {
        Target.Driver(unsafe: context.receive(object))
    }

    /// Return immutable `ReadOnly<Target>` as fetch result rather than mutable object,
    /// - note: Returned `ReadOnly<Target>` will be presented in execution context instead of ui context
    public func asReadOnly() -> ReadOnlyFetchBuilder<Target> {
        ReadOnlyFetchBuilder(
            config: config,
            context: SessionContext(
                executionContext: context.executionContext,
                uiContext: context.executionContext))
    }
}

public class ObjectProxyFetchBuilder<Target: Entity, Received>:
    ArrayExecutableFetchBuilder<Target, Received>
{
    /**
     Sets whether subentities should be included in the fetch request.

     - Parameters flag: A boolean indicating whether subentities should be included. Defaults to `true`.
     */
    public func includesSubentities(_ flag: Bool = true) -> Self {
        _includesSubentities(flag)
    }
}

public final class DriverFetchBuilder<Target: Entity>:
    ObjectProxyFetchBuilder<Target, Target.Driver>
{
    override func wrap(object: NSManagedObject) -> Target.Driver {
        let object = context.receive(object)
        return object.unsafeCast(to: Target.self)
    }
}

public final class ReadOnlyFetchBuilder<Target: Entity>:
    ObjectProxyFetchBuilder<Target, Target.ReadOnly>
{
    override func wrap(object: NSManagedObject) -> ReadOnly<Target> {
        ReadOnly<Target>(object: context.present(object))
    }
}

public typealias LazyFetchResultCollection<T> = LazyMapSequence<[NSManagedObject], T>

extension LazyMapSequence where Base == [NSManagedObject] {
    public static var empty: Self {
        [].lazy.map { _ in fatalError("Unimplemented") }
    }
}

/// A fetch builder that returns a lazy sequence of fetch results.
///
/// The fetch result is wrapped lazily which might become handy if you're not so sure whether the result would be totaly iterated or not.
public final class LazyFetchBuilder<Target: Entity, Result>:
    ExecutableFetchBuilder<Target, LazyFetchResultCollection<Result>>
{
    private let builder: ExecutableFetchBuilder<Target, [Result]>

    /// Specifies the size of the batch to fetch.
    ///
    /// - Parameter size: The size of the batch to fetch.
    public func batch(_ size: Int) -> Self {
        config.modify { $0.fetchBatchSize = size }
        return self
    }

    /// Specifies whether the fetch request should include subentities.
    ///
    /// - Parameter flag: A flag indicating whether to include subentities in the fetch request. Defaults to `true`.
    public func includesSubentities(_ flag: Bool = true) -> LazyFetchBuilder<Target, Target.Driver> {
        LazyFetchBuilder<Target, Target.Driver>(
            builder: DriverFetchBuilder(config: config, context: context)
        )
            ._includesSubentities(flag)
    }

    init(builder: ExecutableFetchBuilder<Target, [Result]>) {
        self.builder = builder
        super.init(config: builder.config, context: builder.context)
    }

    internal required init(config: FetchConfig<Target>, context: FetchBuilder<Target>.Context) {
        builder = ExecutableFetchBuilder(config: config, context: context)
        super.init(config: config, context: context)
    }

    override func received() -> [NSManagedObject] {
        builder.config = config
        return builder.received()
    }

    public override func exec() -> LazyFetchResultCollection<Result> {
        received().lazy.map { self.builder.wrap(object:$0) }
    }
}
