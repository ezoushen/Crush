//
//  PartialQueryBuilder.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/1/17.
//  Copyright © 2020 ezou. All rights reserved.
//

import CoreData

public protocol QueryerProtocol {
    func query<T: Entity>(for type: T.Type) -> Query<T>
}

public enum QuerySorterOption {
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

internal struct QueryConfig<T: Entity> {
    private(set) var predicate: NSPredicate?
    private(set) var sorters: [NSSortDescriptor]?
    private(set) var resultType: NSFetchRequestResultType
    private(set) var groupBy: [Expressible]?
    private(set) var mapTo: [Expressible]?
    private(set) var limit: Int?
    private(set) var offset: Int?
    private(set) var asFaults: Bool
    
    init() {
        self.predicate = nil
        self.sorters = nil
        self.groupBy = nil
        self.mapTo = nil
        self.limit = nil
        self.offset = nil
        self.asFaults = true
        self.resultType = .managedObjectResultType
    }
    
    private init(predicate: NSPredicate?, limit: Int?, offset: Int?,  sorters: [NSSortDescriptor]?, groupBy: [Expressible]?, mapTo: [Expressible]?, asFaults: Bool, resultType: NSFetchRequestResultType) {
        self.predicate = predicate
        self.sorters = sorters
        self.resultType = resultType
        self.groupBy = groupBy
        self.mapTo = mapTo
        self.limit = limit
        self.asFaults = asFaults
        self.offset = offset
    }
    
    func updated<V>(_ keyPath: KeyPath<Self, V>, value: V) -> Self {
        guard let keyPath = keyPath as? WritableKeyPath<Self, V> else { return self }
        
        var config = Self.init(predicate: predicate, limit: limit, offset: offset, sorters: sorters, groupBy: groupBy, mapTo: mapTo, asFaults: asFaults, resultType: resultType)
        config[keyPath: keyPath] = value
        return config
    }
    
    func createFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityDescription().name ?? String(describing: T.self))
        request.sortDescriptors = sorters
        request.predicate = predicate
        request.propertiesToFetch = mapTo?.map{ $0.asExpression() }
        request.propertiesToGroupBy = groupBy?.map{ $0.asExpression() }
        request.resultType = resultType
        request.fetchLimit = limit ?? .max
        request.fetchOffset = offset ?? 0
        request.returnsObjectsAsFaults = asFaults
        return request
    }
}

public class PartialQueryBuilder<Target, Received, Result> where Target: Entity {
    internal var _config: QueryConfig<Target>
    
    internal let _context: ReaderTransactionContext & RawContextProviderProtocol

    internal required init(config: QueryConfig<Target>, context: ReaderTransactionContext & RawContextProviderProtocol) {
        self._config = config
        self._context = context
    }
}

public class QueryBuilder<Target, Received, Result>: PartialQueryBuilder<Target, Received, Result> where Target: Entity { }

extension QueryBuilder {
    public func count() -> Int {
        let newConfig = _config.updated(\.resultType, value: .countResultType)
        let request = newConfig.createFetchRequest()
        return _context.count(request: request)
    }
}

extension PartialQueryBuilder {
    public func limit(_ size: Int) -> PartialQueryBuilder<Target, Received, Result> {
        _config = _config.updated(\.limit, value: size)
        return self
    }

    public func offset(_ step: Int) -> PartialQueryBuilder<Target, Received, Result> {
        _config = _config.updated(\.offset, value: step)
        return self
    }
    
    public func groupAndCount<T>(col name: T) -> PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> where T : TracableKeyPathProtocol, T.Root == Target {
        let keypathExp = NSExpression(forKeyPath: name.fullPath)
        let countDesc = NSExpressionDescription()
        countDesc.name = "count"
        countDesc.expressionResultType = .integer64AttributeType
        countDesc.expression = NSExpression(forFunction: "count:",
                                            arguments: [keypathExp])
        let newConfig = _config
            .updated(\.groupBy, value: (_config.groupBy ?? []) + [name])
            .updated(\.mapTo, value: [name, countDesc])
            .updated(\.resultType, value: .dictionaryResultType)
        return .init(config: newConfig, context: _context)
    }
    
    public func ascendingSort<T>(_ keyPath: T, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> where T : TracableKeyPathProtocol, T.Root == Target {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: true, selector: type.selector)
        _config = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return self
    }
    
    public func descendingSort<T>(_ keyPath: T, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> where T : TracableKeyPathProtocol, T.Root == Target {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: false, selector: type.selector)
        _config = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return self
    }
    
    public func ascendingSort(_ keyPath: PartialKeyPath<Target>, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: true, selector: type.selector)
        _config = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return self
    }
    
    public func descendingSort(_ keyPath: PartialKeyPath<Target>, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: false, selector: type.selector)
        _config = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return self
    }
    
    public func map<T: TracableKeyPathProtocol>(_ keyPath: T) -> PartialQueryBuilder<Target, Dictionary<String, Any>, T.Value.PropertyValue> {
        let newConfig = _config.updated(\.mapTo, value: [keyPath]).updated(\.resultType, value: .dictionaryResultType)
        return .init(config: newConfig, context: _context)
    }
    
    public func map<T: TracableKeyPathProtocol>(_ keyPaths: [T]) -> PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> {
        let newConfig = _config.updated(\.mapTo, value: (_config.mapTo ?? []) + keyPaths).updated(\.resultType, value: .dictionaryResultType)
        return .init(config: newConfig, context: _context)
    }
    
    public func map<E: NSManagedObject, T: SavableTypeProtocol>(_ keyPath: KeyPath<E, T>) -> PartialQueryBuilder<Target, Dictionary<String, Any>, T> {
        let newConfig = _config.updated(\.mapTo, value: [keyPath]).updated(\.resultType, value: .dictionaryResultType)
        return .init(config: newConfig, context: _context)
    }
    
    public func map<E: NSManagedObject, T: SavableTypeProtocol>(_ keyPaths: [KeyPath<E, T>]) -> PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> {
        let newConfig = _config.updated(\.mapTo, value: (_config.mapTo ?? []) + keyPaths).updated(\.resultType, value: .dictionaryResultType)
        return .init(config: newConfig, context: _context)
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
    
    private var received: [Received] {
        let request = _config.createFetchRequest()
        return _context.execute(request: request)
    }
}

extension PartialQueryBuilder where Result == Dictionary<String, Any>, Received == Result {
    public func exec() -> [Result] {
        received
    }
}

extension PartialQueryBuilder where Result: RuntimeObject, Received == NSManagedObject {
    public func findOne() -> Result? {
        limit(1).exec().first
    }
    
    public func exec() -> [Result] {
        received.map {
            Result.create(_context.receive($0), proxyType: _context.proxyType)
        }
    }
}

extension PartialQueryBuilder where Received == Dictionary<String, Any> {
    public func exec() -> [Result] {
        received.flatMap{ $0.values }.compactMap{ $0 as? Result }
    }
}


extension NSExpressionDescription: Expressible {
    public func asExpression() -> Any {
        self
    }
}
