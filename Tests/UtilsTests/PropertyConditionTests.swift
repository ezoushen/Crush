//
//  PropertyConditionTests.swift
//  
//
//  Created by ezou on 2022/2/5.
//

import XCTest

@testable import Crush

class PropertyConditionTests: XCTestCase {
    func test_inRange_shouldReturnTrue() {
        let sut = PropertyCondition(in: 1...3)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_inRange_shouldReturnFalse() {
        let sut = PropertyCondition(in: 1...3)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 5)))
    }

    func test_inArray_shouldReturnTrue() {
        let sut = PropertyCondition(in: Array([1, 2, 3]))
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_inArray_shouldReturnFalse() {
        let sut = PropertyCondition(in: Array([1, 2, 3]))
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 4)))
    }

    func test_inSet_shouldReturnTrue() {
        let sut = PropertyCondition(in: Set([1, 2, 3]))
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_inSet_shouldReturnFalse() {
        let sut = PropertyCondition(in: Set([1, 2, 3]))
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 5)))
    }

    func test_largerThanOrEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(largerThanOrEqualTo: 1)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 1)))
    }

    func test_largerThanOrEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(largerThanOrEqualTo: 1)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 0)))
    }

    func test_smallerThanOrEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(smallerThanOrEqualTo: 1)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 1)))
    }

    func test_smallerThanOrEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(smallerThanOrEqualTo: 1)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_largerThan_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(largerThan: 1)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_largerThan_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(largerThan: 1)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 0)))
    }

    func test_smallerThan_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(smallerThan: 1)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 0)))
    }

    func test_smallerThan_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(smallerThan: 1)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_beginsWith_shouldReturnTrue() {
        let sut = PropertyCondition<String>(beginsWith: "a")
        XCTAssertTrue(sut.evaluate(with: "abc"))
    }

    func test_beginsWith_shouldReturnFalse() {
        let sut = PropertyCondition<String>(beginsWith: "a")
        XCTAssertFalse(sut.evaluate(with: "bc"))
    }

    func test_endsWith_shouldReturnTrue() {
        let sut = PropertyCondition<String>(endsWith: "c")
        XCTAssertTrue(sut.evaluate(with: "abc"))
    }

    func test_endsWith_shouldReturnFalse() {
        let sut = PropertyCondition<String>(endsWith: "c")
        XCTAssertFalse(sut.evaluate(with: "ab"))
    }

    func test_like_shouldReturnTrue() {
        let sut = PropertyCondition<String>(like: "c*")
        XCTAssertTrue(sut.evaluate(with: "cba"))
    }

    func test_like_shouldReturnFalse() {
        let sut = PropertyCondition<String>(like: "c*")
        XCTAssertFalse(sut.evaluate(with: "ab"))
    }

    func test_match_shouldReturnTrue() {
        let sut = PropertyCondition<String>(matches: "^cba$")
        XCTAssertTrue(sut.evaluate(with: "cba"))
    }

    func test_match_shouldReturnFalse() {
        let sut = PropertyCondition<String>(matches: "^cba$")
        XCTAssertFalse(sut.evaluate(with: "dcba"))
    }

    func test_contains_shouldReturnTrue() {
        let sut = PropertyCondition<String>(contains: "a")
        XCTAssertTrue(sut.evaluate(with: "cba"))
    }

    func test_contains_shouldReturnFalse() {
        let sut = PropertyCondition<String>(contains: "d")
        XCTAssertFalse(sut.evaluate(with: "cba"))
    }

    func test_beginsWithStringValue_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(beginsWith: "1")
        XCTAssertTrue(sut.evaluate(with: 123))
    }

    func test_beginsWithStringValue_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(beginsWith: "1")
        XCTAssertFalse(sut.evaluate(with: 23))
    }

    func test_endsWithStringValue_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(endsWith: "1")
        XCTAssertTrue(sut.evaluate(with: 321))
    }

    func test_endsWithStringValue_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(endsWith: "1")
        XCTAssertFalse(sut.evaluate(with: 32))
    }

    func test_likeStringValue_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(like: "1*")
        XCTAssertTrue(sut.evaluate(with: 123))
    }

    func test_likeStringValue_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(like: "1*")
        XCTAssertFalse(sut.evaluate(with: 23))
    }

    func test_matchStringValue_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(matches: "^123$")
        XCTAssertTrue(sut.evaluate(with: 123))
    }

    func test_matchStringValue_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(matches: "^123$")
        XCTAssertFalse(sut.evaluate(with: 312))
    }

    func test_containsStringValue_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(contains: "1")
        XCTAssertTrue(sut.evaluate(with: 312))
    }

    func test_containsStringValue_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(contains: "1")
        XCTAssertFalse(sut.evaluate(with: 333))
    }
}
