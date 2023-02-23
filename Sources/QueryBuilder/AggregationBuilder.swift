//
//  AggregationBuilder.swift
//  
//
//  Created by ezou on 2022/2/1.
//

import CoreData

public class DictionaryBuilderBase<Target: Crush.Entity>:
    RequestBuilder,
    NonThrowingRequestExecutor
{
    let context: Context
    var config: FetchConfig<Target>

    private var fieldConvertors: [String: any AnyPropertyType] = [:]

    init(config: FetchConfig<Target>, context: Context) {
        self.config = config
        self.context = context
    }

    func saveConvertor(keyPath: PartialKeyPath<Target>) {
        if let convertor = Target()[keyPath: keyPath] as? AnyPropertyType,
           let name = keyPath.optionalPropertyName {
            fieldConvertors[name] = convertor
        }
    }
    
    private func received() -> [[String: Any]] {
        config.modify { $0.resultType = .dictionaryResultType }
        let result: NSAsynchronousFetchResult<NSFetchRequestResult> =
            try! context.execute(request: config.createFetchRequest())
        return (result.finalResult ?? []) as! [[String: Any]]
    }

    public func exec() -> [[String: Any]] {
        received().map {
            var dictionary = $0
            let keys = Set(dictionary.keys).intersection(Set(fieldConvertors.keys))
            for key in keys {
                guard let convertor = fieldConvertors[key],
                      let newValue = convertor.managedToRuntime(dictionary[key])
                else { continue }
                dictionary.updateValue(newValue, forKey: key)
            }
            return dictionary
        }
    }

    public func execAsync(completion: @escaping ([[String: Any]]) -> Void) {
        context.rootContext.performAsync {
            let result = self.exec()
            completion(result)
        }
    }
}

public final class DictionaryBuilder<Target: Crush.Entity>: DictionaryBuilderBase<Target> { }

extension FetchBuilder {
    public func asDictionary() -> DictionaryBuilder<Target> {
        DictionaryBuilder(config: config, context: context)
    }
}

public final class AggregationBuilder<Target: Crush.Entity>: DictionaryBuilderBase<Target> {
    public func group<T: Property>(by property: KeyPath<Target, T>) -> Self
    {
        config.modify {
            $0.group(by: property)
        }
        saveConvertor(keyPath: property)
        return self
    }
    
    public func aggregate(
        _ expression: AggregateExpression<Target>,
        as name: String) -> Self
    {
        let description = NSExpressionDescription()
        expression.block(description)
        description.name = name
        config.modify {
            $0.fetch(property: description)
        }
        saveConvertor(keyPath: expression.keyPath)
        return self
    }
    
    public func havingPredicate(_ predicate: NSPredicate) -> Self {
        config.modify { $0.havingPredicate = predicate }
        return self
    }
    
    public func andHavingPredicate(_ predicate: NSPredicate) -> Self {
        config.modify {
            guard let oldPredicate = $0.havingPredicate else {
                return $0.havingPredicate = predicate
            }
            $0.havingPredicate = oldPredicate && predicate
        }
        return self
    }
    
    public func orHavingPredicate(_ predicate: NSPredicate) -> Self {
        config.modify {
            guard let oldPredicate = $0.havingPredicate else {
                return $0.havingPredicate = predicate
            }
            $0.havingPredicate = oldPredicate || predicate
        }
        return self
    }
}

extension AggregationBuilder {
    public func havingPredicate(_ predicate: TypedPredicate<Target>) -> Self {
        havingPredicate(predicate as NSPredicate)
    }
    
    public func andHavingPredicate(_ predicate: TypedPredicate<Target>) -> Self {
        andHavingPredicate(predicate as NSPredicate)
    }
    
    public func orHavingPredicate(_ predicate: TypedPredicate<Target>) -> Self {
        orHavingPredicate(predicate as NSPredicate)
    }
    
    public func havingPredicate(_ format: String, _ args: CVarArg...) -> Self {
        havingPredicate(NSPredicate(format: format, argumentArray: args))
    }
    
    public func andHavingPredicate(_ format: String, _ args: CVarArg...) -> Self {
        andHavingPredicate(NSPredicate(format: format, argumentArray: args))
    }
    
    public func orHavingPredicate(_ format: String, _ args: CVarArg...) -> Self {
        orHavingPredicate(NSPredicate(format: format, argumentArray: args))
    }
}

extension DictionaryBuilder {
    public func group<T: Property>(by property: KeyPath<Target, T>) -> AggregationBuilder<Target> {
        AggregationBuilder(config: config, context: context).group(by: property)
    }
}

public final class AggregateExpression<T: Entity> {

    let keyPath: PartialKeyPath<T>
    let block: (NSExpressionDescription) -> Void

    init(keyPath: PartialKeyPath<T>, _ block: @escaping (NSExpressionDescription) -> Void) {
        self.block = block
        self.keyPath = keyPath
    }

    public static func count<S: Property>(_ keyPath: KeyPath<T, S>) -> AggregateExpression {
        return AggregateExpression(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = .integer16AttributeType
            description.expression = NSExpression(forFunction: "count:", arguments: [exp])
        }
    }

    public static func max<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregateExpression
    where S.PropertyType: PredicateComparable {
        return AggregateExpression(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = S.PropertyType.nativeType
            description.expression = NSExpression(forFunction: "max:", arguments: [exp])
        }
    }

    public static func min<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregateExpression
    where S.PropertyType: PredicateComparable {
        return AggregateExpression(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = S.PropertyType.nativeType
            description.expression = NSExpression(forFunction: "min:", arguments: [exp])
        }
    }

    public static func sum<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregateExpression
    where S.PropertyType: PredicateComputable {
        return AggregateExpression(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = S.PropertyType.nativeType
            description.expression = NSExpression(forFunction: "sum:", arguments: [exp])
        }
    }

    public static func average<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregateExpression
    where S.PropertyType: PredicateComputable {
        return AggregateExpression(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = .doubleAttributeType
            description.expression = NSExpression(forFunction: "average:", arguments: [exp])
        }
    }
}

public final class SelectBuilder<Target: Crush.Entity>: DictionaryBuilderBase<Target> {
    public func select(_ keyPaths: PartialKeyPath<Target>...) -> Self {
        select(keyPaths)
    }

    public func select(_ selectPaths: SelectPath<Target>...) -> Self {
        select(selectPaths)
    }
    
    public func select(
        _ keyPaths: [PartialKeyPath<Target>]) -> Self
    {
        config.modify { [unowned self] in
            for keyPath in keyPaths {
                guard let expressible = keyPath as? Expressible else { continue }
                $0.fetch(property: expressible)
                saveConvertor(keyPath: keyPath)
            }
        }
        return self
    }

    public func select(_ selectPaths: [SelectPath<Target>]) -> Self {
        config.modify { selectPaths.forEach($0.fetch(property:)) }
        return self
    }
    
    public func returnsDistinctResults(_ flag: Bool = true) -> Self {
        config.modify { $0.returnsDistinctResults = flag }
        return self
    }
}

extension DictionaryBuilder {
    public func select(_ keyPaths: PartialKeyPath<Target>...) -> SelectBuilder<Target> {
        SelectBuilder(config: config, context: context).select(keyPaths)
    }

    public func select(_ selectPaths: SelectPath<Target>...) -> SelectBuilder<Target> {
        SelectBuilder(config: config, context: context).select(selectPaths)
    }
    
    public func select(_ keyPaths: [PartialKeyPath<Target>]) -> SelectBuilder<Target> {
        SelectBuilder(config: config, context: context).select(keyPaths)
    }

    public func select(_ selectPaths: [SelectPath<Target>]) -> SelectBuilder<Target> {
        SelectBuilder(config: config, context: context).select(selectPaths)
    }
}

extension NSFetchRequest where ResultType == NSFetchRequestResult {
    func group(by property: any Expressible) {
        let expression = property.asExpression()
        propertiesToFetch.initializeIfNeeded()
        propertiesToGroupBy.initializeIfNeeded()
        propertiesToFetch?.append(expression)
        propertiesToGroupBy?.append(expression)
    }

    func fetch(property: any Expressible) {
        let expression = property.asExpression()
        propertiesToFetch.initializeIfNeeded()
        propertiesToFetch?.append(expression)
    }
}

extension Swift.Optional where Wrapped: Collection {
    mutating func initializeIfNeeded(_ value: @autoclosure () -> Wrapped) {
        guard case .none = self else { return }
        self = .some(value())
    }
}

extension Swift.Optional where Wrapped: Collection & ExpressibleByArrayLiteral {
    mutating func initializeIfNeeded() {
        guard case .none = self else { return }
        self = .some([])
    }
}

extension NSExpressionDescription: Expressible {
    public func getHashValue() -> Int {
        hashValue
    }

    public func asExpression() -> Any {
        self
    }
}
