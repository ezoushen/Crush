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
    var predicate: NSPredicate? = nil
    var sorters: [NSSortDescriptor]? = nil
    var resultType: NSFetchRequestResultType = .managedObjectResultType
    var groupBy: [Expressible]? = nil
    var prefetched: [Expressible]? = nil
    var limit: Int? = nil
    var offset: Int? = nil
    var batch: Int = 0
    var asFaults: Bool = true
    var includePendingChanges: Bool = false

    var postPredicate: NSPredicate? = nil

    func createStoreRequest() -> NSPersistentStoreRequest {
        let request = Entity.fetchRequest()
        configureRequest(request)
        return request
    }

    func configureRequest(_ request: NSFetchRequest<NSFetchRequestResult>) {
        request.sortDescriptors = sorters
        request.predicate = predicate
        request.propertiesToFetch = prefetched?.map{ $0.asExpression() }
        request.propertiesToGroupBy = groupBy?.map{ $0.asExpression() }
        request.resultType = resultType
        request.fetchLimit = limit ?? 0
        request.fetchOffset = offset ?? 0
        request.returnsObjectsAsFaults = asFaults
        request.includesPendingChanges = true
        request.fetchBatchSize = batch
    }
}

public final class FetchBuilder<Target, Received>: PredicateRequestBuilder<Target>
where
    Target: Entity
{
    internal let context: Context
    internal var config: FetchConfig<Target> {
        @inline(__always) get { requestConfig as! FetchConfig<Target> }
        @inline(__always) set { requestConfig = newValue }
    }

    internal required init(config: FetchConfig<Target>, context: Context) {
        self.context = context
        super.init(config: config)
    }
    
    public func limit(_ size: Int) -> FetchBuilder<Target, Received> {
        config.limit = size
        return self
    }

    public func offset(_ step: Int) -> FetchBuilder<Target, Received> {
        config.offset = step
        return self
    }
    
    public func batch(_ size: Int) -> FetchBuilder<Target, Received> {
        config.batch = size
        return self
    }
    
    public func includePendingChanges() -> Self {
        config.includePendingChanges = true
        return self
    }

    public func sort<V: WritableValuedProperty>(
        _ keyPath: KeyPath<Target, V>,
        ascending: Bool,
        option: FetchSorterOption = .default
    ) -> FetchBuilder<Target, Received> {
        let sorters = config.sorters ?? []
        let descriptor = NSSortDescriptor(
            key: keyPath.propertyName,
            ascending: ascending,
            selector: option.selector)
        config.sorters = sorters + [descriptor]
        return self
    }

    public func select(
        _ keyPaths: PartialKeyPath<Target>...
    ) -> FetchBuilder<Target, Received> {
        let fetched = config.prefetched ?? []
        let expressibles = keyPaths.compactMap{ $0 as? Expressible }
        config.prefetched = fetched + expressibles
        config.asFaults = true
        return self
    }
    
    public func asFaults(_ flag: Bool) -> Self {
        config.asFaults = flag
        return self
    }

    public func count() -> Int {
        config.resultType = .countResultType
        return context.count(
            request: config.createStoreRequest() as! NSFetchRequest<NSFetchRequestResult>,
            on: config.includePendingChanges
                ? \.executionContext
                : \.rootContext)
    }

    private func received() -> [ManagedObject<Target>] {
        let objects: [ManagedObject<Target>] = try! context.execute(
            request: config.createStoreRequest() as! NSFetchRequest<NSFetchRequestResult>,
            on: config.includePendingChanges
                ? \.executionContext
                : \.rootContext)
        if let predicate = config.postPredicate {
            return (objects as NSArray).filtered(using: predicate) as! [ManagedObject<Target>]
        }
        return objects
    }
}

extension FetchBuilder {
    public func predicate(_ predicateString: String, _ args: CVarArg...) -> Self {
        return predicate(NSPredicate(format: predicateString, argumentArray: args))
    }

    public func predicate(_ pred: TypedPredicate<Target>) -> Self {
        return predicate(pred as NSPredicate)
    }

    public func predicate(_ predicate: NSPredicate) -> Self {
        config.postPredicate = predicate
        return self
    }

    public func andPredicate(_ predicateString: String, _ args: CVarArg...) -> Self {
        return andPredicate(TypedPredicate(format: predicateString))
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
        return orPredicate(TypedPredicate(format: predicateString))
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

extension FetchBuilder where
    Received == ManagedObject<Target>
{
    public func exists() -> Bool {
        findOne() != nil
    }

    public func findOne() -> Received? {
        limit(1).exec().first
    }
    
    public func exec() -> [Received] {
        received().map {
            let object = context.receive($0)
            if config.includePendingChanges {
                return object
            }
            object.awakeFromFetch()
            return object
        }
    }
}

extension FetchBuilder where
    Received == ReadOnly<Target>
{
    public func exists() -> Bool {
        findOne() != nil
    }

    public func findOne() -> Received? {
        limit(1).exec().first
    }

    public func exec() -> [Received] {
        received().map { ReadOnly<Target>(context.present($0)) }
    }
}

extension NSExpressionDescription: Expressible {
    public func asExpression() -> Any {
        self
    }
}
