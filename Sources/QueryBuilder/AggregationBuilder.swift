//
//  AggregationBuilder.swift
//  
//
//  Created by ezou on 2022/2/1.
//

import CoreData

/// A base class for building dictionaries from `Target` entities.
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

/// A class for building dictionaries from `Target` entities.
public final class DictionaryBuilder<Target: Crush.Entity>: DictionaryBuilderBase<Target> { }

extension FetchBuilder {
    /// Returns a `DictionaryBuilder` for the current `FetchBuilder` instance.
    public func asDictionary() -> DictionaryBuilder<Target> {
        DictionaryBuilder(config: config, context: context)
    }
}

/**
    A class for building database queries for aggregations.

    - Note: You should instantiate this class via a `QueryBuilder` instance.
*/
public final class AggregationBuilder<Target: Crush.Entity>: DictionaryBuilderBase<Target> {

    /**
        Groups the query result by a given property.

        - Parameter property: The property to group by.
        - Returns: The current instance of the class, for method chaining.
    */
    public func group<T: Property>(by property: KeyPath<Target, T>) -> Self {
        config.modify {
            $0.group(by: property)
        }
        saveConvertor(keyPath: property)
        return self
    }

    /**
        Aggregates the query result based on the given expression and assigns an alias to it.

        - Parameters:
            - expression: The expression to aggregate.
            - name: The name of the alias to assign to the aggregated result.
        - Returns: The current instance of the class, for method chaining.
    */
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

    /**
        Adds a predicate to filter the query result by.

        - Parameter predicate: The predicate to filter the query result by.
        - Returns: The current instance of the class, for method chaining.
    */
    public func havingPredicate(_ predicate: NSPredicate) -> Self {
        config.modify { $0.havingPredicate = predicate }
        return self
    }

    /**
        Adds a predicate to filter the query result by, using an `AND` operation.

        - Parameter predicate: The predicate to filter the query result by.
        - Returns: The current instance of the class, for method chaining.
    */
    public func andHavingPredicate(_ predicate: NSPredicate) -> Self {
        config.modify {
            guard let oldPredicate = $0.havingPredicate else {
                return $0.havingPredicate = predicate
            }
            $0.havingPredicate = oldPredicate && predicate
        }
        return self
    }

    /**
        Adds a predicate to filter the query result by, using an `OR` operation.

        - Parameter predicate: The predicate to filter the query result by.
        - Returns: The current instance of the class, for method chaining.
    */
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
    /**
        Adds a predicate to filter the query result by.

        - Parameter predicate: The predicate to filter the query result by.
        - Returns: The current instance of the class, for method chaining.
    */
    public func havingPredicate(_ predicate: TypedPredicate<Target>) -> Self {
        havingPredicate(predicate as NSPredicate)
    }

    /**
        Adds a predicate to filter the query result by, using an `AND` operation.

        - Parameter predicate: The predicate to filter the query result by.
        - Returns: The current instance of the class, for method chaining.
    */
    public func andHavingPredicate(_ predicate: TypedPredicate<Target>) -> Self {
        andHavingPredicate(predicate as NSPredicate)
    }

    /**
        Adds a predicate to filter the query result by, using an `OR` operation.

        - Parameter predicate: The predicate to filter the query result by.
        - Returns: The current instance of the class, for method chaining.
    */
    public func orHavingPredicate(_ predicate: TypedPredicate<Target>) -> Self {
        orHavingPredicate(predicate as NSPredicate)
    }

    /**
        Adds a predicate to filter the query result by.

        - Parameters format: The format string for the new predicate that needs to be combined with the existing predicate using the `OR` operation.
        - Parameters args: The arguments that are used in the format string.
        - Returns: The current instance of the class, for method chaining.
    */
    public func havingPredicate(_ format: String, _ args: CVarArg...) -> Self {
        havingPredicate(NSPredicate(format: format, argumentArray: args))
    }

    /**
        Adds a predicate to filter the query result by, using an `AND` operation.

        - Parameters format: The format string for the new predicate that needs to be combined with the existing predicate using the `OR` operation.
        - Parameters args: The arguments that are used in the format string.
        - Returns: The current instance of the class, for method chaining.
    */
    public func andHavingPredicate(_ format: String, _ args: CVarArg...) -> Self {
        andHavingPredicate(NSPredicate(format: format, argumentArray: args))
    }

    /**
        Adds a predicate to filter the query result by, using an `OR` operation.

        - Parameters format: The format string for the new predicate that needs to be combined with the existing predicate using the `OR` operation.
        - Parameters args: The arguments that are used in the format string.
        - Returns: The current instance of the class, for method chaining.
    */
    public func orHavingPredicate(_ format: String, _ args: CVarArg...) -> Self {
        orHavingPredicate(NSPredicate(format: format, argumentArray: args))
    }
}

extension DictionaryBuilder {
    /// Function that allows grouping results by a given property.
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

    /// Returns an `AggregateExpression` with a `count` aggregate function.
   ///
   /// - Parameter keyPath: The key path for the property to be counted.
   /// - Returns: An `AggregateExpression` with a `count` aggregate function.
   public static func count<S: Property>(_ keyPath: KeyPath<T, S>) -> AggregateExpression {
       return AggregateExpression(keyPath: keyPath) { description in
           let exp = NSExpression(forKeyPath: keyPath.propertyName)
           description.expressionResultType = .integer16AttributeType
           description.expression = NSExpression(forFunction: "count:", arguments: [exp])
       }
   }

   /// Returns an `AggregateExpression` with a `max` aggregate function.
   ///
   /// - Parameter keyPath: The key path for the property to be used in the `max` function.
   /// - Returns: An `AggregateExpression` with a `max` aggregate function.
   public static func max<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregateExpression
   where S.PropertyType: PredicateComparable {
       return AggregateExpression(keyPath: keyPath) { description in
           let exp = NSExpression(forKeyPath: keyPath.propertyName)
           description.expressionResultType = S.PropertyType.nativeType
           description.expression = NSExpression(forFunction: "max:", arguments: [exp])
       }
   }

   /// Returns an `AggregateExpression` with a `min` aggregate function.
   ///
   /// - Parameter keyPath: The key path for the property to be used in the `min` function.
   /// - Returns: An `AggregateExpression` with a `min` aggregate function.
   public static func min<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregateExpression
   where S.PropertyType: PredicateComparable {
       return AggregateExpression(keyPath: keyPath) { description in
           let exp = NSExpression(forKeyPath: keyPath.propertyName)
           description.expressionResultType = S.PropertyType.nativeType
           description.expression = NSExpression(forFunction: "min:", arguments: [exp])
       }
   }

   /// Returns an `AggregateExpression` with a `sum` aggregate function.
   ///
   /// - Parameter keyPath: The key path for the property to be used in the `sum` function.
   /// - Returns: An `AggregateExpression` with a `sum` aggregate function.
   public static func sum<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregateExpression
    where S.PropertyType: PredicateComputable {
        return AggregateExpression(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = S.PropertyType.nativeType
            description.expression = NSExpression(forFunction: "sum:", arguments: [exp])
        }
    }

    /// Returns an `AggregateExpression` with a `average` aggregate function.
    ///
    /// - Parameter keyPath: The key path for the property to be used in the `average` function.
    /// - Returns: An `AggregateExpression` with a `average` aggregate function.
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
    /**
     Adds one or more key paths to the select clause.

     - Parameters:
        - keyPaths: The key paths to add to the select clause.

     - Returns: An instance of `Self`.
     */
    public func select(_ keyPaths: PartialKeyPath<Target>...) -> Self {
        select(keyPaths)
    }

    /**
     Adds one or more `SelectPath` instances to the select clause.

     - Parameters:
        - selectPaths: The `SelectPath` instances to add to the select clause.

     - Returns: An instance of `Self`.
     */
    public func select(_ selectPaths: SelectPath<Target>...) -> Self {
        select(selectPaths)
    }

    /**
     Adds an array of key paths to the select clause.

     - Parameters:
        - keyPaths: An array of key paths to add to the select clause.

     - Returns: An instance of `Self`.
     */
    public func select(_ keyPaths: [PartialKeyPath<Target>]) -> Self {
        config.modify { [unowned self] in
            for keyPath in keyPaths {
                guard let expressible = keyPath as? Expressible else { continue }
                $0.fetch(property: expressible)
                saveConvertor(keyPath: keyPath)
            }
        }
        return self
    }

    /**
     Adds an array of `SelectPath` instances to the select clause.

     - Parameters:
        - selectPaths: An array of `SelectPath` instances to add to the select clause.

     - Returns: An instance of `Self`.
     */
    public func select(_ selectPaths: [SelectPath<Target>]) -> Self {
        config.modify { selectPaths.forEach($0.fetch(property:)) }
        return self
    }

    /**
     Sets the flag to return distinct results.

     - Parameters:
        - flag: The flag to set. Default is `true`.

     - Returns: An instance of `Self`.
     */
    public func returnsDistinctResults(_ flag: Bool = true) -> Self {
        config.modify { $0.returnsDistinctResults = flag }
        return self
    }
}

extension DictionaryBuilder {
    /**
     Adds one or more key paths to the select clause.

     - Parameters:
        - keyPaths: The key paths to add to the select clause.

     - Returns: An instance of `SelectBuilder` with the added key paths to the select clause.
     */
    public func select(_ keyPaths: PartialKeyPath<Target>...) -> SelectBuilder<Target> {
        SelectBuilder(config: config, context: context).select(keyPaths)
    }

    /**
     Adds one or more `SelectPath` instances to the select clause.

     - Parameters:
        - selectPaths: The `SelectPath` instances to add to the select clause.

     - Returns: An instance of `SelectBuilder` with the added `SelectPath` instances to the select clause.
     */
    public func select(_ selectPaths: SelectPath<Target>...) -> SelectBuilder<Target> {
        SelectBuilder(config: config, context: context).select(selectPaths)
    }
    
    /**
     Adds an array of key paths to the select clause.

     - Parameter keyPaths: An array of key paths to add to the select clause.

     - Returns: An instance of `SelectBuilder` with the added key paths to the select clause.
     */
    public func select(_ keyPaths: [PartialKeyPath<Target>]) -> SelectBuilder<Target> {
        SelectBuilder(config: config, context: context).select(keyPaths)
    }

    /**
     Adds an array of `SelectPath` instances to the select clause.

     - Parameter selectPaths: An array of `SelectPath` instances to add to the select clause.

     - Returns: An instance of `SelectBuilder` with the added `SelectPath` instances to the select clause.
     */
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
