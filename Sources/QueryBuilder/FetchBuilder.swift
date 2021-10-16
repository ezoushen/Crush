//
//  PartialQueryBuilder.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/1/17.
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

public struct FetchConfig<T: Entity>: RequestConfig {
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
    
    func createStoreRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityDescription().name ?? String(describing: T.self))
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
        return request
    }
}

public class PartialFetchBuilder<Target, Received, Result> where Target: Entity {
    
    internal var config: Config
    internal let context: Context
    internal let onUiContext: Bool
    
    internal required init(config: Config, context: Context, onUiContext: Bool) {
        self.config = config
        self.context = context
        self.onUiContext = onUiContext
    }
    
    public func limit(_ size: Int) -> PartialFetchBuilder<Target, Received, Result> {
        config.limit = size
        return self
    }

    public func offset(_ step: Int) -> PartialFetchBuilder<Target, Received, Result> {
        config.offset = step
        return self
    }
    
    public func batch(_ size: Int) -> PartialFetchBuilder<Target, Received, Result> {
        config.batch = size
        return self
    }
    
    public func includePendingChanges() -> Self {
        config.includePendingChanges = true
        return self
    }
    
    public func groupAndCount<V: ValuedProperty>(
        col keyPath: KeyPath<Target, V>
    ) -> PartialFetchBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> {
        let name = keyPath.propertyName
        let keypathExp = NSExpression(forKeyPath: name)
        let countDesc = NSExpressionDescription()
        countDesc.name = "count"
        countDesc.expressionResultType = .integer64AttributeType
        countDesc.expression = NSExpression(forFunction: "count:",
                                            arguments: [keypathExp])
        let groupBy = config.groupBy ?? []
        config.groupBy = groupBy + [keyPath]
        config.prefetched = [keyPath, countDesc]
        config.resultType = .dictionaryResultType
        return .init(
            config: config,
            context: context,
            onUiContext: onUiContext)
    }

    public func sort<V: ValuedProperty>(
        _ keyPath: KeyPath<Target, V>,
        ascending: Bool,
        option: FetchSorterOption = .default
    ) -> PartialFetchBuilder<Target, Received, Result> {
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
    ) -> PartialFetchBuilder<Target, Received, Result> {
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
}

extension PartialFetchBuilder: RequestBuilder {
    typealias Config = FetchConfig<Target>
    
    private func received() -> [Received] {
        let request = config.createStoreRequest()
        return try! context.execute(
            request: request,
            on: config.includePendingChanges
                ? \.executionContext
                : \.rootContext)
    }
}

public class FetchBuilder<Target, Received, Result>:
    PartialFetchBuilder<Target, Received, Result> where Target: Entity
{
    public func count() -> Int {
        config.resultType = .countResultType
        return context.count(
            request: config.createStoreRequest(),
            on: config.includePendingChanges
                ? \.executionContext
                : \.rootContext)
    }
}

extension PartialFetchBuilder where Received == Result {
    public func exec() -> [Result] {
        received()
    }
}

extension PartialFetchBuilder where
    Target: Entity,
    Result == ReadOnly<Target>,
    Received == ManagedObject<Target>
{
    public func exists() -> Bool {
        findOne() != nil
    }
    
    public func findOne() -> Result? {
        limit(1).exec().first
    }
    
    public func exec() -> [Result] {
        onUiContext
            ? received().map { ReadOnly<Target>(context.present($0)) }
            : received().map { ReadOnly<Target>(context.receive($0)) }
    }
}

extension NSExpressionDescription: Expressible {
    public func asExpression() -> Any {
        self
    }
}
