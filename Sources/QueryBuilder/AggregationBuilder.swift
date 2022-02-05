//
//  AggregationBuilder.swift
//  
//
//  Created by ezou on 2022/2/1.
//

import CoreData

public final class AggregationBuilder<Target: Crush.Entity>: RequestBuilder, NonThrowingRequestExecutor {

    let context: Context

    var config: FetchConfig<Target>

    private var fieldConvertors: [String: AnyFieldConvertible] = [:]

    init(config: FetchConfig<Target>, context: Context) {
        self.config = config
        self.context = context

        let entity = Target()

        fieldConvertors = config.prefetched?
            .compactMap { $0 as? PartialKeyPath<Target> }
            .compactMap { entity[keyPath: $0] as? (AnyFieldConvertible & PropertyProtocol) }
            .reduce(into: [String: AnyFieldConvertible]()) {
                $0[$1.name] = $1
            } ?? [:]
    }

    private func saveConvertor(keyPath: PartialKeyPath<Target>) {
        if let convertor = Target()[keyPath: keyPath] as? AnyFieldConvertible,
           let name = keyPath.optionalPropertyName {
            fieldConvertors[name] = convertor
        }
    }

    public func group<T: ValuedProperty>(by property: KeyPath<Target, T>) -> Self {
        config.group(by: property)
        saveConvertor(keyPath: property)
        return self
    }

    public func projection(name: String, operator: AggregationOperator<Target>) -> Self {
        let description = NSExpressionDescription()
        `operator`.block(description)
        description.name = name
        config.prefetch(property: description)
        saveConvertor(keyPath: `operator`.keyPath)
        return self
    }

    private func received() -> [[String: Any]] {
        config.resultType = .dictionaryResultType
        let result: NSAsynchronousFetchResult<NSFetchRequestResult> = try! context.execute(
            request: config.createStoreRequest() as! NSFetchRequest<NSFetchRequestResult>,
            on: config.includePendingChanges ? \.executionContext : \.rootContext)
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

public final class AggregationOperator<T: Entity> {

    let keyPath: PartialKeyPath<T>
    let block: (NSExpressionDescription) -> Void

    init(keyPath: PartialKeyPath<T>, _ block: @escaping (NSExpressionDescription) -> Void) {
        self.block = block
        self.keyPath = keyPath
    }

    public static func count<S: ValuedProperty>(_ keyPath: KeyPath<T, S>) -> AggregationOperator {
        return AggregationOperator(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = .integer16AttributeType
            description.expression = NSExpression(forFunction: "count:", arguments: [exp])
        }
    }

    public static func max<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregationOperator
    where S.FieldConvertor: PredicateComparable {
        return AggregationOperator(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = S.FieldConvertor.nativeType
            description.expression = NSExpression(forFunction: "max:", arguments: [exp])
        }
    }

    public static func min<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregationOperator
    where S.FieldConvertor: PredicateComparable {
        return AggregationOperator(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = S.FieldConvertor.nativeType
            description.expression = NSExpression(forFunction: "min:", arguments: [exp])
        }
    }

    public static func sum<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregationOperator
    where S.FieldConvertor: PredicateComputable {
        return AggregationOperator(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = S.FieldConvertor.nativeType
            description.expression = NSExpression(forFunction: "sum:", arguments: [exp])
        }
    }

    public static func average<S: AttributeProtocol>(_ keyPath: KeyPath<T, S>) -> AggregationOperator
    where S.FieldConvertor: PredicateComputable {
        return AggregationOperator(keyPath: keyPath) { description in
            let exp = NSExpression(forKeyPath: keyPath.propertyName)
            description.expressionResultType = S.FieldConvertor.nativeType
            description.expression = NSExpression(forFunction: "average:", arguments: [exp])
        }
    }
}
