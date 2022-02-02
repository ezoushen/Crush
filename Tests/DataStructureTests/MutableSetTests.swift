//
//  MutableSetTests.swift
//  
//
//  Created by ezou on 2021/10/11.
//

import XCTest

@testable import Crush

class MutableSetTests: XCTestCase {
    func test_indexAfter_shouldReturnPlusOne() {
        let sut: MutableSet = [1]
        let result = sut.index(after: 0)
        XCTAssertEqual(result, 1)
    }

    func test_subsequence_shouldReturnElementsInRange() {
        let sut: MutableSet = [1, 2, 3, 4]
        let result = sut[0..<2]
        XCTAssertEqual(result.count, 2)
    }

    func test_init_shouldUseMutableSetDirectly() {
        let mutableSet = NSMutableSet(array: [1, 2])
        let sut = MutableSet<Int>(mutableSet).mutableSet
        XCTAssertIdentical(sut, mutableSet)
    }

    func test_init_shouldCopyMutableSet() {
        let mutableSet: MutableSet = [1, 2, 3, 4]
        let sut = MutableSet(mutableSet)
        XCTAssertNotIdentical(sut.mutableSet, mutableSet)
    }

    func test_init_arrayLiteral() {
        let sut = MutableSet(arrayLiteral: 1, 2, 3)
        XCTAssertEqual(sut, [1, 2, 3])
    }

    func test_init_copyNewSet() {
        let set: Set<Int> = [1, 2, 3]
        let sut = MutableSet(set)
        sut.insert(0)
        XCTAssertNotEqual(Set(sut), set)
    }

    func test_insert_success() {
        let sut: MutableSet = [1, 2, 3, 4]
        let result = sut.insert(0)
        XCTAssertTrue(result.inserted)
    }

    func test_insert_failed() {
        let sut: MutableSet = [1, 2, 3, 4]
        let result = sut.insert(3)
        XCTAssertFalse(result.inserted)
    }

    func test_remove_success() {
        let sut: MutableSet = [1, 2, 3, 4]
        let result = sut.remove(4)
        XCTAssertEqual(result, 4)
    }

    func test_remove_failed() {
        let sut: MutableSet = [1, 2, 3, 4]
        let result = sut.remove(0)
        XCTAssertNil(result)
    }

    func test_union_shouldAddNewElements() {
        let sut: MutableSet = [1, 2, 3, 4]
        let result = sut.union([5])
        XCTAssertEqual(result, [1, 2, 3, 4, 5])
    }

    func test_formUnion_shouldAddNewElements() {
        let sut: MutableSet = [1, 2, 3, 4]
        sut.formUnion([5])
        XCTAssertEqual(sut, [1, 2, 3, 4, 5])
    }

    func test_intersection_shouldReturnCommonElements() {
        let sut: MutableSet = [1, 2, 3, 4]
        let result = sut.intersection([3])
        XCTAssertEqual(result, [3])
    }

    func test_formIntersection_shouldReturnCommonElements() {
        let sut: MutableSet = [1, 2, 3, 4]
        sut.formIntersection([3])
        XCTAssertEqual(sut, [3])
    }

    func test_symmetricDifference_shouldReturnUnionWithoutIntersection() {
        let sut: MutableSet = [1, 2, 3, 4]
        let result = sut.symmetricDifference([3, 4, 5])
        XCTAssertEqual(result, [1, 2, 5])
    }

    func test_formSymmetricDifference_shouldReturnUnionWithoutIntersection() {
        let sut: MutableSet = [1, 2, 3, 4]
        sut.formSymmetricDifference([3, 4, 5])
        XCTAssertEqual(sut, [1, 2, 5])
    }

    func test_subtract_shouldMinusElements() {
        let sut: MutableSet = [1, 2, 3, 4]
        sut.subtract([3, 4])
        XCTAssertEqual(sut, [1, 2])
    }

    func test_subtracting_shouldMinusElements() {
        let sut: MutableSet = [1, 2, 3, 4]
        let result = sut.subtracting([3, 4])
        XCTAssertEqual(result, [1, 2])
    }

    func test_update_shouldReturnNil() {
        let sut: MutableSet = [1, 2, 3, 4]
        let result = sut.update(with: 5)
        XCTAssertNil(result)
    }

    func test_update_shouldReturnElement() {
        let sut: MutableSet = [1, 2, 3, 4, 5]
        let result = sut.update(with: 5)
        XCTAssertEqual(result, 5)
    }
}
