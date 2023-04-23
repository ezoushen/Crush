//
//  Operators.swift
//  Crush
//
//  Created by ezou on 2020/3/12.
//

import CoreData

extension NSPredicate {
    /// Convenient getter for `NSPredicate(value: true)`
    @inlinable public static var `true`: Self {
        Self.init(value: true)
    }

    /// Convenient getter for `NSPredicate(value: false)`
    @inlinable public static var `false`: Self {
        Self.init(value: false)
    }
}

@inlinable func BEGINSWITH<T: Entity>(_ string: SearchString<T>) -> String {
    "BEGINSWITH\(string.type.modifier)"
}

@inlinable func ENDSWITH<T: Entity>(_ string: SearchString<T>) -> String {
    "ENDSWITH\(string.type.modifier)"
}

@inlinable func CONTAINS<T: Entity>(_ string: SearchString<T>) -> String {
    "CONTAINS\(string.type.modifier)"
}

@inlinable func LIKE<T: Entity>(_ string: SearchString<T>) -> String {
    "LIKE\(string.type.modifier)"
}

@inlinable func MATCHES<T: Entity>(_ string: SearchString<T>) -> String {
    "MATCHES\(string.type.modifier)"
}

// MARK: - Property Condition

public final class PropertyCondition<T>: NSPredicate { }

extension PropertyCondition where T: PredicateEquatable {
    @inlinable public static func compare(notEqualTo value: T) -> Self {
        self.init(format: "SELF != %@", value.predicateValue)
    }

    @inlinable public static func compare(equalTo value: T) -> Self {
        self.init(format: "SELF == %@", value.predicateValue)
    }

    @inlinable public static func compare(in rhs: Array<T>) -> Self {
        self.init(format: "SELF IN %@", NSArray(array: rhs.map(\.predicateValue)))
    }
}

extension PropertyCondition where T: PredicateEquatable & Hashable {
    @inlinable public static func compare(in rhs: Set<T>) -> Self {
        self.init(format: "SELF IN %@", NSSet(set: rhs))
    }
}

extension PropertyCondition where T: PredicateComparable & Comparable {
    @inlinable public static func compare(between rhs: ClosedRange<T>) -> Self {
        self.init(
            format: "SELF BETWEEN {%@, %@}",
            rhs.lowerBound.predicateValue,
            rhs.upperBound.predicateValue)
    }

    @inlinable public static func compare(between rhs: Range<T>) -> Self {
        self.init(
            format: "SELF >= %@ AND SELF < %@",
            rhs.lowerBound.predicateValue,
            rhs.upperBound.predicateValue)
    }

    @inlinable public static func compare(greaterThanOrEqualTo rhs: T) -> Self {
        self.init(format: "SELF >= \(rhs)")
    }

    @inlinable public static func compare(lessThanOrEqualTo rhs: T) -> Self {
        self.init(format: "SELF <= \(rhs)")
    }

    @inlinable public static func compare(greaterThan rhs: T) -> Self {
        self.init(format: "SELF > \(rhs)")
    }

    @inlinable public static func compare(lessThan rhs: T) -> Self {
        self.init(format: "SELF < \(rhs)")
    }
}

extension KeyPath
where
    Root: Entity,
    Value == Root
{
    @inlinable public static func == <T: EntityEquatableType>(lhs: KeyPath, rhs: T) -> PropertyCondition<T> {
        .compare(equalTo: rhs)
    }

    @inlinable public static func != <T: EntityEquatableType>(lhs: KeyPath, rhs: T) -> PropertyCondition<T> {
        .compare(notEqualTo: rhs)
    }

    @inlinable public static func <> <T: EntityEquatableType>(lhs: KeyPath, rhs: [T]) -> PropertyCondition<T> {
        .compare(in: rhs)
    }

    @inlinable public static func <> <T: EntityEquatableType & Hashable>(lhs: KeyPath, rhs: Set<T>) -> PropertyCondition<T> {
        .compare(in: rhs)
    }
}

extension PropertyCondition where T == String {
    @inlinable public static func string(endsWith rhs: SearchString<Entity>) -> Self {
        self.init(format: "SELF \(ENDSWITH(rhs)) \(rhs.placeholder)", rhs.string)
    }

    @inlinable public static func string(beginsWith rhs: SearchString<Entity>) -> Self {
        self.init(format: "SELF \(BEGINSWITH(rhs)) \(rhs.placeholder)", rhs.string)
    }

    @inlinable public static func string(like rhs: SearchString<Entity>) -> Self {
        self.init(format: "SELF \(LIKE(rhs)) \(rhs.placeholder)", rhs.string)
    }

    @inlinable public static func string(matches rhs: SearchString<Entity>) -> Self {
        self.init(format: "SELF \(MATCHES(rhs)) \(rhs.placeholder)", rhs.string)
    }

    @inlinable public static func string(contains rhs: SearchString<Entity>) -> Self {
        self.init(format: "SELF \(CONTAINS(rhs)) \(rhs.placeholder)", rhs.string)
    }
}

extension PropertyCondition where T: PredicateExpressibleByString {
    @inlinable public static func string(endsWith rhs: SearchString<Entity>) -> Self {
        self.init(format: "SELF.stringValue \(ENDSWITH(rhs)) \(rhs.placeholder)", rhs.string)
    }

    @inlinable public static func string(beginsWith rhs: SearchString<Entity>) -> Self {
        self.init(format: "SELF.stringValue \(BEGINSWITH(rhs)) \(rhs.placeholder)", rhs.string)
    }

    @inlinable public static func string(like rhs: SearchString<Entity>) -> Self {
        self.init(format: "SELF.stringValue \(LIKE(rhs)) \(rhs.placeholder)", rhs.string)
    }

    @inlinable public static func string(matches rhs: SearchString<Entity>) -> Self {
        self.init(format: "SELF.stringValue \(MATCHES(rhs)) \(rhs.placeholder)", rhs.string)
    }

    @inlinable public static func string(contains rhs: SearchString<Entity>) -> Self {
        self.init(format: "SELF.stringValue \(CONTAINS(rhs)) \(rhs.placeholder)", rhs.string)
    }
}

extension PropertyCondition where T == String {
    @inlinable public static func length(equalTo length: Int) -> Self {
        self.init(format: "length == \(length)")
    }

    @inlinable public static func length(greaterThanOrEqualTo length: Int) -> Self {
        self.init(format: "length >= \(length)")
    }

    @inlinable public static func length(lessThanOrEqualTo length: Int) -> Self {
        self.init(format: "length <= \(length)")
    }

    @inlinable public static func length(greaterThan length: Int) -> Self {
        self.init(format: "length > \(length)")
    }

    @inlinable public static func length(lessThan length: Int) -> Self {
        self.init(format: "length < \(length)")
    }

    @inlinable public static func length(between range: ClosedRange<Int>) -> Self {
        self.init(format: "length BETWEEN {\(range.lowerBound), \(range.upperBound)}")
    }

    @inlinable public static func length(between range: Range<Int>) -> Self {
        self.init(format: "length >= \(range.lowerBound) AND length < \(range.upperBound)")
    }
}

extension PropertyCondition where T: PredicateExpressibleByString {
    @inlinable public static func length(equalTo length: Int) -> Self {
        self.init(format: "SELF.stringValue.length == \(length)")
    }

    @inlinable public static func length(greaterThanOrEqualTo length: Int) -> Self {
        self.init(format: "SELF.stringValue.length > \(length)")
    }

    @inlinable public static func length(lessThanOrEqualTo length: Int) -> Self {
        self.init(format: "SELF.stringValue.length <= \(length)")
    }

    @inlinable public static func length(greaterThan length: Int) -> Self {
        self.init(format: "SELF.stringValue.length > \(length)")
    }

    @inlinable public static func length(lessThan length: Int) -> Self {
        self.init(format: "SELF.stringValue.length < \(length)")
    }

    @inlinable public static func length(between range: ClosedRange<Int>) -> Self {
        self.init(format: "SELF.stringValue.length BETWEEN {\(range.lowerBound), \(range.upperBound)}")
    }

    @inlinable public static func length(between range: Range<Int>) -> Self {
        self.init(format: "SELF.stringValue.length >= \(range.lowerBound) AND SELF.stringValue.length < \(range.upperBound)")
    }
}

// MARK: Predicate

/// NSPredicate bounded to generic type `T` that inheriting from ``Entity``.
/// This class helps the compiler determines `Root` of the `KeyPath` that will be used in operators overloaded
/// for instantiate a `NSPredicate`.
///
/// Example:
///
///     // Equal to "someProperty == 1"
///     let predicate: TypedPredicate<SomeEntity> = \.someProperty == 1
///
/// It also provides `join` for concanating `KeyPath` in different classes and `subquery` for constructing subquery predicate.
///
/// Example:
///
///     let joinPredicate: TypedPredicate<SomeEntity> = .join(
///         \.toOneRelationshipToAnotherEntity,
///         predicate: \.propertyOfAnotherEntity == 1)
///
///     let subqueryPredicate: TypedPredicate<SomeEntity> = .subquery(
///         \.toManyRelationshipToAnotherEntity,
///         predicate: \.propertyOfAnotherEntity == 1,
///         collectionQuery: .count(greaterThan: 1))
///
public final class TypedPredicate<T: Entity>: NSPredicate { }

// MARK: - Operators

/// CONTAINS, BETWEEN operator
infix operator <>
/// BEGINSWITH operator
infix operator |~
/// ENDSWITH operator
infix operator ~|
/// LINE operator
infix operator |~|
/// MATCHES operator
infix operator |*|

// MARK: - Operator overloading for Entity

extension KeyPath
where
    Root: Entity,
    Value: WritableProperty,
    Value.PredicateValue: PredicateEquatable & Equatable & Hashable
{
    public static func <> (lhs: KeyPath, rhs: Set<Value.PredicateValue>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath
where
    Root: Entity,
	Value: WritableProperty,
    Value.PredicateValue: PredicateEquatable & Equatable
{
    public static func <> (lhs: KeyPath, rhs: Array<Value.PredicateValue>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where
    Root: Entity,
    Value: RelationshipProtocol,
    Value.Mapping == ToOne<Value.Destination>
{
    public static func == <T: EntityEquatableType>(
        lhs: KeyPath, rhs: T) -> TypedPredicate<Root>
    {
        TypedPredicate<Root>(
            format: "\(lhs.propertyName) == %@", rhs.predicateValue)
    }

    public static func != <T: EntityEquatableType>(
        lhs: KeyPath, rhs: T) -> TypedPredicate<Root>
    {
        TypedPredicate<Root>(
            format: "\(lhs.propertyName) != %@", rhs.predicateValue)
    }

    public static func == (lhs: KeyPath, rhs: NSNull?) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) == NULL")
    }

    public static func != (lhs: KeyPath, rhs: NSNull?) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) != NULL")
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
    Value: WritableProperty,
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
    Value: WritableProperty,
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

    public static func <> (
        lhs: KeyPath, rhs: ClosedRange<Value.PredicateValue>) -> TypedPredicate<Root>
    {
        TypedPredicate<Root>(
            format: "\(lhs.propertyName) BETWEEN {%@, %@}",
            rhs.lowerBound.predicateValue,
            rhs.upperBound.predicateValue)
    }
    
    public static func <> (
        lhs: KeyPath, rhs: Range<Value.PredicateValue>) -> TypedPredicate<Root>
    {
        TypedPredicate<Root>(
            format: "\(lhs.propertyName) >= %@ AND \(lhs.propertyName) < %@",
            rhs.lowerBound.predicateValue,
            rhs.upperBound.predicateValue)
    }
    
    public static func > <T>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where
        T: WritableProperty,
        T.PredicateValue == Value.PredicateValue
    {
        TypedPredicate<Root>(format: "\(lhs.propertyName) > \(rhs.propertyName)")
    }

    public static func < <T>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where
        T: WritableProperty,
        T.PredicateValue == Value.PredicateValue
    {
        TypedPredicate<Root>(format: "\(lhs.propertyName) < \(rhs.propertyName)")
    }

    public static func >= <T>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where
        T: WritableProperty,
        T.PredicateValue == Value.PredicateValue
    {
        TypedPredicate<Root>(format: "\(lhs.propertyName) >= \(rhs.propertyName)")
    }

    public static func <= <T>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where
        T: WritableProperty,
        T.PredicateValue == Value.PredicateValue
    {
        TypedPredicate<Root>(format: "\(lhs.propertyName) <= \(rhs.propertyName)")
    }
}

extension KeyPath where
    Root: Entity,
    Value: WritableProperty,
    Value.PredicateValue == String
{
    public static func |~ (lhs: KeyPath, rhs: SearchString<Root>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(BEGINSWITH(rhs)) \(rhs.placeholder)", rhs.string)
    }

    public static func ~| (lhs: KeyPath, rhs: SearchString<Root>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(ENDSWITH(rhs)) \(rhs.placeholder)", rhs.string)
    }

    public static func <> (lhs: KeyPath, rhs: SearchString<Root>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(CONTAINS(rhs)) \(rhs.placeholder)", rhs.string)
    }

    public static func |~| (lhs: KeyPath, rhs: SearchString<Root>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(LIKE(rhs)) \(rhs.placeholder)", rhs.string)
    }

    public static func |*| (lhs: KeyPath, rhs: SearchString<Root>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(MATCHES(rhs)) \(rhs.placeholder)", rhs.string)
    }

    @inlinable public static func |~ (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        lhs |~ SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func ~| (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        lhs ~| SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func <> (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        lhs <> SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func |~| (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        lhs |~| SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func |*| (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        lhs |*| SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func |~ <T: WritableProperty>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where T.PredicateValue: PredicateExpressibleByString {
        lhs |~ SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func ~| <T: WritableProperty>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where T.PredicateValue: PredicateExpressibleByString {
        lhs ~| SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func <> <T: WritableProperty>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where T.PredicateValue: PredicateExpressibleByString {
        lhs <> SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func |~| <T: WritableProperty>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where T.PredicateValue: PredicateExpressibleByString {
        lhs |~| SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func |*| <T: WritableProperty>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where T.PredicateValue: PredicateExpressibleByString {
        lhs |*| SearchString(rhs, modifier: .plain)
    }
}

extension KeyPath where
    Root: Entity,
    Value: AttributeProtocol,
    Value.PredicateValue: PredicateExpressibleByString
{
    public static func |~ (lhs: KeyPath, rhs: SearchString<Root>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(BEGINSWITH(rhs)) \(rhs.placeholder)", rhs.string)
    }

    public static func ~| (lhs: KeyPath, rhs: SearchString<Root>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(ENDSWITH(rhs)) \(rhs.placeholder)", rhs.string)
    }

    public static func <> (lhs: KeyPath, rhs: SearchString<Root>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(CONTAINS(rhs)) \(rhs.placeholder)", rhs.string)
    }

    public static func |~| (lhs: KeyPath, rhs: SearchString<Root>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(LIKE(rhs)) \(rhs.placeholder)", rhs.string)
    }

    public static func |*| (lhs: KeyPath, rhs: SearchString<Root>) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(MATCHES(rhs)) \(rhs.placeholder)", rhs.string)
    }

    @inlinable public static func |~ (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        lhs |~ SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func ~| (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        lhs ~| SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func <> (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        lhs <> SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func |~| (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        lhs |~| SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func |*| (lhs: KeyPath, rhs: KeyPath) -> TypedPredicate<Root> {
        lhs |*| SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func |~ <T: WritableProperty>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where T.PredicateValue == String {
        lhs |~ SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func ~| <T: WritableProperty>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where T.PredicateValue == String {
        lhs ~| SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func <> <T: WritableProperty>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where T.PredicateValue == String {
        lhs <> SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func |~| <T: WritableProperty>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where T.PredicateValue == String {
        lhs |~| SearchString(rhs, modifier: .plain)
    }

    @inlinable public static func |*| <T: WritableProperty>(lhs: KeyPath, rhs: KeyPath<Root, T>) -> TypedPredicate<Root>
    where T.PredicateValue == String {
        lhs |*| SearchString(rhs, modifier: .plain)
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

    public static func subquery<Property: RelationshipProtocol>(
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
        Property.Mapping: ToManyRelationMappingProtocol,
        Property.Mapping.EntityType == Property.Destination
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

