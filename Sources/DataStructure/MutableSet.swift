//
//  MutableSet.swift
//  
//
//  Created by ezou on 2021/10/10.
//

import Foundation

public final class MutableSet<T: Hashable>:
    Collection,
    ExpressibleByArrayLiteral,
    Hashable,
    CustomStringConvertible
{
    public func index(after i: Int) -> Int {
        i + 1
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        (mutableSet.allObjects as! [T])[bounds]
    }

    public subscript(position: Int) -> T {
        return mutableSet.allObjects[position] as! T
    }

    public var startIndex: Int {
        0
    }

    public var endIndex: Int {
        mutableSet.count
    }

    public var indices: Range<Int> {
        0..<endIndex
    }

    public static func == (lhs: MutableSet<T>, rhs: MutableSet<T>) -> Bool {
        lhs.mutableSet == rhs.mutableSet
    }

    public var description: String {
        mutableSet.allObjects.description
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mutableSet)
    }

    public typealias ArrayLiteralElement = T

    public typealias Element = T

    public typealias Index = Int

    public typealias SubSequence = ArraySlice<T>

    public typealias Indices = Range<Int>

    internal var mutableSet: NSMutableSet

    internal init(_ mutableSet: NSMutableSet) {
        self.mutableSet = mutableSet
    }

    public init(_ mutableSet: MutableSet<T>) {
        self.mutableSet = mutableSet.copy()
    }

    public required init(arrayLiteral elements: T...) {
        self.mutableSet = NSMutableSet(array: elements)
    }

    public required init<S: Sequence>(_ sequence: S) where S.Element == T {
        self.mutableSet = NSMutableSet(array: Array(sequence))
    }

    public required init() {
        self.mutableSet = NSMutableSet()
    }

    public required init(_ set: Set<T>) {
        self.mutableSet = (set as NSSet).mutableCopy() as! NSMutableSet
    }
}

extension Set {
    init(_ mutableSet: MutableSet<Element>) {
        self.init(mutableSet.mutableSet.allObjects as! [Element])
    }
}

extension MutableSet: SetAlgebra {
    public var isEmpty: Bool {
        endIndex == 0
    }

    @inline(__always)
    private func copy() -> NSMutableSet {
        mutableSet.mutableCopy() as! NSMutableSet
    }

    @discardableResult
    public func insert(_ newMember: __owned T) -> (inserted: Bool, memberAfterInsert: T) {
        if mutableSet.contains(newMember) {
            return (
                inserted: false,
                memberAfterInsert: (mutableSet.allObjects as! [T])
                    .first { $0.hashValue == newMember.hashValue }!)
        } else {
            mutableSet.add(newMember)
            return (
                inserted: true,
                memberAfterInsert: newMember)
        }
    }

    public func remove(_ member: T) -> T? {
        if mutableSet.contains(member) {
            mutableSet.remove(member)
            return member
        }
        return nil
    }

    public __consuming func union(_ other: __owned MutableSet<T>) -> Self {
        let newSet = Self(self as MutableSet)
        newSet.formUnion(other)
        return newSet
    }

    public __consuming func intersection(_ other: MutableSet<T>) -> Self {
        let newSet = Self(self as MutableSet)
        newSet.formIntersection(other)
        return newSet
    }

    public __consuming func symmetricDifference(_ other: __owned MutableSet<T>) -> Self {
        let newSet = Self(self as MutableSet)
        newSet.formSymmetricDifference(other)
        return newSet
    }

    public func subtract(_ other: __owned MutableSet<T>) {
        mutableSet.minus(other.mutableSet.toSet())
    }

    public func subtracting(_ other: MutableSet<T>) -> Self {
        let newSet = Self(self as MutableSet)
        newSet.subtract(other)
        return newSet
    }

    public func update(with newMember: __owned T) -> T? {
        if mutableSet.contains(newMember) {
            mutableSet.add(newMember)
            return newMember
        }
        return nil
    }

    public func formUnion(_ other: __owned MutableSet<T>) {
        mutableSet.union(other.mutableSet.toSet())
    }

    public func formIntersection(_ other: MutableSet<T>) {
        mutableSet.intersect(other.mutableSet.toSet())
    }

    public func formSymmetricDifference(_ other: __owned MutableSet<T>) {
        let tempSet = copy()
        tempSet.intersect(other.mutableSet.toSet())
        mutableSet.union(other.mutableSet.toSet())
        mutableSet.minus(tempSet.toSet())
    }


}

private extension NSSet {
    @inline(__always)
    func toSet() -> Set<AnyHashable> {
        Set(_immutableCocoaSet: copy() as! NSSet)
    }
}
