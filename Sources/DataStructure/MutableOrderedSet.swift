//
//  MutableOrderedSet.swift
//  
//
//  Created by ezou on 2021/10/10.
//

import Foundation

public final class MutableOrderedSet<T: Hashable>:
    RandomAccessCollection,
    RangeReplaceableCollection,
    ExpressibleByArrayLiteral,
    Hashable,
    SetAlgebra,
    CustomStringConvertible
{
    public func makeIterator() -> FastEnumerationIterator<T> {
        FastEnumerationIterator(orderedSet.makeIterator())
    }

    public static func == (lhs: MutableOrderedSet<T>, rhs: MutableOrderedSet<T>) -> Bool {
        lhs.orderedSet == rhs.orderedSet
    }

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

    public func replaceSubrange<C>(
        _ subrange: Range<Int>,
        with newElements: C)
    where
        C : Collection,
        T == C.Element
    {
        let mutableSet = orderedSet
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
    }

    public typealias ArrayLiteralElement = T

    public typealias Element = T

    public typealias Index = Int

    public typealias SubSequence = ArraySlice<T>

    public typealias Indices = Range<Int>

    internal var orderedSet: NSMutableOrderedSet

    public required init(_ orderedSet: NSMutableOrderedSet) {
        self.orderedSet = orderedSet
    }

    public required init(arrayLiteral elements: T...) {
        self.orderedSet = NSMutableOrderedSet(array: elements)
    }

    public required init<S: Sequence>(_ sequence: S) where S.Element == T {
        self.orderedSet = NSMutableOrderedSet(array: Array(sequence))
    }

    public required init() {
        self.orderedSet = NSMutableOrderedSet()
    }

    public required init(_ orderedSet: OrderedSet<T>) {
        self.orderedSet = orderedSet.orderedSet.mutableCopy() as! NSMutableOrderedSet
    }

    public required init(_ mutableOrderedSet: MutableOrderedSet<T>) {
        self.orderedSet = mutableOrderedSet.orderedSet.mutableCopy() as! NSMutableOrderedSet
    }
}

extension MutableOrderedSet {
    @inlinable
    public var isEmpty: Bool {
        count == 0
    }

    @inlinable
    public func append(_ newElement: __owned Element) {
        insert(newElement, at: endIndex)
    }

    @inlinable
    public func append<S: Sequence>(contentsOf newElements: __owned S)
    where S.Element == Element {

        let approximateCapacity = self.count + newElements.underestimatedCount
        self.reserveCapacity(approximateCapacity)
        for element in newElements {
            append(element)
        }
    }

    @inlinable
    public func insert(
        _ newElement: __owned Element, at i: Index
    ) {
        replaceSubrange(i..<i, with: CollectionOfOne(newElement))
    }

    @inlinable
    public func insert<C: Collection>(
        contentsOf newElements: __owned C, at i: Index
    ) where C.Element == Element {
        replaceSubrange(i..<i, with: newElements)
    }

    @inlinable
    @discardableResult
    public func remove(at position: Index) -> Element {
        precondition(!isEmpty, "Can't remove from an empty collection")
        let result: Element = self[position]
        replaceSubrange(position..<index(after: position), with: EmptyCollection())
        return result
    }

    @inlinable
    public func removeSubrange(_ bounds: Range<Index>) {
        replaceSubrange(bounds, with: EmptyCollection())
    }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        if !keepCapacity {
            orderedSet.removeAllObjects()
        }
        else {
            replaceSubrange(startIndex..<endIndex, with: EmptyCollection())
        }
    }

    @inlinable
    public func reserveCapacity(_ n: Int) { }

    @discardableResult
    public func removeFirst() -> Element {
        precondition(!isEmpty, "Can't remove items from an empty collection")
        let element = orderedSet.object(at: 0)
        orderedSet.removeObject(at: 0)
        return element as! Element
    }

    public func removeFirst(_ k: Int) {
        if k == 0 { return }
        precondition(k >= 0, "Number of elements to remove should be non-negative")
        guard let idx = index(startIndex, offsetBy: k, limitedBy: endIndex) else {
            preconditionFailure(
                "Can't remove more items from a collection than it contains")
        }
        orderedSet.removeObjects(at: IndexSet(integersIn: startIndex..<idx))
    }

    public func replaceSubrange<C: Collection, R: RangeExpression>(
        _ subrange: R,
        with newElements: __owned C
    ) where C.Element == Element, R.Bound == Index {
        self.replaceSubrange(subrange.relative(to: self), with: newElements)
    }

    @inlinable
    public func removeSubrange<R: RangeExpression>(
        _ bounds: R
    ) where R.Bound == Index {
        removeSubrange(bounds.relative(to: self))
    }

    @inlinable
    public func popLast() -> Element? {
        if isEmpty { return nil }
        return remove(at: index(before: endIndex))
    }

    @inlinable
    @discardableResult
    public func removeLast() -> Element {
        precondition(!isEmpty, "Can't remove last element from an empty collection")
        return remove(at: index(before: endIndex))
    }

    @inlinable
    public func removeLast(_ k: Int) {
        if k == 0 { return }
        precondition(k >= 0, "Number of elements to remove should be non-negative")
        let end = endIndex
        guard let start = index(end, offsetBy: -k, limitedBy: startIndex)
        else {
            preconditionFailure(
                "Can't remove more items from a collection than it contains")
        }

        removeSubrange(start..<end)
    }

    public func removeAll(
        where shouldBeRemoved: (Element) throws -> Bool
    ) rethrows {
        let indices = try orderedSet.enumerated().compactMap { (index, object) -> Int? in
            return try shouldBeRemoved(object as! Element) ? index : nil
        }
        orderedSet.removeObjects(at: IndexSet(indices))
    }
}

extension MutableOrderedSet {
    private func copy() -> Self {
        Self.init(orderedSet.mutableCopy() as! NSMutableOrderedSet)
    }

    public func remove(_ member: T) -> T? {
        if orderedSet.contains(member) {
            orderedSet.remove(member)
            return member
        }
        return nil
    }

    @discardableResult
    public func insert(_ newMember: __owned T) -> (inserted: Bool, memberAfterInsert: T) {
        if orderedSet.contains(newMember) {
            return (
                inserted: false,
                memberAfterInsert: orderedSet.object(at: orderedSet.index(of: newMember)) as! T)
        } else {
            orderedSet.add(newMember)
            return (
                inserted: true,
                memberAfterInsert: newMember)
        }
    }

    public __consuming func union(_ other: __owned MutableOrderedSet<T>) -> Self {
        let newSet = copy()
        newSet.formUnion(other)
        return newSet
    }

    public __consuming func intersection(_ other: MutableOrderedSet<T>) -> Self {
        let newSet = copy()
        newSet.formIntersection(other)
        return newSet
    }

    public __consuming func symmetricDifference(_ other: __owned MutableOrderedSet<T>) -> Self {
        let newSet = copy()
        newSet.formSymmetricDifference(other)
        return newSet
    }

    public func update(with newMember: __owned T) -> T? {
        let index = orderedSet.index(of: newMember)
        if index != NSNotFound {
            orderedSet.replaceObject(at: index, with: newMember)
            return newMember
        }
        return nil
    }

    public func subtracting(_ other: MutableOrderedSet<T>) -> Self {
        let newSet = copy()
        newSet.subtract(other)
        return newSet
    }

    public func subtract(_ other: MutableOrderedSet<T>) {
        orderedSet.minus(other.orderedSet)
    }

    public func formUnion(_ other: __owned MutableOrderedSet<T>) {
        orderedSet.union(other.orderedSet)
    }

    public func formIntersection(_ other: MutableOrderedSet<T>) {
        orderedSet.intersect(other.orderedSet)
    }

    public func formSymmetricDifference(_ other: __owned MutableOrderedSet<T>) {
        let otherSet = other.orderedSet.mutableCopy() as! NSMutableOrderedSet
        otherSet.minus(orderedSet)
        orderedSet.minus(other.orderedSet)
        orderedSet.union(otherSet)
    }
}

extension MutableOrderedSet: Decodable where T: Decodable {
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode([T].self)
        self.init(array)
    }
}

extension MutableOrderedSet: Encodable where T: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(orderedSet.array as! [T])
    }
}
