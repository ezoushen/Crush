//
//  Operators.swift
//  Crush
//
//  Created by ezou on 2020/3/12.
//

import CoreData

extension NSPredicate {
    @inlinable public static var `true`: Self {
        Self.init(value: true)
    }

    @inlinable public static var `false`: Self {
        Self.init(value: false)
    }
}

public final class TypedPredicate<T: Entity>: NSPredicate { }

@inlinable func BEGINSWITH(_ string: SearchString) -> String {
    "BEGINSWITH\(string.type.modifier) \"\(string.string)\""
}

@inlinable func ENDSWITH(_ string: SearchString) -> String {
    "ENDSWITH\(string.type.modifier) \"\(string.string)\""
}

@inlinable func CONTAINS(_ string: SearchString) -> String {
    "CONTAINS\(string.type.modifier) \"\(string.string)\""
}

@inlinable func LIKE(_ string: SearchString) -> String {
    "LIKE\(string.type.modifier) \"\(string.string)\""
}

@inlinable func MATCHES(_ string: SearchString) -> String {
    "MATCHES\(string.type.modifier) \"\(string.string)\""
}

// MARK: - Property Condition

public final class PropertyCondition<T>: NSPredicate { }

extension PropertyCondition where T: PredicateEquatable {
    public convenience init(in rhs: Array<T>) {
        self.init(format: "SELF IN %@", NSArray(array: rhs))
    }
}

extension PropertyCondition where T: PredicateEquatable & Hashable {
    public convenience init(in rhs: Set<T>) {
        self.init(format: "SELF IN %@", NSSet(set: rhs))
    }
}

extension PropertyCondition where T: PredicateComparable & Comparable {
    public convenience init(in rhs: ClosedRange<T>) {
        self.init(format: "SELF BETWEEN {%@, %@}", rhs.lowerBound.predicateValue, rhs.upperBound.predicateValue)
    }

    public convenience init(largerThanOrEqualTo rhs: T) {
        self.init(format: "SELF >= \(rhs)")
    }

    public convenience init(smallerThanOrEqualTo rhs: T) {
        self.init(format: "SELF <= \(rhs)")
    }
    
    public convenience init(largerThan rhs: T) {
        self.init(format: "SELF > \(rhs)")
    }

    public convenience init(smallerThan rhs: T) {
        self.init(format: "SELF < \(rhs)")
    }
}

extension PropertyCondition where T == String {
    public convenience init(endsWith rhs: SearchString) {
        self.init(format: "SELF \(ENDSWITH(rhs))")
    }

    public convenience init(beginsWith rhs: SearchString) {
        self.init(format: "SELF \(BEGINSWITH(rhs))")
    }

    public convenience init(like rhs: SearchString) {
        self.init(format: "SELF \(LIKE(rhs))")
    }

    public convenience init(matches rhs: SearchString) {
        self.init(format: "SELF \(MATCHES(rhs))")
    }

    public convenience init(contains rhs: SearchString) {
        self.init(format: "SELF \(CONTAINS(rhs))")
    }
}

extension PropertyCondition where T: PredicateExpressibleByString {
    public convenience init(endsWith rhs: SearchString) {
        self.init(format: "SELF.stringValue \(ENDSWITH(rhs))")
    }

    public convenience init(beginsWith rhs: SearchString) {
        self.init(format: "SELF.stringValue \(BEGINSWITH(rhs))")
    }

    public convenience init(like rhs: SearchString) {
        self.init(format: "SELF.stringValue \(LIKE(rhs))")
    }

    public convenience init(matches rhs: SearchString) {
        self.init(format: "SELF.stringValue \(MATCHES(rhs))")
    }

    public convenience init(contains rhs: SearchString) {
        self.init(format: "SELF.stringValue \(CONTAINS(rhs))")
    }
}

// MARK: - Operators

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

// MARK: - Operator overloading for Entity

extension KeyPath where Root: Entity, Value: WritableValuedProperty, Value.PredicateValue: PredicateEquatable & Equatable & Hashable {
    public static func <> (lhs: KeyPath, rhs: Set<Value.PredicateValue>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath where Root: Entity, Value: WritableValuedProperty, Value.PredicateValue: PredicateEquatable & Equatable {
    public static func <> (lhs: KeyPath, rhs: Array<Value.PredicateValue>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where
    Root: Entity,
    Value: WritableValuedProperty,
    Value.PredicateValue: PredicateEquatable & Equatable
{
    public static func == (lhs: KeyPath, rhs: Value.PredicateValue?) -> TypedPredicate<Root> {
        guard let value = rhs?.predicateValue else {
            return TypedPredicate<Root>(format: "\(lhs.propertyName) == NULL")
        }
        return TypedPredicate<Root>(format: "\(lhs.propertyName) == %@", value)
    }

    public static func != (lhs: KeyPath, rhs: Value.PredicateValue?) -> TypedPredicate<Root> {
        guard let value = rhs?.predicateValue else {
            return TypedPredicate<Root>(format: "\(lhs.propertyName) != NULL")
        }
        return TypedPredicate<Root>(format: "\(lhs.propertyName) != %@", value)
    }

    public static func == (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) == \(rhs.propertyName)")
    }

    public static func != (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) != \(rhs.propertyName)")
    }
}

extension KeyPath where
    Root: Entity,
    Value: WritableValuedProperty,
    Value.PredicateValue: PredicateComparable & Comparable
{
    public static func > (lhs: KeyPath, rhs: Value.PredicateValue) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) > %@", rhs.predicateValue)
    }

    public static func < (lhs: KeyPath, rhs: Value.PredicateValue) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) < %@", rhs.predicateValue)
    }

    public static func >= (lhs: KeyPath, rhs: Value.PredicateValue) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) >= %@", rhs.predicateValue)
    }

    public static func <= (lhs: KeyPath, rhs: Value.PredicateValue) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) <= %@", rhs.predicateValue)
    }

    public static func <> (lhs: KeyPath, rhs: ClosedRange<Value.PredicateValue>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) BETWEEN {%@, %@}", rhs.lowerBound.predicateValue, rhs.upperBound.predicateValue)
    }

    public static func > (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) > \(rhs.propertyName)")
    }

    public static func < (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) < \(rhs.propertyName)")
    }

    public static func >= (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) >= \(rhs.propertyName)")
    }

    public static func <= (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) <= \(rhs.propertyName)")
    }
}

extension KeyPath where
    Root: Entity,
    Value: WritableValuedProperty,
    Value.PredicateValue == String
{
    public static func |~ (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(BEGINSWITH(rhs))")
    }

    public static func ~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(ENDSWITH(rhs))")
    }

    public static func <> (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(CONTAINS(rhs))")
    }

    public static func |~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(LIKE(rhs))")
    }

    public static func |*| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(MATCHES(rhs))")
    }
}

extension KeyPath where
    Root: Entity,
    Value: AttributeProtocol,
    Value.PredicateValue: PredicateExpressibleByString
{
    public static func |~ (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(BEGINSWITH(rhs))")
    }

    public static func ~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(ENDSWITH(rhs))")
    }

    public static func <> (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(CONTAINS(rhs))")
    }

    public static func |~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(LIKE(rhs))")
    }

    public static func |*| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(MATCHES(rhs))")
    }
}

@inlinable public func && <T: NSPredicate>(lhs: T, rhs: T) -> T {
    T(format: "(\(lhs)) AND (\(rhs))", argumentArray: nil)
}

@inlinable public func || <T: NSPredicate>(lhs: T, rhs: T) -> T {
    T(format: "(\(lhs)) OR (\(rhs))", argumentArray: nil)
}

@inlinable public prefix func ! <T: NSPredicate>(predicate: T) -> T {
    T(format: "NOT (\(predicate))", argumentArray: nil)
}

extension TypedPredicate {
    public static func subquery<Property: RelationshipProtocol>(
        _ keyPath: KeyPath<T, Property>, predicate: TypedPredicate<Property.Destination>
    ) -> TypedPredicate<T>
    where
        Property.Mapping == ToOne<Property.Destination>
    {
        TypedPredicate(format: "\(keyPath.propertyName).\(predicate.predicateFormat)")
    }

    public static func subquery<Property: RelationshipProtocol>(
        _ keyPath: KeyPath<T, Property>,
        predicate: TypedPredicate<Property.Destination>,
        collectionQuery: CollectionQuery<Property.Destination>
    ) -> TypedPredicate<T>
    where
        Property.Mapping == ToMany<Property.Destination>
    {
        TypedPredicate(
            format: "SUBQUERY(\(keyPath.propertyName)," +
                    "$x,$x.\(predicate.predicateFormat))" +
                    ".\(collectionQuery.predicateString)")
    }
}

