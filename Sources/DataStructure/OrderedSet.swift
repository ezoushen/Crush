//
//  OrderedSet.swift
//  
//
//  Created by ezou on 2021/10/9.
//

import Foundation

public struct OrderedSet<T: Hashable>:
    SetAlgebra,
    RandomAccessCollection,
    RangeReplaceableCollection,
    ExpressibleByArrayLiteral,
    Hashable,
    CustomStringConvertible
{
    public subscript(position: Int) -> T {
        return orderedSet[position] as! T
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        (orderedSet.array as! [T])[bounds]
    }
    
    public var startIndex: Int {
        0
    }
    
    public var endIndex: Int {
        orderedSet.count
    }
    
    public var description: String {
        orderedSet.array.description
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(orderedSet)
    }
    
    public mutating func replaceSubrange<C>(
        _ subrange: Range<Int>,
        with newElements: C)
    where
    C : Collection,
    T == C.Element
    {
        let mutableSet = NSMutableOrderedSet(orderedSet: orderedSet)
        if subrange.startIndex == subrange.endIndex {
            // insert
            if subrange.startIndex > endIndex {
                mutableSet.addObjects(from: Array(newElements))
            } else  {
                let range = subrange.startIndex..<subrange.startIndex+newElements.count
                mutableSet.insert(Array(newElements), at: IndexSet(range))
            }
        } else if let _ = newElements as? EmptyCollection<T> {
            mutableSet.removeObjects(at: IndexSet(subrange))
        } else {
            precondition(
                startIndex <= subrange.startIndex &&
                endIndex >= subrange.endIndex)
            mutableSet.replaceObjects(
                at: IndexSet(integersIn: subrange),
                with: Array(newElements))
        }

        self = Self.init(mutableSet)
    }
    
    public typealias ArrayLiteralElement = T
    
    public typealias Element = T
    
    public typealias Index = Int
    
    public typealias SubSequence = ArraySlice<T>
    
    public typealias Indices = Range<Int>
    
    internal let orderedSet: NSOrderedSet
    
    internal init(_ orderedSet: NSOrderedSet) {
        self.orderedSet = orderedSet
    }
    
    public init(arrayLiteral elements: T...) {
        self.init(NSOrderedSet(array: elements))
    }
    
    public init<S: Sequence>(_ sequence: S) where S.Element == T {
        self.init(NSOrderedSet(array: Array(sequence)))
    }
    
    public init() {
        self.init(NSOrderedSet())
    }

    public init(_ mutableOrderedSet: MutableOrderedSet<T>) {
        self.init(mutableOrderedSet.orderedSet.copy() as! NSOrderedSet)
    }

    public init(_ orderedSet: OrderedSet<T>) {
        self.init(orderedSet.orderedSet)
    }
}

extension OrderedSet {
    @inline(__always)
    private func mutableCopy() -> NSMutableOrderedSet {
        orderedSet.mutableCopy() as! NSMutableOrderedSet
    }

    public var isEmpty: Bool {
        count == 0
    }

    public mutating func remove(_ member: T) -> T? {
        let orderedSet = mutableCopy()
        if orderedSet.contains(member) {
            orderedSet.remove(member)
            self = Self(orderedSet)
            return member
        }
        return nil
    }

    @discardableResult
    public mutating func insert(_ newMember: __owned T) -> (inserted: Bool, memberAfterInsert: T) {
        let orderedSet = mutableCopy()
        if orderedSet.contains(newMember) {
            return (
                inserted: false,
                memberAfterInsert: orderedSet.object(at: orderedSet.index(of: newMember)) as! T)
        } else {
            orderedSet.add(newMember)
            self = Self(orderedSet)
            return (
                inserted: true,
                memberAfterInsert: newMember)
        }
    }

    public __consuming func union(_ other: __owned OrderedSet<T>) -> OrderedSet<T> {
        let mutableSet = mutableCopy()
        mutableSet.union(other.orderedSet)
        return OrderedSet(mutableSet)
    }

    public __consuming func intersection(_ other: OrderedSet<T>) -> OrderedSet<T> {
        let mutableSet = mutableCopy()
        mutableSet.intersect(other.orderedSet)
        return OrderedSet(mutableSet)
    }

    public __consuming func symmetricDifference(_ other: __owned OrderedSet<T>) -> OrderedSet<T> {
        let mutableSet = mutableCopy()
        let mutableOtherSet = other.mutableCopy()
        let result = mutableCopy()
        result.union(other.orderedSet)
        mutableSet.minus(other.orderedSet)
        mutableOtherSet.intersect(orderedSet)
        result.minus(mutableOtherSet)
        return OrderedSet(result)
    }

    public mutating func subtract(_ other: OrderedSet<T>) {
        self = subtracting(other)
    }

    public func subtracting(_ other: OrderedSet<T>) -> OrderedSet<T> {
        let mutableSet = mutableCopy()
        mutableSet.minus(other.orderedSet)
        return OrderedSet(mutableSet)
    }

    public mutating func update(with newMember: __owned T) -> T? {
        guard orderedSet.contains(newMember) else {
            return nil
        }
        let mutableSet = mutableCopy()
        mutableSet.add(newMember)
        self = OrderedSet(mutableSet)
        return newMember
    }

    public mutating func formUnion(_ other: __owned OrderedSet<T>) {
        self = union(other)
    }

    public mutating func formIntersection(_ other: OrderedSet<T>) {
        self = intersection(other)
    }

    public mutating func formSymmetricDifference(_ other: __owned OrderedSet<T>) {
        self = symmetricDifference(other)
    }
}

extension OrderedSet: Decodable where T: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode([T].self)
        self.init(array)
    }
}

extension OrderedSet: Encodable where T: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(orderedSet.array as! [T])
    }
}
