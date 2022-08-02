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
    
    public func limit(_ size: Int) -> Self {
        config.modify { $0.fetchLimit = size }
        return self
    }

    public func offset(_ step: Int) -> Self {
        config.modify { $0.fetchOffset = step }
        return self
    }
    
    public func includesPendingChanges(_ flag: Bool = true) -> Self {
        config.includesPendingChanges = flag
        return self
    }

    public func prefetch<T: RelationshipProtocol>(relationship: KeyPath<Target, T>) -> Self {
        config.modify {
            $0.relationshipKeyPathsForPrefetching.initializeIfNeeded()
            $0.relationshipKeyPathsForPrefetching?.append(relationship.propertyName)
        }
        return self
    }

    public func sort<V: WritableValuedProperty>(
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
    
    public func asFaults(_ flag: Bool = true) -> Self {
        config.modify { $0.returnsObjectsAsFaults = flag }
        return self
    }
    
    internal func _includesSubentities(_ flag: Bool = true) -> Self {
        config.modify { $0.includesSubentities = flag }
        return self
    }
}

extension FetchBuilder {
    public func predicate(_ predicateString: String, _ args: CVarArg...) -> Self {
        return predicate(NSPredicate(format: predicateString, argumentArray: args))
    }

    public func predicate(_ pred: TypedPredicate<Target>) -> Self {
        return predicate(pred as NSPredicate)
    }

    /// It simply evaluates returned array by given predicate. Please be aware of that it has no effects to `count`, `exists`, and `batch`.
    public func predicate(_ predicate: NSPredicate) -> Self {
        config.postPredicate = predicate
        return self
    }

    public func andPredicate(_ predicateString: String, _ args: CVarArg...) -> Self {
        return andPredicate(NSPredicate(format: predicateString, argumentArray: args))
    }

    public func andPredicate(_ predicate: TypedPredicate<Target>) -> Self {
        return andPredicate(predicate as NSPredicate)
    }

    public func andPredicate(_ predicate: NSPredicate) -> Self {
        guard let oldPredicate = config.postPredicate else {
            config.postPredicate = predicate
            return self
        }
        config.postPredicate = oldPredicate && predicate
        return self
    }

    public func orPredicate(_ predicateString: String, _ args: CVarArg...) -> Self {
        return orPredicate(NSPredicate(format: predicateString, argumentArray: args))
    }

    public func orPredicate(_ predicate: TypedPredicate<Target>) -> Self {
        return orPredicate(predicate as NSPredicate)
    }

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
    @inlinable
    public func findOne() -> Received.Element? {
        let results: Received = limit(1).exec()
        return results.first
    }
    
    public func count() -> Int {
        config.modify { $0.resultType = .countResultType }
        return context.count(request: config.createFetchRequest())
    }

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
    
    /// Fetch only objectID of objects. `includesPropertyValues` is false by default.
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
            return nsArray.filtered(using: predicate) as! [ManagedObject<Target>]
        }
        return objects
    }
}

public class ArrayExecutableFetchBuilder<Target: Entity, Result>:
    ExecutableFetchBuilder<Target, [Result]>
{
    public func lazy() -> LazyFetchBuilder<Target, Result> {
        LazyFetchBuilder(builder: self)
    }
    
    public func batch(_ size: Int) -> LazyFetchBuilder<Target, Received.Element> {
        config.modify { $0.fetchBatchSize = size }
        return LazyFetchBuilder(builder: self)
    }
    
    public override func exec() -> [Result] {
        received().map(wrap(object:))
    }
}

public final class ManagedFetchBuilder<Target: Entity>:
    ArrayExecutableFetchBuilder<Target, Target.Managed>
{
    public func includesSubentities(_ flag: Bool = true) -> DriverFetchBuilder<Target> {
        DriverFetchBuilder(config: config, context: context)
            ._includesSubentities(flag)
    }
    
    override func wrap(object: NSManagedObject) -> ManagedObject<Target> {
        context.receive(object as! Target.Managed)
    }
}

public class ObjectProxyFetchBuilder<Target: Entity, Received>:
    ArrayExecutableFetchBuilder<Target, Received>
{
    public func includesSubentities(_ flag: Bool = true) -> Self {
        _includesSubentities(flag)
    }
}

public final class DriverFetchBuilder<Target: Entity>:
    ObjectProxyFetchBuilder<Target, Target.Driver>
{
    override func wrap(object: NSManagedObject) -> ManagedDriver<Target> {
        let object = context.receive(object)
        return object.unsafeDriver(entity: Target.self)
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

public final class LazyFetchBuilder<Target: Entity, Result>:
    ExecutableFetchBuilder<Target, LazyFetchResultCollection<Result>>
{
    private let builder: ExecutableFetchBuilder<Target, [Result]>
    
    public func batch(_ size: Int) -> Self {
        config.modify { $0.fetchBatchSize = size }
        return self
    }
    
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
