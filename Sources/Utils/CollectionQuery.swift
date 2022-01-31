//
//  CollectionQuery.swift
//  
//
//  Created by ezou on 2022/1/31.
//

import Foundation

public final class CollectionQuery<T: Entity> {

    let predicateString: String

    init(_ string: String) {
        predicateString = string
    }

    // MARK: @count

    public static func count(equalTo value: Int) -> CollectionQuery {
        CollectionQuery("@count == \(value)")
    }

    public static func count(greaterThan value: Int) -> CollectionQuery {
        CollectionQuery("@count > \(value)")
    }

    public static func count(greaterThanOrEqualTo value: Int) -> CollectionQuery {
        CollectionQuery("@count >= \(value)")
    }

    public static func count(lessThan value: Int) -> CollectionQuery {
        CollectionQuery("@count < \(value)")
    }

    public static func count(lessThanOrEqualTo value: Int) -> CollectionQuery {
        CollectionQuery("@count <= \(value)")
    }

    // MARK: @sum

    /// `sum` only work with in-memory storage / array
    public static func sum<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@sum.\(selector.propertyName) == \(value)")
    }

    /// `sum` only work with in-memory storage / array
    public static func sum<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@sum.\(selector.propertyName) > \(value)")
    }

    /// `sum` only work with in-memory storage / array
    public static func sum<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@sum.\(selector.propertyName) >= \(value)")
    }

    /// `sum` only work with in-memory storage / array
    public static func sum<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@sum.\(selector.propertyName) < \(value)")
    }

    /// `sum` only work with in-memory storage / array
    public static func sum<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@sum.\(selector.propertyName) <= \(value)")
    }

    // MARK: @avg

    /// `avg` only work with in-memory storage / array
    public static func avg<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@avg.\(selector.propertyName) == \(value)")
    }

    /// `avg` only work with in-memory storage / array
    public static func avg<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@avg.\(selector.propertyName) > \(value)")
    }

    /// `avg` only work with in-memory storage / array
    public static func avg<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@avg.\(selector.propertyName) >= \(value)")
    }

    /// `avg` only work with in-memory storage / array
    public static func avg<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@avg.\(selector.propertyName) < \(value)")
    }

    /// `avg` only work with in-memory storage / array
    public static func avg<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@avg.\(selector.propertyName) <= \(value)")
    }

    // MARK: @min

    /// `min` only work with in-memory storage / array
    public static func min<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@min.\(selector.propertyName) == \(value)")
    }

    /// `min` only work with in-memory storage / array
    public static func min<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@min.\(selector.propertyName) > \(value)")
    }

    /// `min` only work with in-memory storage / array
    public static func min<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@min.\(selector.propertyName) >= \(value)")
    }

    /// `min` only work with in-memory storage / array
    public static func min<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@min.\(selector.propertyName) < \(value)")
    }

    /// `min` only work with in-memory storage / array
    public static func min<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@min.\(selector.propertyName) <= \(value)")
    }

    // MARK: @max

    /// `max` only work with in-memory storage / array
    public static func max<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, equalTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@max.\(selector.propertyName) == \(value)")
    }

    /// `max` only work with in-memory storage / array
    public static func max<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@max.\(selector.propertyName) > \(value)")
    }

    /// `max` only work with in-memory storage / array
    public static func max<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, greaterThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@max.\(selector.propertyName) >= \(value)")
    }

    /// `max` only work with in-memory storage / array
    public static func max<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThan value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@max.\(selector.propertyName) < \(value)")
    }

    /// `max` only work with in-memory storage / array
    public static func max<S: ValuedProperty>(
        _ selector: KeyPath<T, S>, lessThanOrEqualTo value: Int) -> CollectionQuery
    where
        S.FieldConvertor: PredicateAggregatable
    {
        CollectionQuery("@max.\(selector.propertyName) <= \(value)")
    }
}
