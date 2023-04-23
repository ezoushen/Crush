//
//  CollectionQuery.swift
//  
//
//  Created by ezou on 2022/1/31.
//

import Foundation

/// Aggregate functions that used to evaluate collections. It defines the aggregate function and the following predicate.
public struct CollectionQuery<T: Entity> {

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

    /// It's equal to "@count == %d"
    public static func count(equalTo value: Int) -> CollectionQuery {
        CollectionQuery("count:", keyPath: nil, operator: .equalTo, value: value)
    }

    /// It's equal to "@count > %d"
    public static func count(greaterThan value: Int) -> CollectionQuery {
        CollectionQuery("count:", keyPath: nil, operator: .greaterThan, value: value)
    }

    /// It's equal to "@count >= %d"
    public static func count(greaterThanOrEqualTo value: Int) -> CollectionQuery {
        CollectionQuery("count:", keyPath: nil, operator: .greaterThanOrEqualTo, value: value)
    }

    /// It's equal to "@count < %d"
    public static func count(lessThan value: Int) -> CollectionQuery {
        CollectionQuery("count:", keyPath: nil, operator: .lessThan, value: value)
    }

    /// It's equal to "@count <= %d"
    public static func count(lessThanOrEqualTo value: Int) -> CollectionQuery {
        CollectionQuery("count:", keyPath: nil, operator: .lessThanOrEqualTo, value: value)
    }

    // MARK: @sum

    /// It's equal to "@sum == %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func sum<S: Property>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("sum:", keyPath: selector.propertyName, operator: .equalTo, value: value)
    }

    /// It's equal to "@sum > %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func sum<S: Property>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("sum:", keyPath: selector.propertyName, operator: .greaterThan, value: value)
    }

    /// It's equal to "@sum >= %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func sum<S: Property>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("sum:", keyPath: selector.propertyName, operator: .greaterThanOrEqualTo, value: value)
    }

    /// It's equal to "@sum < %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func sum<S: Property>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("sum:", keyPath: selector.propertyName, operator: .lessThan, value: value)
    }

    /// It's equal to "@sum <= %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func sum<S: Property>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("sum:", keyPath: selector.propertyName, operator: .lessThanOrEqualTo, value: value)
    }

    // MARK: @avg

    /// It's equal to "@avg == %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func avg<S: Property>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("avg:", keyPath: selector.propertyName, operator: .equalTo, value: value)
    }

    /// It's equal to "@avg > %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func avg<S: Property>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("avg:", keyPath: selector.propertyName, operator: .greaterThan, value: value)
    }

    /// It's equal to "@avg >= %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func avg<S: Property>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("avg:", keyPath: selector.propertyName, operator: .greaterThanOrEqualTo, value: value)
    }

    /// It's equal to "@avg < %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func avg<S: Property>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("avg:", keyPath: selector.propertyName, operator: .lessThan, value: value)
    }

    /// It's equal to "@avg <=> %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func avg<S: Property>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("avg:", keyPath: selector.propertyName, operator: .lessThanOrEqualTo, value: value)
    }

    // MARK: @min

    /// It's equal to "@min == %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func min<S: Property>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("min:", keyPath: selector.propertyName, operator: .equalTo, value: value)
    }

    /// It's equal to "@min > %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func min<S: Property>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("min:", keyPath: selector.propertyName, operator: .greaterThan, value: value)
    }

    /// It's equal to "@min >= %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func min<S: Property>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("min:", keyPath: selector.propertyName, operator: .greaterThanOrEqualTo, value: value)
    }

    /// It's equal to "@min < %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func min<S: Property>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("min:", keyPath: selector.propertyName, operator: .lessThan, value: value)
    }

    /// It's equal to "@min <=> %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func min<S: Property>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("min:", keyPath: selector.propertyName, operator: .lessThanOrEqualTo, value: value)
    }

    // MARK: @max

    /// It's equal to "@max == %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func max<S: Property>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("max:", keyPath: selector.propertyName, operator: .equalTo, value: value)
    }

    /// It's equal to "@max > %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func max<S: Property>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("max:", keyPath: selector.propertyName, operator: .greaterThan, value: value)
    }

    /// It's equal to "@max >= %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func max<S: Property>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("max:", keyPath: selector.propertyName, operator: .greaterThanOrEqualTo, value: value)
    }

    /// It's equal to "@max < %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func max<S: Property>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("max:", keyPath: selector.propertyName, operator: .lessThan, value: value)
    }

    /// It's equal to "@max <= %d", only work with `NSArray` and CoreData subquery backed by in-memory store.
    public static func max<S: Property>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.PredicateValue: PredicateComputable
    {
        CollectionQuery("max:", keyPath: selector.propertyName, operator: .lessThanOrEqualTo, value: value)
    }
}
