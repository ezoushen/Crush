//
//  OrderedSetTests.swift
//  
//
//  Created by ezou on 2021/10/10.
//

import XCTest

@testable import Crush

class OrderedSetTests: XCTestCase {
    func test_removeAll_shouldBeEmpty() {
        var sut: OrderedSet = [1, 2, 3, 4, 5]
        sut.removeAll()
        XCTAssertTrue(sut.isEmpty)
    }

    func test_removeAllWhere_shouldReserveOdds() {
        var sut: OrderedSet = [1, 2, 3, 4, 5]
        sut.removeAll { $0 % 2 == 0 }
        XCTAssertEqual(sut, [1, 3, 5])
    }

    func test_append_shouldAddNewElement() {
        var sut: OrderedSet = [1, 2, 3, 4, 5]
        sut.append(6)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5, 6])
    }

    func test_appendSequence_shouldAddNewElments() {
        var sut: OrderedSet = [1, 2, 3, 4, 5]
        sut.append(contentsOf: [6, 7, 8])
        XCTAssertEqual(sut, [1, 2, 3, 4, 5, 6, 7, 8])
    }

    func test_insert_shouldInsertAtSpecificPosition() {
        var sut: OrderedSet = [1, 2, 4, 5]
        sut.insert(3, at: 2)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_insertSequence_shouldInsertNewElements() {
        var sut: OrderedSet = [1, 5]
        sut.insert(contentsOf: [2, 3, 4], at: 1)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_remove_shouldRemoveElementAtSpecificIndex() {
        var sut: OrderedSet = [1, 2, 3, 6, 4 ,5]
        sut.remove(at: 3)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_removeSubrange_shouldRemoveElements() {
        var sut: OrderedSet = [1, 2, 3, 6, 7, 4 ,5]
        sut.removeSubrange(3..<5)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_removeFirst_shouldDropFirst() {
        var sut: OrderedSet = [6, 1, 2, 3, 4 ,5]
        sut.removeFirst()
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_revmoveFirst2_shouldDropFirst2() {
        var sut: OrderedSet = [6, 7, 1, 2, 3, 4 ,5]
        sut.removeFirst(2)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_popLast_shouldRemoveLast() {
        var sut: OrderedSet = [1, 2, 3, 4 ,5, 6]
        _ = sut.popLast()
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_removeLast_shouldRemoveLast() {
        var sut: OrderedSet = [1, 2, 3, 4 ,5, 6]
        _ = sut.removeLast()
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_removeLast2_shouldRemoveLast2() {
        var sut: OrderedSet = [1, 2, 3, 4 ,5, 6, 7]
        sut.removeLast(2)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_isEmpty_equalsTrue() {
        let sut: OrderedSet<Int> = []
        XCTAssertTrue(sut.isEmpty)
    }

    func test_isEmpty_equalsFalse() {
        let sut: OrderedSet<Int> = [1, 2, 3]
        XCTAssertFalse(sut.isEmpty)
    }

    func test_remove_shouldRemoveSpecificElement() {
        var sut: OrderedSet = [1, 2, 3, 6, 4 ,5]
        _ = sut.remove(6)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_remove_shouldDoNothing() {
        var sut: OrderedSet = [1, 2, 3, 4 ,5]
        let result = sut.remove(6)
        XCTAssertNil(result)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_insert_alreadyExists() {
        var sut: OrderedSet = [1, 2, 3, 4 ,5]
        let result = sut.insert(3)
        XCTAssertFalse(result.inserted)
        XCTAssertEqual(result.memberAfterInsert, 3)
    }

    func test_insert_success() {
        var sut: OrderedSet = [1, 2, 3, 4]
        let result = sut.insert(5)
        XCTAssertTrue(result.inserted)
        XCTAssertEqual(result.memberAfterInsert, 5)
    }

    func test_union_shouldAddTwoSets() {
        let sut: OrderedSet = [1, 2, 3]
        let result = sut.union([3, 4, 5])
        XCTAssertEqual(result, [1, 2, 3, 4, 5])
    }

    func test_formUnion_shouldAddTwoSets() {
        var sut: OrderedSet = [1, 2, 3]
        sut.formUnion([3, 4, 5])
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_intersection_shouldIntersectTwoSets() {
        let sut: OrderedSet = [1, 2, 3]
        let result = sut.intersection([3, 4, 5])
        XCTAssertEqual(result, [3])
    }

    func test_formIntersection_shouldIntersectTwoSets() {
        var sut: OrderedSet = [1, 2, 3]
        sut.formIntersection([3, 4, 5])
        XCTAssertEqual(sut, [3])
    }

    func test_symmetricDifference_shouldGet1245() {
        let sut: OrderedSet = [1, 2, 3]
        let result = sut.symmetricDifference([3, 4, 5])
        XCTAssertEqual(result, [1, 2, 4, 5])
    }

    func test_formSymmetricDifference_shouldGet1245() {
        var sut: OrderedSet = [1, 2, 3]
        sut.formSymmetricDifference([3, 4, 5])
        XCTAssertEqual(sut, [1, 2, 4, 5])
    }

    func test_update_shouldGetNil() {
        var sut: OrderedSet = [1, 2, 3]
        let result = sut.update(with: 4)
        XCTAssertNil(result)
    }

    func test_update_shouldGetReturnValue() {
        var sut: OrderedSet = [1, 2, 3, 4]
        let result = sut.update(with: 4)
        XCTAssertEqual(result, 4)
    }

    func test_subtracting_shouldGetDifference() {
        let sut: OrderedSet = [1, 2, 3]
        let result = sut.subtracting([3])
        XCTAssertEqual(result, [1, 2])
    }

    func test_subtract_shouldGetDifferenceInplace() {
        var sut: OrderedSet = [1, 2, 3]
        sut.subtract([3])
        XCTAssertEqual(sut, [1, 2])
    }

    func test_equalibility_shouldEffectByOrder() {
        let sut: OrderedSet = [1, 2, 3]
        let target: OrderedSet = [2, 3, 1]
        XCTAssertNotEqual(sut, target)
    }

    func test_equalibility_shouldBeEqual() {
        let sut: OrderedSet = [1, 2, 3]
        let target: OrderedSet = [1, 2, 3]
        XCTAssertEqual(sut, target)
    }

    func test_immutability_shouldBeIdentical() {
        let sut: OrderedSet = [1, 2, 3]
        let copy = sut
        XCTAssertIdentical(sut.orderedSet, copy.orderedSet)
    }

    func test_immutability_shouldDoCopyOnWrite() {
        let sut: OrderedSet = [1, 2, 3]
        var copy = sut
        _ = copy.remove(1)
        XCTAssertNotEqual(sut.orderedSet, copy.orderedSet)
    }

    func test_encodable_shouldReturnArrayString() {
        let sut: OrderedSet = [1, 2, 3]
        let data = try! JSONEncoder().encode(sut)
        let string = String(data: data, encoding: .utf8)
        XCTAssertEqual(string, "[1,2,3]")
    }

    func test_decodable_shouldReturnSet() {
        let sut = try! JSONDecoder().decode(
            OrderedSet<Int>.self,
            from: "[1,2,3]".data(using: .utf8)!)
        let target: OrderedSet = [1, 2, 3]
        XCTAssertEqual(sut, target)
    }

    func test_subsequence_shouldReturElementsInRange() {
        let sut: OrderedSet = [1, 2, 3, 4]
        let result = sut[0..<2]
        XCTAssertEqual(result, [1, 2])
    }
}
