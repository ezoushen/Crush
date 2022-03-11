//
//  Operators.swift
//  Crush
//
//  Created by ezou on 2020/3/12.
//

import CoreData

public protocol RangeProtocol: RangeExpression {
    var upperBound: Bound { get }
    var lowerBound: Bound { get }
}

extension Range: RangeProtocol { }

extension ClosedRange: RangeProtocol { }

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
    public convenience init<R: RangeProtocol>(in rhs: R) where R.Bound == T {
        self.init(
            format: "SELF BETWEEN {%@, %@}",
            rhs.lowerBound.predicateValue,
            rhs.upperBound.predicateValue)
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

extension KeyPath
where
    Root: Entity,
    Value: WritableValuedProperty,
    Value.PredicateValue: PredicateEquatable & Equatable & Hashable
{
    public static func <> (lhs: KeyPath, rhs: Set<Value.PredicateValue>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath
where
    Root: Entity,
	Value: WritableValuedProperty,
    Value.PredicateValue: PredicateEquatable & Equatable
{
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

    public static func <> <R: RangeProtocol>(
        lhs: KeyPath, rhs: R) -> TypedPredicate<Root> where R.Bound == Value.PredicateValue
    {
        TypedPredicate<Root>(
            format: "\(lhs.propertyName) BETWEEN {%@, %@}",
            rhs.lowerBound.predicateValue,
            rhs.upperBound.predicateValue)
    }
    
    public static func > <T>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where
        T: WritableValuedProperty,
        T.PredicateValue == Value.PredicateValue
    {
        TypedPredicate<Root>(format: "\(lhs.propertyName) > \(rhs.propertyName)")
    }

    public static func < <T>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where
        T: WritableValuedProperty,
        T.PredicateValue == Value.PredicateValue
    {
        TypedPredicate<Root>(format: "\(lhs.propertyName) < \(rhs.propertyName)")
    }

    public static func >= <T>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where
        T: WritableValuedProperty,
        T.PredicateValue == Value.PredicateValue
    {
        TypedPredicate<Root>(format: "\(lhs.propertyName) >= \(rhs.propertyName)")
    }

    public static func <= <T>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where
        T: WritableValuedProperty,
        T.PredicateValue == Value.PredicateValue
    {
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

private func cast<T: NSObject>(_ object: NSObject) -> T {
    if let object = object as? T { return object }
    let clazz: AnyClass = object_getClass(object)!
    object_setClass(object, T.self)
    defer { object_setClass(object, clazz) }
    return object as! T
}

public func && <T: NSPredicate>(lhs: T, rhs: T) -> T {
    cast(NSCompoundPredicate(andPredicateWithSubpredicates: [lhs, rhs]))
}

public func || <T: NSPredicate>(lhs: T, rhs: T) -> NSPredicate {
    cast(NSCompoundPredicate(orPredicateWithSubpredicates: [lhs, rhs]))
}

public prefix func ! (predicate: NSPredicate) -> NSPredicate {
    cast(NSCompoundPredicate(notPredicateWithSubpredicate: predicate))
}

extension TypedPredicate {
    private static func updatePredicate(
        _ predicate: NSPredicate, block: (NSComparisonPredicate) -> Void)
    {
        if let predicate = predicate as? NSCompoundPredicate {
            for subpredicate in predicate.subpredicates {
                updatePredicate(subpredicate as! NSPredicate, block: block)
            }
        } else if let predicate = predicate as? NSComparisonPredicate {
            block(predicate)
        }
    }

    public static func join<Property: RelationshipProtocol>(
        _ keyPath: KeyPath<T, Property>, predicate: TypedPredicate<Property.Destination>
    ) -> Self
    where
        Property.Mapping == ToOne<Property.Destination>
    {
        let keyPath = keyPath.propertyName
        updatePredicate(predicate) { predicate in
            let originKeyPath = predicate.leftExpression.keyPath
            let expression = NSExpression(forKeyPath: "\(keyPath).\(originKeyPath)")
            predicate.setValue(expression, forKey: "_lhs")
        }
        return cast(predicate)
    }

    public static func subquery<Property: RelationshipProtocol>(
        _ keyPath: KeyPath<T, Property>,
        predicate: TypedPredicate<Property.Destination>,
        collectionQuery: CollectionQuery<Property.Destination>
    ) -> Self
    where
        Property.Mapping == ToMany<Property.Destination>
    {
        updatePredicate(predicate) { predicate in
            let expression = NSExpression(
                forFunction: NSExpression(forVariable: "x"),
                selectorName: "valueForKeyPath:",
                arguments: [NSExpression(forConstantValue: predicate.leftExpression.keyPath)])
            predicate.setValue(expression, forKey: "_lhs")
        }
        return cast(NSComparisonPredicate(
            leftExpression: NSExpression(forFunction: collectionQuery.function, arguments: [
                NSExpression(
                    forSubquery: NSExpression(forKeyPath: keyPath.propertyName),
                    usingIteratorVariable: "x",
                    predicate: predicate)
            ]),
            rightExpression: NSExpression(forConstantValue: collectionQuery.value),
            modifier: .direct,
            type: collectionQuery.operator,
            options: .init(rawValue: 0)))
    }
}

