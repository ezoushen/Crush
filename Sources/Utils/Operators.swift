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

// MARK: - Property Condition

public final class PropertyCondition: NSPredicate {
    public convenience init<T: PredicateComparable>(in rhs: ClosedRange<T>) {
        self.init(format: "SELF BETWEEN {%@, %@}", rhs.lowerBound.predicateValue, rhs.upperBound.predicateValue)
    }

    public convenience init<T: PredicateEquatable>(in rhs: Array<T>) {
        self.init(format: "SELF IN %@", NSArray(array: rhs))
    }

    public convenience init<T: PredicateEquatable>(in rhs: Set<T>) {
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

private var propertyNameCache: NSCache<AnyKeyPath, NSString> = .init()

extension PartialKeyPath: CustomStringConvertible where Root: Entity {
    var optionalPropertyName: String? {
        guard let name = propertyNameCache.object(forKey: self) else {
            if let name = (Root.init()[keyPath: self] as? PropertyProtocol)?.name {
                propertyNameCache.setObject(name as NSString, forKey: self)
                return name
            }
            return nil
        }
        return name as String
    }

    public var description: String {
        optionalPropertyName ?? "\(self)"
    }
}

extension KeyPath where Root: Entity, Value: PropertyProtocol {
    var propertyName: String {
        guard let name = propertyNameCache.object(forKey: self) else {
            let name = Root.init()[keyPath: self].name
            propertyNameCache.setObject(name as NSString, forKey: self)
            return name
        }
        return name as String
    }
}

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
    Value.PredicateValue: PredicateExpressedByString
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

public func && (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(andPredicateWithSubpredicates: [lhs, rhs])
}

public func || (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(orPredicateWithSubpredicates: [lhs, rhs])
}

public prefix func ! (predicat: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(notPredicateWithSubpredicate: predicat)
}
