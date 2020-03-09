//
//  PartialQueryBuilder.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/1/17.
//  Copyright © 2020 ezou. All rights reserved.
//

import CoreData

public typealias Query<T: Entity> = QueryBuilder<T, NSManagedObject, T>

extension TracableKeyPathProtocol where Root: Entity, Value: NullablePropertyProtocol, Value.EntityType: PredicateEquatable & Equatable {
    public static func == (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) == %@", rhs.predicateValue)
    }
    
    public static func != (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) != %@", rhs.predicateValue)
    }
}

extension KeyPath where Root: NSManagedObject, Value: PredicateEquatable & Equatable {
    public static func == (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) == %@", rhs.predicateValue)
    }
    
    public static func != (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) != %@", rhs.predicateValue)
    }
}

extension KeyPath where Root: NSManagedObject {
    public static func == <E: PredicateEquatable & Equatable>(lhs: KeyPath, rhs: Value) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.fullPath) == %@", rhs?.predicateValue ?? "NULL")
    }
    
    public static func != <E: PredicateEquatable & Equatable>(lhs: KeyPath, rhs: Value) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.fullPath) != %@", rhs?.predicateValue ?? "NULL")
    }
    
    public static func == <E: NSManagedObject>(lhs: KeyPath, rhs: Value) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.fullPath) == NULL")
    }
    
    public static func != <E: NSManagedObject>(lhs: KeyPath, rhs: Value) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.fullPath) != NULL")
    }
}

// CONTAINS, BETWEEN operator
infix operator <>
// BEGINSWITH operator
infix operator |~
// ENDSWITH operator
infix operator ~|
// LINE operator
infix operator |~|
// MATCHES operator
infix operator |*|

extension TracableKeyPathProtocol where Root: Entity, Value: NullablePropertyProtocol, Value.EntityType: PredicateComparable & Comparable {
    public static func > (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) > %@", rhs.predicateValue)
    }
    
    public static func < (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) < %@", rhs.predicateValue)
    }
    
    public static func >= (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) >= %@", rhs.predicateValue)
    }
    
    public static func <= (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) <= %@", rhs.predicateValue)
    }
    
    public static func <> (lhs: Self, rhs: Range<Value.EntityType>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) BETWEEN '{\(rhs.lowerBound.predicateValue), \(rhs.upperBound.predicateValue)}'")
    }
}

extension TracableKeyPathProtocol where Root: Entity, Value: NullablePropertyProtocol, Value.EntityType == String {
    public static func |~ (lhs: Self, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) BEGINSWITH %@", rhs)
    }
    
    public static func ~| (lhs: Self, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) ENDSWITH %@", rhs)
    }
    
    public static func <> (lhs: Self, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) CONTAINS %@", rhs)
    }
    
    public static func |~| (lhs: Self, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) LIKE %@", rhs)
    }
    
    public static func |*| (lhs: Self, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) MATCHES %@", rhs)
    }
}

extension KeyPath where Root: Entity, Value: NullablePropertyProtocol, Value.EntityType: PredicateEquatable & Equatable & Hashable {
    public static func <> (lhs: KeyPath, rhs: Set<Value.EntityType>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath where Root: Entity, Value: NullablePropertyProtocol, Value.EntityType: PredicateEquatable & Equatable {
    public static func <> (lhs: KeyPath, rhs: Array<Value.EntityType>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where Root: NSManagedObject, Value: PredicateEquatable & Equatable & Hashable {
    public static func <> (lhs: KeyPath, rhs: Set<Value>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath where Root: NSManagedObject, Value: PredicateEquatable & Equatable {
    public static func <> (lhs: KeyPath, rhs: Array<Value>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where Root: NSManagedObject, Value: PredicateComparable & Comparable {
    public static func > (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) > %@", rhs.predicateValue)
    }
    
    public static func < (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) < %@", rhs.predicateValue)
    }
    
    public static func >= (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) >= %@", rhs.predicateValue)
    }
    
    public static func <= (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) <= %@", rhs.predicateValue)
    }
    
    public static func <> (lhs: KeyPath, rhs: Range<Value>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) BETWEEN '{\(rhs.lowerBound.predicateValue), \(rhs.upperBound.predicateValue)}'")
    }
}

extension KeyPath where Root: NSManagedObject, Value == String {
    public static func |~ (lhs: KeyPath, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) BEGINSWITH %@", rhs)
    }
    
    public static func ~| (lhs: KeyPath, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) ENDSWITH %@", rhs)
    }
    
    public static func <> (lhs: KeyPath, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) CONTAINS %@", rhs)
    }
    
    public static func |~| (lhs: KeyPath, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) LIKE %@", rhs)
    }
    
    public static func |*| (lhs: KeyPath, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) MATCHES %@", rhs)
    }
}

extension KeyPath where Root: NSManagedObject {
    public static func <> <E: PredicateEquatable & Equatable & Hashable>(lhs: KeyPath, rhs: Set<E>) -> NSPredicate where Value == Swift.Optional<E>{
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath where Root: NSManagedObject {
    public static func <> <E: PredicateEquatable & Equatable>(lhs: KeyPath, rhs: Array<E>) -> NSPredicate where Value == Swift.Optional<E>{
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where Root: NSManagedObject {
    public static func > <E: PredicateComparable & Comparable>(lhs: KeyPath, rhs: E) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.fullPath) > %@", rhs.predicateValue)
    }
    
    public static func < <E: PredicateComparable & Comparable>(lhs: KeyPath, rhs: E) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.fullPath) < %@", rhs.predicateValue)
    }
    
    public static func >= <E: PredicateComparable & Comparable>(lhs: KeyPath, rhs: E) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.fullPath) >= %@", rhs.predicateValue)
    }
    
    public static func <= <E: PredicateComparable & Comparable>(lhs: KeyPath, rhs: E) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.fullPath) <= %@", rhs.predicateValue)
    }
    
    public static func <> <E: PredicateComparable & Comparable>(lhs: KeyPath, rhs: Range<E>) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.fullPath) BETWEEN '{\(rhs.lowerBound.predicateValue), \(rhs.upperBound.predicateValue)}'")
    }
}

extension KeyPath where Root: NSManagedObject, Value == Swift.Optional<String> {
    public static func |~ (lhs: KeyPath, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) BEGINSWITH %@", rhs)
    }
    
    public static func ~| (lhs: KeyPath, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) ENDSWITH %@", rhs)
    }
    
    public static func <> (lhs: KeyPath, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) CONTAINS %@", rhs)
    }
    
    public static func |~| (lhs: KeyPath, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) LIKE %@", rhs)
    }
    
    public static func |*| (lhs: KeyPath, rhs: String) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) MATCHES %@", rhs)
    }
}

public func CASE_INSENSITIVE(_ string: String) -> String {
    return "[c] \(string)"
}

public func DIACRITIC_INSENSITIVE(_ string: String) -> String {
    return "[d] \(string)"
}

public func CASE_DIACRITIC_INSENSITIVE(_ string: String) -> String {
    return "[cd] \(string)"
}

public func && (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(andPredicateWithSubpredicates: [lhs, rhs])
}

public func || (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(orPredicateWithSubpredicates: [lhs, rhs])
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
    private(set) var groupBy: [TracableProtocol]?
    private(set) var mapTo: [TracableProtocol]?
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
    
    private init(predicate: NSPredicate?, limit: Int?, offset: Int?,  sorters: [NSSortDescriptor]?, groupBy: [TracableProtocol]?, mapTo: [TracableProtocol]?, asFaults: Bool, resultType: NSFetchRequestResultType) {
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
        request.propertiesToFetch = mapTo?.map{ $0.expression }
        request.propertiesToGroupBy = groupBy?.map{ $0.expression }
        request.resultType = resultType
        request.fetchLimit = limit ?? .max
        request.fetchOffset = offset ?? 0
        request.returnsObjectsAsFaults = asFaults
        return request
    }
}

public struct PartialQueryBuilder<Target: Entity, Received, Result> {
    internal var _config: QueryConfig<Target>
    
    internal let _context: ReadOnlyTransactionContext & RawContextProviderProtocol

    internal init(config: QueryConfig<Target>, context: ReadOnlyTransactionContext & RawContextProviderProtocol) {
        self._config = config
        self._context = context
    }
}

extension PartialQueryBuilder {
    public func limit(_ size: Int) -> PartialQueryBuilder<Target, Received, Result> {
        let newConfig = _config.updated(\.limit, value: size)
        return PartialQueryBuilder(config: newConfig, context: _context)
    }

    public func offset(_ step: Int) -> PartialQueryBuilder<Target, Received, Result> {
        let newConfig = _config.updated(\.offset, value: step)
        return PartialQueryBuilder<Target, Received, Result>(config: newConfig, context: _context)
    }
    
    public func groupAndCount<T>(col name: T) -> PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> where T : TracableKeyPathProtocol, T.Root == Target {
        let keypathExp = NSExpression(forKeyPath: name.fullPath)
        let countDesc = NSExpressionDescription()
        countDesc.name = "count"
        countDesc.expressionResultType = .integer64AttributeType
        countDesc.expression = NSExpression(forFunction: "count:",
                                            arguments: [keypathExp])
        let expression = _TracableExpression<Target>(descriptor: countDesc)
        let newConfig = _config
            .updated(\.groupBy, value: (_config.groupBy ?? []) + [name])
            .updated(\.mapTo, value: [name, expression])
            .updated(\.resultType, value: .dictionaryResultType)
        return PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>>(config: newConfig, context: _context)
    }
    
    public func ascendingSort<T>(_ keyPath: T, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> where T : TracableKeyPathProtocol, T.Root == Target {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: true, selector: type.selector)
        let newConfig = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return PartialQueryBuilder(config: newConfig, context: _context)
    }
    
    public func descendingSort<T>(_ keyPath: T, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> where T : TracableKeyPathProtocol, T.Root == Target {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: false, selector: type.selector)
        let newConfig = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return PartialQueryBuilder(config: newConfig, context: _context)
    }
    
    public func ascendingSort(_ keyPath: PartialKeyPath<Target>, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: true, selector: type.selector)
        let newConfig = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return PartialQueryBuilder(config: newConfig, context: _context)
    }
    
    public func descendingSort(_ keyPath: PartialKeyPath<Target>, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: false, selector: type.selector)
        let newConfig = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return PartialQueryBuilder(config: newConfig, context: _context)
    }
    
    public func map<T: TracableKeyPathProtocol>(_ keyPath: T) -> PartialQueryBuilder<Target, Dictionary<String, Any>, T.Value.PropertyValue> {
        let newConfig = _config.updated(\.mapTo, value: [keyPath]).updated(\.resultType, value: .dictionaryResultType)
        return PartialQueryBuilder<Target, Dictionary<String, Any>, T.Value.PropertyValue>(config: newConfig, context: _context)
    }
    
    public func map<T: TracableKeyPathProtocol>(_ keyPaths: [T]) -> PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> {
        let newConfig = _config.updated(\.mapTo, value: (_config.mapTo ?? []) + keyPaths).updated(\.resultType, value: .dictionaryResultType)
        return PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>>(config: newConfig, context: _context)
    }
    
    public func map<E: NSManagedObject, T: SavableTypeProtocol>(_ keyPath: KeyPath<E, T>) -> PartialQueryBuilder<Target, Dictionary<String, Any>, T> {
        let newConfig = _config.updated(\.mapTo, value: [keyPath]).updated(\.resultType, value: .dictionaryResultType)
        return PartialQueryBuilder<Target, Dictionary<String, Any>, T>(config: newConfig, context: _context)
    }
    
    public func map<E: NSManagedObject, T: SavableTypeProtocol>(_ keyPaths: [KeyPath<E, T>]) -> PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> {
        let newConfig = _config.updated(\.mapTo, value: (_config.mapTo ?? []) + keyPaths).updated(\.resultType, value: .dictionaryResultType)
        return PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>>(config: newConfig, context: _context)
    }
    
    public func exec() -> [Result] {
        let request = _config.createFetchRequest()
        let results: [Received] = _context.execute(request: request)
        
        if Result.self == Dictionary<String, Any>.self {
            return results as! [Result]
        } else if let runtimeObject = Result.self as? RuntimeObject.Type {
            return results.compactMap{
                let object = $0 as! NSManagedObject
                return runtimeObject.init(objectID: object.objectID, in: _context.context, proxyType: _context.proxyType) as? Result
            }
        } else {
            return (results as! [Dictionary<String, Any>]).flatMap{ $0.values }.compactMap{ $0 as? Result }
        }
    }
    
    public func findOne() -> Result? {
        limit(1).exec().first
    }

    public func `where`(_ predicate: NSPredicate) -> Self {
        let newConfig = _config.updated(\.predicate, value: predicate)
        return Self.init(config: newConfig, context: _context)
    }
    
    public func andWhere(_ predicate: NSPredicate) -> Self {
        let newPredicate: NSPredicate = {
            if let pred = _config.predicate {
                return NSCompoundPredicate(andPredicateWithSubpredicates: [pred, predicate])
            }
            return predicate
        }()
        let newConfig = _config.updated(\.predicate, value: newPredicate)
        return Self.init(config: newConfig, context: _context)
    }
    
    public func orWhere(_ predicate: NSPredicate) -> Self {
        let newPredicate: NSPredicate = {
            if let pred = _config.predicate {
                return NSCompoundPredicate(orPredicateWithSubpredicates: [pred, predicate])
            }
            return predicate
        }()
        let newConfig = _config.updated(\.predicate, value: newPredicate)
        return Self.init(config: newConfig, context: _context)
    }
}

public struct QueryBuilder<Target: Entity, Received, Result> {
    internal var _config: QueryConfig<Target>
    
    internal let _context: ReadOnlyTransactionContext & RawContextProviderProtocol

    internal init(config: QueryConfig<Target>, context: ReadOnlyTransactionContext & RawContextProviderProtocol) {
        self._config = config
        self._context = context
    }
    
    public func count() -> Int {
        let newConfig = _config.updated(\.resultType, value: .countResultType)
        let request = newConfig.createFetchRequest()
        return _context.count(request: request)
    }
    
    public func limit(_ size: Int) -> PartialQueryBuilder<Target, Received, Result> {
        let newConfig = _config.updated(\.limit, value: size)
        return PartialQueryBuilder(config: newConfig, context: _context)
    }

    public func offset(_ step: Int) -> PartialQueryBuilder<Target, Received, Result> {
        let newConfig = _config.updated(\.offset, value: step)
        return PartialQueryBuilder<Target, Received, Result>(config: newConfig, context: _context)
    }
    
    public func groupAndCount<T>(col name: T) -> PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> where T : TracableKeyPathProtocol, T.Root == Target {
        let keypathExp = NSExpression(forKeyPath: name.fullPath)
        let countDesc = NSExpressionDescription()
        countDesc.name = "count"
        countDesc.expressionResultType = .integer64AttributeType
        countDesc.expression = NSExpression(forFunction: "count:",
                                            arguments: [keypathExp])
        let expression = _TracableExpression<Target>(descriptor: countDesc)
        let newConfig = _config
            .updated(\.groupBy, value: (_config.groupBy ?? []) + [name])
            .updated(\.mapTo, value: [name, expression])
            .updated(\.resultType, value: .dictionaryResultType)
        return PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>>(config: newConfig, context: _context)
    }
    
    public func ascendingSort<T>(_ keyPath: T, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> where T : TracableKeyPathProtocol, T.Root == Target {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: true, selector: type.selector)
        let newConfig = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return PartialQueryBuilder(config: newConfig, context: _context)
    }
    
    public func descendingSort<T>(_ keyPath: T, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> where T : TracableKeyPathProtocol, T.Root == Target {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: false, selector: type.selector)
        let newConfig = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return PartialQueryBuilder(config: newConfig, context: _context)
    }
    
    public func ascendingSort(_ keyPath: PartialKeyPath<Target>, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: true, selector: type.selector)
        let newConfig = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return PartialQueryBuilder(config: newConfig, context: _context)
    }
    
    public func descendingSort(_ keyPath: PartialKeyPath<Target>, type: QuerySorterOption = .default) -> PartialQueryBuilder<Target, Received, Result> {
        let descriptor = NSSortDescriptor(key: keyPath.fullPath, ascending: false, selector: type.selector)
        let newConfig = _config.updated(\.sorters, value: (_config.sorters ?? []) + [descriptor])
        return PartialQueryBuilder(config: newConfig, context: _context)
    }
    
    public func map<T: TracableKeyPathProtocol>(_ keyPath: T) -> PartialQueryBuilder<Target, Dictionary<String, Any>, T.Value.PropertyValue> {
        let newConfig = _config.updated(\.mapTo, value: [keyPath]).updated(\.resultType, value: .dictionaryResultType)
        return PartialQueryBuilder<Target, Dictionary<String, Any>, T.Value.PropertyValue>(config: newConfig, context: _context)
    }
    
    public func map<T: TracableKeyPathProtocol>(_ keyPaths: [T]) -> PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> {
        let newConfig = _config.updated(\.mapTo, value: (_config.mapTo ?? []) + keyPaths).updated(\.resultType, value: .dictionaryResultType)
        return PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>>(config: newConfig, context: _context)
    }
    
    public func map<E: NSManagedObject, T: SavableTypeProtocol>(_ keyPath: KeyPath<E, T>) -> PartialQueryBuilder<Target, Dictionary<String, Any>, T> {
        let newConfig = _config.updated(\.mapTo, value: [keyPath]).updated(\.resultType, value: .dictionaryResultType)
        return PartialQueryBuilder<Target, Dictionary<String, Any>, T>(config: newConfig, context: _context)
    }
    
    public func map<E: NSManagedObject, T: SavableTypeProtocol>(_ keyPaths: [KeyPath<E, T>]) -> PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>> {
        let newConfig = _config.updated(\.mapTo, value: (_config.mapTo ?? []) + keyPaths).updated(\.resultType, value: .dictionaryResultType)
        return PartialQueryBuilder<Target, Dictionary<String, Any>, Dictionary<String, Any>>(config: newConfig, context: _context)
    }
    
    public func exec() -> [Result] {
        let request = _config.createFetchRequest()
        let results: [Received] = _context.execute(request: request)
        
        if Result.self == Dictionary<String, Any>.self {
            return results as! [Result]
        } else if let runtimeObject = Result.self as? RuntimeObject.Type {
            return results.compactMap{ runtimeObject.init($0 as! NSManagedObject, proxyType: _context.proxyType) as? Result }
        } else {
            return (results as! [Dictionary<String, Any>]).flatMap{ $0.values }.compactMap{ $0 as? Result }
        }
    }
    
    public func findOne() -> Result? {
        limit(1).exec().first
    }

    public func `where`(_ predicate: NSPredicate) -> Self {
        let newConfig = _config.updated(\.predicate, value: predicate)
        return Self.init(config: newConfig, context: _context)
    }
    
    public func andWhere(_ predicate: NSPredicate) -> Self {
        let newPredicate: NSPredicate = {
            if let pred = _config.predicate {
                return NSCompoundPredicate(andPredicateWithSubpredicates: [pred, predicate])
            }
            return predicate
        }()
        let newConfig = _config.updated(\.predicate, value: newPredicate)
        return Self.init(config: newConfig, context: _context)
    }
    
    public func orWhere(_ predicate: NSPredicate) -> Self {
        let newPredicate: NSPredicate = {
            if let pred = _config.predicate {
                return NSCompoundPredicate(orPredicateWithSubpredicates: [pred, predicate])
            }
            return predicate
        }()
        let newConfig = _config.updated(\.predicate, value: newPredicate)
        return Self.init(config: newConfig, context: _context)
    }
}


fileprivate class _TracableExpression<T: Entity>: TracableProtocol {
    let expression: Any
    
    var rootType: Entity.Type { T.self }
    
    init(descriptor: NSExpressionDescription) {
        self.expression = descriptor
    }
}
