//
//  Operators.swift
//  Crush
//
//  Created by ezou on 2020/3/12.
//

import CoreData

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

// MARK: - Validation

public func BETWEEN<T: PredicateComparable>(_ rhs: Range<T>) -> NSPredicate {
    return NSPredicate(format: "SELF BETWEEN {%@, %@}", rhs.lowerBound.predicateValue, rhs.upperBound.predicateValue)
}

public func BETWEEN<T: PredicateEquatable>(_ rhs: Array<T>) -> NSPredicate {
    return NSPredicate(format: "SELF IN %@", NSArray(array: rhs))
}

public func BETWEEN<T: PredicateEquatable>(_ rhs: Set<T>) -> NSPredicate {
    return NSPredicate(format: "SELF IN %@", NSSet(set: rhs))
}

public func LARGER_THAN_OR_EQUALS_TO(_ rhs: PredicateComparable) -> NSPredicate {
    return NSPredicate(format: "SELF >= \(rhs)")
}

public func SMALLER_THAN_OR_EQUALS_TO(_ rhs: PredicateComparable) -> NSPredicate {
    return NSPredicate(format: "SELF <= \(rhs)")
}

public func LARGER_THAN(_ rhs: PredicateComparable) -> NSPredicate {
    return NSPredicate(format: "SELF > \(rhs)")
}

public func SMALLER_THAN(_ rhs: PredicateComparable) -> NSPredicate {
    return NSPredicate(format: "SELF < \(rhs)")
}

public func ENDSWITH(_ rhs: SearchString) -> NSPredicate {
    return NSPredicate(format: "SELF ENDSWITH\(rhs.type.modifier) %@", rhs.string)
}

public func BEGINSWITH(_ rhs: SearchString) -> NSPredicate {
    return NSPredicate(format: "SELF BEGINSWITH\(rhs.type.modifier) %@", rhs.string)
}

public func LIKE(_ rhs: SearchString) -> NSPredicate {
    return NSPredicate(format: "SELF LIKE\(rhs.type.modifier) %@", rhs.string)
}

public func MATCHES(_ rhs: SearchString) -> NSPredicate {
    return NSPredicate(format: "SELF MATCHES\(rhs.type.modifier) %@", rhs.string)
}

public func CONTAINS(_ rhs: SearchString) -> NSPredicate {
    return NSPredicate(format: "SELF CONTAINS\(rhs.type.modifier) %@", rhs.string)
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

extension KeyPath where Root: NeutralEntityObject, Value: NullableProperty, Value.PredicateValue: PredicateEquatable & Equatable & Hashable {
    public static func <> (lhs: KeyPath, rhs: Set<Value.PredicateValue>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath where Root: NeutralEntityObject, Value: NullableProperty, Value.PredicateValue: PredicateEquatable & Equatable {
    public static func <> (lhs: KeyPath, rhs: Array<Value.PredicateValue>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.fullPath) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where Root: NSManagedObject, Value: PredicateEquatable & Equatable {
    public static func == (lhs: KeyPath, rhs: Value?) -> NSPredicate {
        guard let value = rhs?.predicateValue else {
            return NSPredicate(format: "\(lhs.stringValue) == NULL")
        }
        return NSPredicate(format: "\(lhs.stringValue) == %@", value)
    }
    
    public static func != (lhs: KeyPath, rhs: Value?) -> NSPredicate {
        guard let value = rhs?.predicateValue else {
            return NSPredicate(format: "\(lhs.stringValue) != NULL")
        }
        return NSPredicate(format: "\(lhs.stringValue) != %@", value)
    }
    
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
        guard let value = rhs?.predicateValue else {
            return NSPredicate(format: "\(lhs.stringValue) == NULL")
        }
        return NSPredicate(format: "\(lhs.stringValue) == %@", value)
    }

    public static func != <E: PredicateEquatable & Equatable>(lhs: KeyPath, rhs: Value) -> NSPredicate where Value == Swift.Optional<E> {
        guard let value = rhs?.predicateValue else {
            return NSPredicate(format: "\(lhs.stringValue) != NULL")
        }
        return NSPredicate(format: "\(lhs.stringValue) != %@", value)
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
        return NSPredicate(format: "\(lhs.stringValue) BETWEEN {%@, %@}", rhs.lowerBound.predicateValue, rhs.upperBound.predicateValue)
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
        return NSPredicate(format: "\(lhs.stringValue) BETWEEN {%@, %@}", rhs.lowerBound.predicateValue, rhs.upperBound.predicateValue)
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
