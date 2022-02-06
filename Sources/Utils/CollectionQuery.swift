//
//  CollectionQuery.swift
//  
//
//  Created by ezou on 2022/1/31.
//

import Foundation

public final class CollectionQuery<T: Entity> {

    let function: String
    let keyPath: String?
    let `operator`: NSComparisonPredicate.Operator
    let value: Int

    init(_ string: String, keyPath: String?, operator: NSComparisonPredicate.Operator, value: Int) {
        self.function = string
        self.operator = `operator`
        self.value = value
        self.keyPath = keyPath
    }

    // MARK: @count

    public static func count(equalTo value: Int) -> CollectionQuery {
        CollectionQuery("count:", keyPath: nil, operator: .equalTo, value: value)
    }

    public static func count(greaterThan value: Int) -> CollectionQuery {
        CollectionQuery("count:", keyPath: nil, operator: .greaterThan, value: value)
    }

    public static func count(greaterThanOrEqualTo value: Int) -> CollectionQuery {
        CollectionQuery("count:", keyPath: nil, operator: .greaterThanOrEqualTo, value: value)
    }

    public static func count(lessThan value: Int) -> CollectionQuery {
        CollectionQuery("count:", keyPath: nil, operator: .lessThan, value: value)
    }

    public static func count(lessThanOrEqualTo value: Int) -> CollectionQuery {
        CollectionQuery("count:", keyPath: nil, operator: .lessThanOrEqualTo, value: value)
    }

    // MARK: @sum

    /// `sum` only work with in-memory storage / array
    public static func sum<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("sum:", keyPath: selector.propertyName, operator: .equalTo, value: value)
    }

    /// `sum` only work with in-memory storage / array
    public static func sum<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("sum:", keyPath: selector.propertyName, operator: .greaterThan, value: value)
    }

    /// `sum` only work with in-memory storage / array
    public static func sum<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("sum:", keyPath: selector.propertyName, operator: .greaterThanOrEqualTo, value: value)
    }

    /// `sum` only work with in-memory storage / array
    public static func sum<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("sum:", keyPath: selector.propertyName, operator: .lessThan, value: value)
    }

    /// `sum` only work with in-memory storage / array
    public static func sum<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("sum:", keyPath: selector.propertyName, operator: .lessThanOrEqualTo, value: value)
    }

    // MARK: @avg

    /// `avg` only work with in-memory storage / array
    public static func avg<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("avg:", keyPath: selector.propertyName, operator: .equalTo, value: value)
    }

    /// `avg` only work with in-memory storage / array
    public static func avg<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("avg:", keyPath: selector.propertyName, operator: .greaterThan, value: value)
    }

    /// `avg` only work with in-memory storage / array
    public static func avg<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("avg:", keyPath: selector.propertyName, operator: .greaterThanOrEqualTo, value: value)
    }

    /// `avg` only work with in-memory storage / array
    public static func avg<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("avg:", keyPath: selector.propertyName, operator: .lessThan, value: value)
    }

    /// `avg` only work with in-memory storage / array
    public static func avg<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("avg:", keyPath: selector.propertyName, operator: .lessThanOrEqualTo, value: value)
    }

    // MARK: @min

    /// `min` only work with in-memory storage / array
    public static func min<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("min:", keyPath: selector.propertyName, operator: .equalTo, value: value)
    }

    /// `min` only work with in-memory storage / array
    public static func min<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("min:", keyPath: selector.propertyName, operator: .greaterThan, value: value)
    }

    /// `min` only work with in-memory storage / array
    public static func min<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("min:", keyPath: selector.propertyName, operator: .greaterThanOrEqualTo, value: value)
    }

    /// `min` only work with in-memory storage / array
    public static func min<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("min:", keyPath: selector.propertyName, operator: .lessThan, value: value)
    }

    /// `min` only work with in-memory storage / array
    public static func min<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("min:", keyPath: selector.propertyName, operator: .lessThanOrEqualTo, value: value)
    }

    // MARK: @max

    /// `max` only work with in-memory storage / array
    public static func max<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("max:", keyPath: selector.propertyName, operator: .equalTo, value: value)
    }

    /// `max` only work with in-memory storage / array
    public static func max<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("max:", keyPath: selector.propertyName, operator: .greaterThan, value: value)
    }

    /// `max` only work with in-memory storage / array
    public static func max<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("max:", keyPath: selector.propertyName, operator: .greaterThanOrEqualTo, value: value)
    }

    /// `max` only work with in-memory storage / array
    public static func max<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("max:", keyPath: selector.propertyName, operator: .lessThan, value: value)
    }

    /// `max` only work with in-memory storage / array
    public static func max<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateComputable
    {
        CollectionQuery("max:", keyPath: selector.propertyName, operator: .lessThanOrEqualTo, value: value)
    }
}
