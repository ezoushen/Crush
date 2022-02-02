//
//  MutableOrderedSetTests.swift
//  
//
//  Created by ezou on 2021/10/10.
//

import XCTest

@testable import Crush

class MutableOrderedSetTests: XCTestCase {
    func test_removeAll_shouldBeEmpty() {
        let sut: MutableOrderedSet = [1, 2, 3, 4, 5]
        sut.removeAll()
        XCTAssertTrue(sut.isEmpty)
    }

    func test_removeAllWhere_shouldReserveOdds() {
        let sut: MutableOrderedSet = [1, 2, 3, 4, 5]
        sut.removeAll { $0 % 2 == 0 }
        XCTAssertEqual(sut, [1, 3, 5])
    }

    func test_append_shouldAddNewElement() {
        let sut: MutableOrderedSet = [1, 2, 3, 4, 5]
        sut.append(6)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5, 6])
    }

    func test_appendSequence_shouldAddNewElments() {
        let sut: MutableOrderedSet = [1, 2, 3, 4, 5]
        sut.append(contentsOf: [6, 7, 8])
        XCTAssertEqual(sut, [1, 2, 3, 4, 5, 6, 7, 8])
    }

    func test_insert_shouldInsertAtSpecificPosition() {
        let sut: MutableOrderedSet = [1, 2, 4, 5]
        sut.insert(3, at: 2)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_insertSequence_shouldInsertNewElements() {
        let sut: MutableOrderedSet = [1, 5]
        sut.insert(contentsOf: [2, 3, 4], at: 1)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_remove_shouldRemoveElementAtSpecificIndex() {
        let sut: MutableOrderedSet = [1, 2, 3, 6, 4 ,5]
        sut.remove(at: 3)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_removeSubrange_shouldRemoveElements() {
        let sut: MutableOrderedSet = [1, 2, 3, 6, 7, 4 ,5]
        sut.removeSubrange(3..<5)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_removeFirst_shouldDropFirst() {
        let sut: MutableOrderedSet = [6, 1, 2, 3, 4 ,5]
        sut.removeFirst()
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_revmoveFirst2_shouldDropFirst2() {
        let sut: MutableOrderedSet = [6, 7, 1, 2, 3, 4 ,5]
        sut.removeFirst(2)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_popLast_shouldRemoveLast() {
        let sut: MutableOrderedSet = [1, 2, 3, 4 ,5, 6]
        _ = sut.popLast()
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_removeLast_shouldRemoveLast() {
        let sut: MutableOrderedSet = [1, 2, 3, 4 ,5, 6]
        _ = sut.removeLast()
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_removeLast2_shouldRemoveLast2() {
        let sut: MutableOrderedSet = [1, 2, 3, 4 ,5, 6, 7]
        sut.removeLast(2)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_isEmpty_equalsTrue() {
        let sut: MutableOrderedSet<Int> = []
        XCTAssertTrue(sut.isEmpty)
    }

    func test_isEmpty_equalsFalse() {
        let sut: MutableOrderedSet<Int> = [1, 2, 3]
        XCTAssertFalse(sut.isEmpty)
    }

    func test_remove_shouldRemoveSpecificElement() {
        let sut: MutableOrderedSet = [1, 2, 3, 6, 4 ,5]
        _ = sut.remove(6)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_remove_shouldDoNothing() {
        let sut: MutableOrderedSet = [1, 2, 3, 4 ,5]
        let result = sut.remove(6)
        XCTAssertNil(result)
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_insert_alreadyExists() {
        let sut: MutableOrderedSet = [1, 2, 3, 4 ,5]
        let result = sut.insert(3)
        XCTAssertFalse(result.inserted)
        XCTAssertEqual(result.memberAfterInsert, 3)
    }

    func test_insert_success() {
        let sut: MutableOrderedSet = [1, 2, 3, 4]
        let result = sut.insert(5)
        XCTAssertTrue(result.inserted)
        XCTAssertEqual(result.memberAfterInsert, 5)
    }

    func test_union_shouldAddTwoSets() {
        let sut: MutableOrderedSet = [1, 2, 3]
        let result = sut.union([3, 4, 5])
        XCTAssertEqual(result, [1, 2, 3, 4, 5])
    }

    func test_formUnion_shouldAddTwoSets() {
        let sut: MutableOrderedSet = [1, 2, 3]
        sut.formUnion([3, 4, 5])
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_intersection_shouldIntersectTwoSets() {
        let sut: MutableOrderedSet = [1, 2, 3]
        let result = sut.intersection([3, 4, 5])
        XCTAssertEqual(result, [3])
    }

    func test_formIntersection_shouldIntersectTwoSets() {
        let sut: MutableOrderedSet = [1, 2, 3]
        sut.formIntersection([3, 4, 5])
        XCTAssertEqual(sut, [3])
    }

    func test_symmetricDifference_shouldGet1245() {
        let sut: MutableOrderedSet = [1, 2, 3]
        let result = sut.symmetricDifference([3, 4, 5])
        XCTAssertEqual(result, [1, 2, 4, 5])
    }

    func test_formSymmetricDifference_shouldGet1245() {
        let sut: MutableOrderedSet = [1, 2, 3]
        sut.formSymmetricDifference([3, 4, 5])
        XCTAssertEqual(sut, [1, 2, 4, 5])
    }

    func test_update_shouldGetNil() {
        let sut: MutableOrderedSet = [1, 2, 3]
        let result = sut.update(with: 4)
        XCTAssertNil(result)
    }

    func test_update_shouldGetReturnValue() {
        let sut: MutableOrderedSet = [1, 2, 3, 4]
        let result = sut.update(with: 4)
        XCTAssertEqual(result, 4)
    }

    func test_subtracting_shouldGetDifference() {
        let sut: MutableOrderedSet = [1, 2, 3]
        let result = sut.subtracting([3])
        XCTAssertEqual(result, [1, 2])
    }

    func test_subtract_shouldGetDifferenceInplace() {
        let sut: MutableOrderedSet = [1, 2, 3]
        sut.subtract([3])
        XCTAssertEqual(sut, [1, 2])
    }

    func test_equalibility_shouldEffectByOrder() {
        let sut: MutableOrderedSet = [1, 2, 3]
        let target: MutableOrderedSet = [2, 3, 1]
        XCTAssertNotEqual(sut, target)
    }

    func test_equalibility_shouldBeEqual() {
        let sut: MutableOrderedSet = [1, 2, 3]
        let target: MutableOrderedSet = [1, 2, 3]
        XCTAssertEqual(sut, target)
    }

    func test_encodable_shouldReturnArrayString() {
        let sut: MutableOrderedSet = [1, 2, 3]
        let data = try! JSONEncoder().encode(sut)
        let string = String(data: data, encoding: .utf8)
        XCTAssertEqual(string, "[1,2,3]")
    }

    func test_decodable_shouldReturnSet() {
        let sut = try! JSONDecoder().decode(MutableOrderedSet<Int>.self, from: "[1,2,3]".data(using: .utf8)!)
        let target: MutableOrderedSet = [1, 2, 3]
        XCTAssertEqual(sut, target)
    }

    func test_init_shouldBeEmpty() {
        let sut = MutableOrderedSet<Int>()
        XCTAssertEqual(sut, [])
    }

    func test_initByMutableOrderedSet_shouldHaveSameContent() {
        let set: MutableOrderedSet = [1, 2, 3]
        let sut = MutableOrderedSet(set)
        XCTAssertEqual(sut, set)
    }

    func test_initByOrderedSet_shouldHaveSameContent() {
        let set: OrderedSet = [1, 2, 3]
        let sut = MutableOrderedSet(set)
        XCTAssertEqual(sut, [1, 2, 3])
    }

    func test_subsequence_shouldReturElementsInRange() {
        let sut: MutableOrderedSet = [1, 2, 3, 4]
        let result = sut[0..<2]
        XCTAssertEqual(result, [1, 2])
    }
}
