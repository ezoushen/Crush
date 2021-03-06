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
    private(set) var predicate: NSPredicate?
    private(set) var sorters: [NSSortDescriptor]?
    private(set) var resultType: NSFetchRequestResultType
    private(set) var groupBy: [Expressible]?
    private(set) var mapTo: [Expressible]?
    private(set) var limit: Int?
    private(set) var offset: Int?
    private(set) var batch: Int
    private(set) var asFaults: Bool
    private(set) var includePendingChanges: Bool
    
    init() {
        self.predicate = nil
        self.sorters = nil
        self.groupBy = nil
        self.mapTo = nil
        self.limit = nil
        self.offset = nil
        self.batch = 0
        self.asFaults = true
        self.resultType = .managedObjectResultType
        self.includePendingChanges = false
    }
    
    private init(predicate: NSPredicate?, limit: Int?, offset: Int?, batch: Int, sorters: [NSSortDescriptor]?, groupBy: [Expressible]?, mapTo: [Expressible]?, asFaults: Bool, resultType: NSFetchRequestResultType, includePendingChanges: Bool) {
        self.predicate = predicate
        self.sorters = sorters
        self.resultType = resultType
        self.groupBy = groupBy
        self.mapTo = mapTo
        self.limit = limit
        self.batch = batch
        self.asFaults = asFaults
        self.offset = offset
        self.includePendingChanges = includePendingChanges
    }
    
    func createFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityDescription().name ?? String(describing: T.self))
        request.sortDescriptors = sorters
        request.predicate = predicate
        request.propertiesToFetch = mapTo?.map{ $0.asExpression() }
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
    
    internal var _config: Config
    internal let _context: Context
    internal let _onUiContext: Bool
    
    internal required init(config: Config, context: Context, onUiContext: Bool) {
        self._config = config
        self._context = context
        self._onUiContext = onUiContext
    }
    
    public func limit(_ size: Int) -> PartialFetchBuilder<Target, Received, Result> {
        _config = _config.updated(\.limit, value: size)
        return self
    }

    public func offset(_ step: Int) -> PartialFetchBuilder<Target, Received, Result> {
        _config = _config.updated(\.offset, value: step)
        return self
    }
    
    public func batch(_ size: Int) -> PartialFetchBuilder<Target, Received, Result> {
        _config = _config.updated(\.batch, value: size)
        return self
    }
    
    public func includePendingChanges() -> Self {
        _config = _config.updated(\.includePendingChanges, value: true)
        return self
    }
    
    public func groupAndCount<V>(col name: KeyPath<Target, V>) -> PartialFetchBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> {
        let keypathExp = NSExpression(forKeyPath: name.stringValue)
        let countDesc = NSExpressionDescription()
        countDesc.name = "count"
        countDesc.expressionResultType = .integer64AttributeType
        countDesc.expression = NSExpression(forFunction: "count:",
                                            arguments: [keypathExp])
        let newConfig = _config
            .updated(\.groupBy, value: (_config.groupBy ?? []) + [name])
            .updated(\.mapTo, value: [name, countDesc])
            .updated(\.resultType, value: .dictionaryResultType)
        return .init(config: newConfig, context: _context, onUiContext: _onUiContext)
    }
    
    public func ascendingSort<V>(_ keyPath: KeyPath<Target, V>, type: FetchSorterOption = .default) -> PartialFetchBuilder<Target, Received, Result> {
        let descriptor = NSSortDescriptor(key: keyPath.stringValue, ascending: true, selector: type.selector)
        _config = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return self
    }
    
    public func descendingSort<V>(_ keyPath: KeyPath<Target, V>, type: FetchSorterOption = .default) -> PartialFetchBuilder<Target, Received, Result> {
        let descriptor = NSSortDescriptor(key: keyPath.stringValue, ascending: false, selector: type.selector)
        _config = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return self
    }
    
    public func ascendingSort<V>(_ keyPath: KeyPath<Target, V>, type: FetchSorterOption = .default) -> PartialFetchBuilder<Target, Received, Result> where V: FieldProtocol {
        let descriptor = NSSortDescriptor(key: keyPath.stringValue, ascending: true, selector: type.selector)
        _config = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return self
    }
    
    public func descendingSort<V>(_ keyPath: KeyPath<Target, V>, type: FetchSorterOption = .default) -> PartialFetchBuilder<Target, Received, Result> where V: FieldProtocol{
        let descriptor = NSSortDescriptor(key: keyPath.stringValue, ascending: false, selector: type.selector)
        _config = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return self
    }
    
    public func map<V>(_ keyPath: KeyPath<Target, V>) -> PartialFetchBuilder<Target, Dictionary<String, Any>, V> {
        let newConfig = _config.updated(\.mapTo, value: [keyPath]).updated(\.resultType, value: .dictionaryResultType)
        return .init(config: newConfig, context: _context, onUiContext: _onUiContext)
    }
    
    public func map<V>(_ keyPaths: [KeyPath<Target, V>]) -> PartialFetchBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> {
        let newConfig = _config.updated(\.mapTo, value: (_config.mapTo ?? []) + keyPaths).updated(\.resultType, value: .dictionaryResultType)
        return .init(config: newConfig, context: _context, onUiContext: _onUiContext)
    }

    public func `where`(_ predicate: NSPredicate) -> Self {
        _config = _config.updated(\.predicate, value: predicate)
        return self
    }
    
    public func andWhere(_ predicate: NSPredicate) -> Self {
        let newPredicate: NSPredicate = {
            if let pred = _config.predicate {
                return NSCompoundPredicate(andPredicateWithSubpredicates: [pred, predicate])
            }
            return predicate
        }()
        _config = _config.updated(\.predicate, value: newPredicate)
        return self
    }
    
    public func orWhere(_ predicate: NSPredicate) -> Self {
        let newPredicate: NSPredicate = {
            if let pred = _config.predicate {
                return NSCompoundPredicate(orPredicateWithSubpredicates: [pred, predicate])
            }
            return predicate
        }()
        _config = _config.updated(\.predicate, value: newPredicate)
        return self
    }
    
    public func asFaults(_ flag: Bool) -> Self {
        _config = _config.updated(\.asFaults, value: flag)
        return self
    }
}

extension PartialFetchBuilder: RequestBuilder {
    typealias Config = FetchConfig<Target>
    
    private func received() -> [Received] {
        let request = _config.createFetchRequest()
        return try! _context.execute(request: request, on: _config.includePendingChanges ? \.executionContext : \.rootContext)
    }
}

public class FetchBuilder<Target, Received, Result>: PartialFetchBuilder<Target, Received, Result> where Target: Entity {
    public func count() -> Int {
        let newConfig = _config.updated(\.resultType, value: .countResultType)
        let request = newConfig.createFetchRequest()
        return _context.count(request: request, on: _config.includePendingChanges ? \.executionContext : \.rootContext)
    }
}

extension PartialFetchBuilder where Result == Dictionary<String, Any>, Received == Result {
    public func exec() -> [Result] {
        received()
    }
}

extension PartialFetchBuilder where Result: HashableEntity, Received: NSManagedObject {
    public func exists() -> Bool {
        findOne() != nil
    }
    
    public func findOne() -> Result? {
        limit(1).exec().first
    }
    
    public func exec() -> [Result] {
        if _onUiContext {
            return received().compactMap {
                _context.present($0) as? Result
            }
        } else {
            return received().compactMap {
                _context.receive($0) as? Result
            }
        }
    }
}

extension PartialFetchBuilder where Target: HashableEntity, Result == Target.ReadOnly, Received == Target {
    public func exists() -> Bool {
        findOne() != nil
    }
    
    public func findOne() -> Result? {
        limit(1).exec().first
    }
    
    public func exec() -> [Result] {
        if _onUiContext {
            return received().map {
                Result(_context.present($0))
            }
        } else {
            return received().map {
                Result(_context.receive($0))
            }
        }
    }
}

extension PartialFetchBuilder where Received == Dictionary<String, Any> {
    public func exec() -> [Result] {
        received().flatMap{ $0.values }.compactMap{ $0 as? Result }
    }
}


extension NSExpressionDescription: Expressible {
    public func asExpression() -> Any {
        self
    }
}
