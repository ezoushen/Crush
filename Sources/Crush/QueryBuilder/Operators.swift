//
//  Operators.swift
//  Crush
//
//  Created by ezou on 2020/3/12.
//

import CoreData

public typealias Query<T: Entity> = QueryBuilder<T, NSManagedObject, T>

extension NSPredicate {
    public static prefix func ! (_ predicate: NSPredicate) -> NSPredicate {
        NSCompoundPredicate(notPredicateWithSubpredicate: predicate)
    }

    public static func && (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [lhs, rhs])
    }

    public static func || (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: [lhs, rhs])
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

// MARK: - Operator Overloading for `RuntimeObject`

extension TracableKeyPathProtocol where Root: Entity, Value: NullablePropertyProtocol, Value.EntityType: PredicateEquatable & Equatable {
    public static func == (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) == %@", rhs.predicateValue)
    }
    
    public static func != (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) != %@", rhs.predicateValue)
    }
}

extension TracableKeyPathProtocol where Root: Entity, Value: NullablePropertyProtocol, Value.EntityType: PredicateComparable & Comparable {
    public static func > (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) > %@", rhs.predicateValue)
    }
    
    public static func < (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) < %@", rhs.predicateValue)
    }
    
    public static func >= (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) >= %@", rhs.predicateValue)
    }
    
    public static func <= (lhs: Self, rhs: Value.EntityType) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) <= %@", rhs.predicateValue)
    }
    
    public static func <> (lhs: Self, rhs: Range<Value.EntityType>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) BETWEEN '{\(rhs.lowerBound.predicateValue), \(rhs.upperBound.predicateValue)}'")
    }
}

extension TracableKeyPathProtocol where Root: Entity, Value: NullablePropertyProtocol, Value.EntityType == String {
    public static func |~ (lhs: Self, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) BEGINSWITH\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func ~| (lhs: Self, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) ENDSWITH\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func <> (lhs: Self, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) CONTAINS\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func |~| (lhs: Self, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) LIKE\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func |*| (lhs: Self, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) MATCHES\(rhs.type.modifier) %@", rhs.string)
    }
}

extension TracableKeyPathProtocol where Root: Entity, Value: NullablePropertyProtocol {
    public static func |~ (lhs: Self, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath).stringValue BEGINSWITH\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func ~| (lhs: Self, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath).stringValue ENDSWITH\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func <> (lhs: Self, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath).stringValue CONTAINS\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func |~| (lhs: Self, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath).stringValue LIKE\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func |*| (lhs: Self, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath).stringValue MATCHES\(rhs.type.modifier) %@", rhs.string)
    }
}

extension KeyPath where Root: NeutralEntityObject, Value: NullablePropertyProtocol, Value.EntityType: PredicateEquatable & Equatable & Hashable {
    public static func <> (lhs: KeyPath, rhs: Set<Value.EntityType>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath where Root: NeutralEntityObject, Value: NullablePropertyProtocol, Value.EntityType: PredicateEquatable & Equatable {
    public static func <> (lhs: KeyPath, rhs: Array<Value.EntityType>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSArray(array: rhs))
    }
}

extension TracableKeyPathProtocol where Root: NeutralEntityObject, Value: NullablePropertyProtocol, Value.EntityType: PredicateEquatable & Equatable & Hashable {
    public static func <> (lhs: Self, rhs: Set<Value.EntityType>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSSet(set: rhs))
    }
}

extension TracableKeyPathProtocol where Root: NeutralEntityObject, Value: NullablePropertyProtocol, Value.EntityType: PredicateEquatable & Equatable {
    public static func <> (lhs: Self, rhs: Array<Value.EntityType>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where Root: NSManagedObject, Value: PredicateEquatable & Equatable {
    public static func == (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) == %@", rhs.predicateValue)
    }
    
    public static func != (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) != %@", rhs.predicateValue)
    }
}

// MARK: - Operator Overloading for `NSManagedObject`

extension KeyPath where Root: NSManagedObject {
    public static func == <E: PredicateEquatable & Equatable>(lhs: KeyPath, rhs: Value) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.stringValue) == %@", rhs?.predicateValue ?? "NULL")
    }
    
    public static func != <E: PredicateEquatable & Equatable>(lhs: KeyPath, rhs: Value) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.stringValue) != %@", rhs?.predicateValue ?? "NULL")
    }
    
    public static func == <E: NSManagedObject>(lhs: KeyPath, rhs: Value) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.stringValue) == NULL")
    }
    
    public static func != <E: NSManagedObject>(lhs: KeyPath, rhs: Value) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.stringValue) != NULL")
    }
}

extension KeyPath where Root: NSManagedObject, Value: PredicateEquatable & Equatable & Hashable {
    public static func <> (lhs: KeyPath, rhs: Set<Value>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath where Root: NSManagedObject, Value: PredicateEquatable & Equatable {
    public static func <> (lhs: KeyPath, rhs: Array<Value>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where Root: NSManagedObject, Value: PredicateComparable & Comparable {
    public static func > (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) > %@", rhs.predicateValue)
    }
    
    public static func < (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) < %@", rhs.predicateValue)
    }
    
    public static func >= (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) >= %@", rhs.predicateValue)
    }
    
    public static func <= (lhs: KeyPath, rhs: Value) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) <= %@", rhs.predicateValue)
    }
    
    public static func <> (lhs: KeyPath, rhs: Range<Value>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) BETWEEN '{\(rhs.lowerBound.predicateValue), \(rhs.upperBound.predicateValue)}'")
    }
}

extension KeyPath where Root: NSManagedObject, Value == String {
    public static func |~ (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) BEGINSWITH\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func ~| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) ENDSWITH\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func <> (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) CONTAINS\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func |~| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) LIKE\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func |*| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) MATCHES\(rhs.type.modifier) %@", rhs.string)
    }
}

extension KeyPath where Root: NSManagedObject {
    public static func <> <E: PredicateEquatable & Equatable & Hashable>(lhs: KeyPath, rhs: Set<E>) -> NSPredicate where Value == Swift.Optional<E>{
        return NSPredicate(format: "\(lhs.stringValue) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath where Root: NSManagedObject {
    public static func <> <E: PredicateEquatable & Equatable>(lhs: KeyPath, rhs: Array<E>) -> NSPredicate where Value == Swift.Optional<E>{
        return NSPredicate(format: "\(lhs.stringValue) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where Root: NSManagedObject {
    public static func > <E: PredicateComparable & Comparable>(lhs: KeyPath, rhs: E) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.stringValue) > %@", rhs.predicateValue)
    }
    
    public static func < <E: PredicateComparable & Comparable>(lhs: KeyPath, rhs: E) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.stringValue) < %@", rhs.predicateValue)
    }
    
    public static func >= <E: PredicateComparable & Comparable>(lhs: KeyPath, rhs: E) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.stringValue) >= %@", rhs.predicateValue)
    }
    
    public static func <= <E: PredicateComparable & Comparable>(lhs: KeyPath, rhs: E) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.stringValue) <= %@", rhs.predicateValue)
    }
    
    public static func <> <E: PredicateComparable & Comparable>(lhs: KeyPath, rhs: Range<E>) -> NSPredicate where Value == Swift.Optional<E> {
        return NSPredicate(format: "\(lhs.stringValue) BETWEEN '{\(rhs.lowerBound.predicateValue), \(rhs.upperBound.predicateValue)}'")
    }
}

extension KeyPath where Root: NSManagedObject, Value == Swift.Optional<String> {
    public static func |~ (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) BEGINSWITH\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func ~| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) ENDSWITH\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func <> (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) CONTAINS\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func |~| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) LIKE\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func |*| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue) MATCHES\(rhs.type.modifier) %@", rhs.string)
    }
}

extension KeyPath where Root: NSManagedObject {
    public static func |~ (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue).stringValue BEGINSWITH\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func ~| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue).stringValue ENDSWITH\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func <> (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue).stringValue CONTAINS\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func |~| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue).stringValue LIKE\(rhs.type.modifier) %@", rhs.string)
    }
    
    public static func |*| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.stringValue).stringValue MATCHES\(rhs.type.modifier) %@", rhs.string)
    }
}
