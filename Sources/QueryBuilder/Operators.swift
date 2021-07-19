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

public func BETWEEN<T: PredicateComparable>(_ rhs: ClosedRange<T>) -> NSPredicate {
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

// MARK: - Operator overloading for Entity

extension KeyPath where Root: Entity, Value: ValuedProperty {
    public var propertyName: String {
        Root.init()[keyPath: self].name
    }
}

extension KeyPath where Root: Entity, Value: ValuedProperty, Value.PredicateValue: PredicateEquatable & Equatable & Hashable {
    public static func <> (lhs: KeyPath, rhs: Set<Value.PredicateValue>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) IN %@", NSSet(set: rhs))
    }
}

extension KeyPath where Root: Entity, Value: ValuedProperty, Value.PredicateValue: PredicateEquatable & Equatable {
    public static func <> (lhs: KeyPath, rhs: Array<Value.PredicateValue>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) IN %@", NSArray(array: rhs))
    }
}

extension KeyPath where
    Root: Entity,
    Value: ValuedProperty,
    Value.PredicateValue: PredicateEquatable & Equatable,
    Value.Nullability == NotNull
{
    public static func == (lhs: KeyPath, rhs: Value.PredicateValue) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) == %@", rhs.predicateValue)
    }

    public static func != (lhs: KeyPath, rhs: Value.PredicateValue) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) != %@", rhs.predicateValue)
    }
}

extension KeyPath where
    Root: Entity,
    Value: ValuedProperty,
    Value.PredicateValue: PredicateEquatable & Equatable,
    Value.Nullability == Nullable
{
    public static func == (lhs: KeyPath, rhs: Value.PredicateValue?) -> NSPredicate {
        guard let value = rhs?.predicateValue else {
            return NSPredicate(format: "\(lhs.propertyName) == NULL")
        }
        return NSPredicate(format: "\(lhs.propertyName) == %@", value)
    }

    public static func != (lhs: KeyPath, rhs: Value.PredicateValue?) -> NSPredicate {
        guard let value = rhs?.predicateValue else {
            return NSPredicate(format: "\(lhs.propertyName) != NULL")
        }
        return NSPredicate(format: "\(lhs.propertyName) != %@", value)
    }
}

extension KeyPath where Root: Entity, Value: ValuedProperty, Value.PredicateValue: PredicateComparable & Comparable {
    public static func > (lhs: KeyPath, rhs: Value.PredicateValue) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) > %@", rhs.predicateValue)
    }

    public static func < (lhs: KeyPath, rhs: Value.PredicateValue) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) < %@", rhs.predicateValue)
    }

    public static func >= (lhs: KeyPath, rhs: Value.PredicateValue) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) >= %@", rhs.predicateValue)
    }

    public static func <= (lhs: KeyPath, rhs: Value.PredicateValue) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) <= %@", rhs.predicateValue)
    }

    public static func <> (lhs: KeyPath, rhs: ClosedRange<Value.PredicateValue>) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) BETWEEN {%@, %@}", rhs.lowerBound.predicateValue, rhs.upperBound.predicateValue)
    }
}

extension KeyPath where Root: Entity, Value: ValuedProperty, Value.PredicateValue == String {
    public static func |~ (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) BEGINSWITH\(rhs.type.modifier) %@", rhs.string)
    }

    public static func ~| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) ENDSWITH\(rhs.type.modifier) %@", rhs.string)
    }

    public static func <> (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) CONTAINS\(rhs.type.modifier) %@", rhs.string)
    }

    public static func |~| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) LIKE\(rhs.type.modifier) %@", rhs.string)
    }

    public static func |*| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName) MATCHES\(rhs.type.modifier) %@", rhs.string)
    }
}

extension KeyPath where Root: Entity, Value: ValuedProperty {
    public static func |~ (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName).stringValue BEGINSWITH\(rhs.type.modifier) %@", rhs.string)
    }

    public static func ~| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName).stringValue ENDSWITH\(rhs.type.modifier) %@", rhs.string)
    }

    public static func <> (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName).stringValue CONTAINS\(rhs.type.modifier) %@", rhs.string)
    }

    public static func |~| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName).stringValue LIKE\(rhs.type.modifier) %@", rhs.string)
    }

    public static func |*| (lhs: KeyPath, rhs: SearchString) -> NSPredicate {
        return NSPredicate(format: "\(lhs.propertyName).stringValue MATCHES\(rhs.type.modifier) %@", rhs.string)
    }
}
