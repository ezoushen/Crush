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
    "BEGINSWITH\(string.type.modifier)"
}

@inlinable func ENDSWITH(_ string: SearchString) -> String {
    "ENDSWITH\(string.type.modifier)"
}

@inlinable func CONTAINS(_ string: SearchString) -> String {
    "CONTAINS\(string.type.modifier)"
}

@inlinable func LIKE(_ string: SearchString) -> String {
    "LIKE\(string.type.modifier)"
}

@inlinable func MATCHES(_ string: SearchString) -> String {
    "MATCHES\(string.type.modifier)"
}

// MARK: - Property Condition

public final class PropertyCondition<T>: NSPredicate { }

extension PropertyCondition where T: PredicateEquatable {
    public convenience init(notEqualTo value: T) {
        self.init(format: "SELF != %@", value.predicateValue)
    }

    public convenience init(equalTo value: T) {
        self.init(format: "SELF == %@", value.predicateValue)
    }

    public convenience init(in rhs: Array<T>) {
        self.init(format: "SELF IN %@", NSArray(array: rhs.map(\.predicateValue)))
    }

    @inlinable public static func notEqual(to value: T) -> Self {
        self.init(notEqualTo: value)
    }

    @inlinable public static func equal(to value: T) -> Self {
        self.init(equalTo: value)
    }

    @inlinable public static func with(in rhs: Array<T>) -> Self {
        self.init(in: rhs)
    }
}

extension PropertyCondition where T: PredicateEquatable & Hashable {
    public convenience init(in rhs: Set<T>) {
        self.init(format: "SELF IN %@", NSSet(set: rhs))
    }

    @inlinable public static func with(in rhs: Set<T>) -> Self {
        self.init(in: rhs)
    }
}

extension PropertyCondition where T: PredicateComparable & Comparable {
    public convenience init(in rhs: ClosedRange<T>) {
        self.init(
            format: "SELF BETWEEN {%@, %@}",
            rhs.lowerBound.predicateValue,
            rhs.upperBound.predicateValue)
    }
    
    public convenience init(in rhs: Range<T>) {
        self.init(
            format: "SELF >= %@ AND SELF < %@",
            rhs.lowerBound.predicateValue,
            rhs.upperBound.predicateValue)
    }

    public convenience init(largerThanOrEqualTo rhs: T) {
        self.init(format: "SELF >= \(rhs)")
    }

    public convenience init(lessThanOrEqualTo rhs: T) {
        self.init(format: "SELF <= \(rhs)")
    }
    
    public convenience init(largerThan rhs: T) {
        self.init(format: "SELF > \(rhs)")
    }

    public convenience init(lessThan rhs: T) {
        self.init(format: "SELF < \(rhs)")
    }

    @inlinable public static func with(in rhs: ClosedRange<T>) -> Self {
        self.init(in: rhs)
    }

    @inlinable public static func with(in rhs: Range<T>) -> Self {
        self.init(in: rhs)
    }

    @inlinable public static func compare(largerThanOrEqualTo rhs: T) -> Self {
        self.init(largerThanOrEqualTo: rhs)
    }

    @inlinable public static func compare(lessThanOrEqualTo rhs: T) -> Self {
        self.init(lessThanOrEqualTo: rhs)
    }

    @inlinable public static func compare(largerThan rhs: T) -> Self {
        self.init(largerThan: rhs)
    }

    @inlinable public static func compare(lessThan rhs: T) -> Self {
        self.init(lessThan: rhs)
    }
}

extension KeyPath
where
    Root: Entity,
    Value == Root
{
    public static func == <T: EntityEquatable>(lhs: KeyPath, rhs: T) -> PropertyCondition<T> {
        PropertyCondition(equalTo: rhs)
    }

    public static func != <T: EntityEquatable>(lhs: KeyPath, rhs: T) -> PropertyCondition<T> {
        PropertyCondition(notEqualTo: rhs)
    }

    public static func <> <T: EntityEquatable>(lhs: KeyPath, rhs: [T]) -> PropertyCondition<T> {
        PropertyCondition(in: rhs)
    }

    public static func <> <T: EntityEquatable & Hashable>(lhs: KeyPath, rhs: Set<T>) -> PropertyCondition<T> {
        PropertyCondition(in: rhs)
    }
}

extension PropertyCondition where T == String {
    public convenience init(endsWith rhs: SearchString) {
        self.init(format: "SELF \(ENDSWITH(rhs)) %@", rhs.string)
    }

    public convenience init(beginsWith rhs: SearchString) {
        self.init(format: "SELF \(BEGINSWITH(rhs)) %@", rhs.string)
    }

    public convenience init(like rhs: SearchString) {
        self.init(format: "SELF \(LIKE(rhs)) %@", rhs.string)
    }

    public convenience init(matches rhs: SearchString) {
        self.init(format: "SELF \(MATCHES(rhs)) %@", rhs.string)
    }

    public convenience init(contains rhs: SearchString) {
        self.init(format: "SELF \(CONTAINS(rhs)) %@", rhs.string)
    }

    @inlinable public static func string(endsWith rhs: SearchString) -> Self {
        self.init(endsWith: rhs)
    }

    @inlinable public static func string(beginsWith rhs: SearchString) -> Self {
        self.init(beginsWith: rhs)
    }

    @inlinable public static func string(like rhs: SearchString) -> Self {
        self.init(like: rhs)
    }

    @inlinable public static func string(matches rhs: SearchString) -> Self {
        self.init(matches: rhs)
    }

    @inlinable public static func string(contains rhs: SearchString) -> Self {
        self.init(contains: rhs)
    }
}

extension PropertyCondition where T: PredicateExpressibleByString {
    public convenience init(endsWith rhs: SearchString) {
        self.init(format: "SELF.stringValue \(ENDSWITH(rhs)) %@", rhs.string)
    }

    public convenience init(beginsWith rhs: SearchString) {
        self.init(format: "SELF.stringValue \(BEGINSWITH(rhs)) %@", rhs.string)
    }

    public convenience init(like rhs: SearchString) {
        self.init(format: "SELF.stringValue \(LIKE(rhs)) %@", rhs.string)
    }

    public convenience init(matches rhs: SearchString) {
        self.init(format: "SELF.stringValue \(MATCHES(rhs)) %@", rhs.string)
    }

    public convenience init(contains rhs: SearchString) {
        self.init(format: "SELF.stringValue \(CONTAINS(rhs)) %@", rhs.string)
    }

    @inlinable public static func string(endsWith rhs: SearchString) -> Self {
        self.init(endsWith: rhs)
    }

    @inlinable public static func string(beginsWith rhs: SearchString) -> Self {
        self.init(beginsWith: rhs)
    }

    @inlinable public static func string(like rhs: SearchString) -> Self {
        self.init(like: rhs)
    }

    @inlinable public static func string(matches rhs: SearchString) -> Self {
        self.init(matches: rhs)
    }

    @inlinable public static func string(contains rhs: SearchString) -> Self {
        self.init(contains: rhs)
    }
}

extension PropertyCondition where T == String {
    public convenience init(lengthEqualTo length: Int) {
        self.init(format: "length == \(length)")
    }

    public convenience init(lengthLargerThanOrEqualTo length: Int) {
        self.init(format: "length >= \(length)")
    }

    public convenience init(lengthLessThanOrEqualTo length: Int) {
        self.init(format: "length <= \(length)")
    }

    public convenience init(lengthLargerThan length: Int) {
        self.init(format: "length > \(length)")
    }

    public convenience init(lengthLessThan length: Int) {
        self.init(format: "length < \(length)")
    }

    public convenience init(lengthBetween range: ClosedRange<Int>) {
        self.init(format: "length BETWEEN {\(range.lowerBound), \(range.upperBound)}")
    }

    public convenience init(lengthBetween range: Range<Int>) {
        self.init(format: "length >= \(range.lowerBound) AND length < \(range.upperBound)")
    }

    @inlinable public static func length(equalTo length: Int) -> Self {
        self.init(lengthEqualTo: length)
    }

    @inlinable public static func length(largerThanOrEqualTo length: Int) -> Self {
        self.init(lengthLargerThanOrEqualTo: length)
    }

    @inlinable public static func length(lessThanOrEqualTo length: Int) -> Self {
        self.init(lengthLessThanOrEqualTo: length)
    }

    @inlinable public static func length(largerThan length: Int) -> Self {
        self.init(lengthLargerThan: length)
    }

    @inlinable public static func length(lessThan length: Int) -> Self {
        self.init(lengthLessThan: length)
    }

    @inlinable public static func length(between range: ClosedRange<Int>) -> Self {
        self.init(lengthBetween: range)
    }

    @inlinable public static func length(between range: Range<Int>) -> Self {
        self.init(lengthBetween: range)
    }
}

extension PropertyCondition where T: PredicateExpressibleByString {
    public convenience init(lengthEqualTo length: Int) {
        self.init(format: "SELF.stringValue.length == \(length)")
    }

    public convenience init(lengthLargerThanOrEqualTo length: Int) {
        self.init(format: "SELF.stringValue.length >= \(length)")
    }

    public convenience init(lengthLessThanOrEqualTo length: Int) {
        self.init(format: "SELF.stringValue.length <= \(length)")
    }

    public convenience init(lengthLargerThan length: Int) {
        self.init(format: "SELF.stringValue.length > \(length)")
    }

    public convenience init(lengthLessThan length: Int) {
        self.init(format: "SELF.stringValue.length < \(length)")
    }

    public convenience init(lengthBetween range: ClosedRange<Int>) {
        self.init(format: "SELF.stringValue.length BETWEEN {\(range.lowerBound), \(range.upperBound)}")
    }

    public convenience init(lengthBetween range: Range<Int>) {
        self.init(format: "SELF.stringValue.length >= \(range.lowerBound) AND SELF.stringValue.length < \(range.upperBound)")
    }

    @inlinable public static func length(equalTo length: Int) -> Self {
        self.init(lengthEqualTo: length)
    }

    @inlinable public static func length(largerThanOrEqualTo length: Int) -> Self {
        self.init(lengthLargerThanOrEqualTo: length)
    }

    @inlinable public static func length(lessThanOrEqualTo length: Int) -> Self {
        self.init(lengthLessThanOrEqualTo: length)
    }

    @inlinable public static func length(largerThan length: Int) -> Self {
        self.init(lengthLargerThan: length)
    }

    @inlinable public static func length(lessThan length: Int) -> Self {
        self.init(lengthLessThan: length)
    }

    @inlinable public static func length(between range: ClosedRange<Int>) -> Self {
        self.init(lengthBetween: range)
    }

    @inlinable public static func length(between range: Range<Int>) -> Self {
        self.init(lengthBetween: range)
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
    Value: RelationshipProtocol,
    Value.Mapping == ToOne<Value.Destination>
{
    public static func == <T: EntityEquatable>(
        lhs: KeyPath, rhs: T) -> TypedPredicate<Root>
    {
        TypedPredicate<Root>(
            format: "\(lhs.propertyName) == %@", rhs.predicateValue)
    }

    public static func != <T: EntityEquatable>(
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
            format: "\(lhs.propertyName) >= %@ AND \(lhs.propertyName) < %@}",
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
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(BEGINSWITH(rhs)) %@", rhs.string)
    }

    public static func ~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(ENDSWITH(rhs)) %@", rhs.string)
    }

    public static func <> (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(CONTAINS(rhs)) %@", rhs.string)
    }

    public static func |~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(LIKE(rhs)) %@", rhs.string)
    }

    public static func |*| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName) \(MATCHES(rhs)) %@", rhs.string)
    }
}

extension KeyPath where
    Root: Entity,
    Value: AttributeProtocol,
    Value.PredicateValue: PredicateExpressibleByString
{
    public static func |~ (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(BEGINSWITH(rhs)) %@", rhs.string)
    }

    public static func ~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(ENDSWITH(rhs)) %@", rhs.string)
    }

    public static func <> (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(CONTAINS(rhs)) %@", rhs.string)
    }

    public static func |~| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(LIKE(rhs)) %@", rhs.string)
    }

    public static func |*| (lhs: KeyPath, rhs: SearchString) -> TypedPredicate<Root> {
        TypedPredicate<Root>(format: "\(lhs.propertyName).stringValue \(MATCHES(rhs)) %@", rhs.string)
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

