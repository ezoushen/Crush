//
//  Operators.swift
//  Crush
//
//  Created by ezou on 2020/3/12.
//

import CoreData

public final class TypedPredicate<T: Entity>: NSPredicate {
    @inlinable public static prefix func ! (_ predicate: TypedPredicate<T>) -> TypedPredicate<T> {
        TypedPredicate<T>(format: NSCompoundPredicate(notPredicateWithSubpredicate: predicate).predicateFormat)
    }

    @inlinable public static func && (lhs: NSPredicate, rhs: TypedPredicate) -> TypedPredicate {
        TypedPredicate<T>(format: NSCompoundPredicate(andPredicateWithSubpredicates: [lhs, rhs]).predicateFormat)
    }

    @inlinable public static func || (lhs: NSPredicate, rhs: TypedPredicate) -> TypedPredicate {
        TypedPredicate<T>(format: NSCompoundPredicate(orPredicateWithSubpredicates: [lhs, rhs]).predicateFormat)
    }
}

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

// MARK: - Validation

public final class ValidationCondition: NSPredicate {
    public convenience init<T: PredicateComparable>(between rhs: ClosedRange<T>) {
        self.init(format: "SELF BETWEEN {%@, %@}", rhs.lowerBound.predicateValue, rhs.upperBound.predicateValue)
    }

    public convenience init<T: PredicateEquatable>(between rhs: Array<T>) {
        self.init(format: "SELF IN %@", NSArray(array: rhs))
    }

    public convenience init<T: PredicateEquatable>(between rhs: Set<T>) {
        self.init(format: "SELF IN %@", NSSet(set: rhs))
    }

    public convenience init(largerThanOrEqualsTo rhs: PredicateComparable) {
        self.init(format: "SELF >= \(rhs)")
    }

    public convenience init(smallerThanOrEqualsTo rhs: PredicateComparable) {
        self.init(format: "SELF <= \(rhs)")
    }

    public convenience init(largerThan rhs: PredicateComparable) {
        self.init(format: "SELF > \(rhs)")
    }

    public convenience init(smallerThan rhs: PredicateComparable) {
        self.init(format: "SELF < \(rhs)")
    }

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

extension KeyPath where Root: Entity, Value: ValuedProperty {
    public var propertyName: String {
        Root.init()[keyPath: self].name
    }
}

extension KeyPath where Root: Entity, Value: ValuedProperty, Value.PredicateValue: PredicateEquatable & Equatable & Hashable {
    @inlinable public static func <> (lhs: KeyPath, rhs: Set<Value.PredicateValue>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath where Root: Entity, Value: ValuedProperty, Value.PredicateValue: PredicateEquatable & Equatable {
    @inlinable public static func <> (lhs: KeyPath, rhs: Array<Value.PredicateValue>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where
    Root: Entity,
    Value: ValuedProperty,
    Value.PredicateValue: PredicateEquatable & Equatable,
    Value.Nullability == NotNull
{
    @inlinable public static func == (lhs: KeyPath, rhs: Value.PredicateValue) -> TypedPredicate<Root> {
        return TypedPredicate(format: "\(lhs.propertyName) == %@", rhs.predicateValue)
    }

    @inlinable public static func != (lhs: KeyPath, rhs: Value.PredicateValue) -> TypedPredicate<Root> {
        return TypedPredicate(format: "\(lhs.propertyName) != %@", rhs.predicateValue)
    }
}

extension KeyPath where
    Root: Entity,
    Value: ValuedProperty,
    Value.PredicateValue: PredicateEquatable & Equatable,
    Value.Nullability == Nullable
{
    @inlinable public static func == (lhs: KeyPath, rhs: Value.PredicateValue?) -> TypedPredicate<Root> {
        guard let value = rhs?.predicateValue else {
            return TypedPredicate<Root>(format: "\(lhs.propertyName) == NULL")
        }
        return TypedPredicate<Root>(format: "\(lhs.propertyName) == %@", value)
    }

    @inlinable public static func != (lhs: KeyPath, rhs: Value.PredicateValue?) -> TypedPredicate<Root> {
        guard let value = rhs?.predicateValue else {
            return TypedPredicate<Root>(format: "\(lhs.propertyName) != NULL")
        }
        return TypedPredicate<Root>(format: "\(lhs.propertyName) != %@", value)
    }
}

extension KeyPath where Root: Entity, Value: ValuedProperty, Value.PredicateValue: PredicateComparable & Comparable {
    @inlinable public static func > (lhs: KeyPath, rhs: Value.PredicateValue) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) > %@", rhs.predicateValue)
    }

    @inlinable public static func < (lhs: KeyPath, rhs: Value.PredicateValue) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) < %@", rhs.predicateValue)
    }

    @inlinable public static func >= (lhs: KeyPath, rhs: Value.PredicateValue) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) >= %@", rhs.predicateValue)
    }

    @inlinable public static func <= (lhs: KeyPath, rhs: Value.PredicateValue) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) <= %@", rhs.predicateValue)
    }

    @inlinable public static func <> (lhs: KeyPath, rhs: ClosedRange<Value.PredicateValue>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) BETWEEN {%@, %@}", rhs.lowerBound.predicateValue, rhs.upperBound.predicateValue)
    }
}

extension KeyPath where Root: Entity, Value: ValuedProperty, Value.PredicateValue == String {
    @inlinable public static func |~ (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(BEGINSWITH(rhs))")
    }

    @inlinable public static func ~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(ENDSWITH(rhs))")
    }

    @inlinable public static func <> (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(CONTAINS(rhs))")
    }

    @inlinable public static func |~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(LIKE(rhs))")
    }

    @inlinable public static func |*| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(MATCHES(rhs))")
    }
}

extension KeyPath where Root: Entity, Value: AttributeProtocol, Value.PredicateValue: PredicateExpressedByString {
    @inlinable public static func |~ (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(BEGINSWITH(rhs))")
    }

    @inlinable public static func ~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(ENDSWITH(rhs))")
    }

    @inlinable public static func <> (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(CONTAINS(rhs))")
    }

    @inlinable public static func |~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(LIKE(rhs))")
    }

    @inlinable public static func |*| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(MATCHES(rhs))")
    }
}
