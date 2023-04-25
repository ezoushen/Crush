//
//  PropertyConditionTests.swift
//  
//
//  Created by ezou on 2022/2/5.
//

import XCTest

@testable import Crush

class PropertyConditionTests: XCTestCase {
    func test_equalTo_shouldReturnTrue() {
        let sut = PropertyCondition.compare(equalTo: 2)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_equalTo_shouldReturnFalse() {
        let sut = PropertyCondition.compare(equalTo: 3)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_notEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition.compare(notEqualTo: 3)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_notEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition.compare(notEqualTo: 2)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_inRange_shouldReturnTrue() {
        let sut = PropertyCondition.compare(between: 1..<3)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_inRange_shouldReturnFalse() {
        let sut = PropertyCondition.compare(between: 1..<3)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 3)))
    }

    func test_inClosedRange_shouldReturnTrue() {
        let sut = PropertyCondition.compare(between: 1...3)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_inClosedRange_shouldReturnFalse() {
        let sut = PropertyCondition.compare(between: 1...3)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 5)))
    }

    func test_inArray_shouldReturnTrue() {
        let sut = PropertyCondition.compare(in: Array([1, 2, 3]))
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_inArray_shouldReturnFalse() {
        let sut = PropertyCondition.compare(in: Array([1, 2, 3]))
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 4)))
    }

    func test_inSet_shouldReturnTrue() {
        let sut = PropertyCondition.compare(in: Set([1, 2, 3]))
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_inSet_shouldReturnFalse() {
        let sut = PropertyCondition.compare(in: Set([1, 2, 3]))
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 5)))
    }

    func test_greaterThanOrEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.compare(greaterThanOrEqualTo: 1)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 1)))
    }

    func test_greaterThanOrEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.compare(greaterThanOrEqualTo: 1)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 0)))
    }

    func test_lessThanOrEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.compare(lessThanOrEqualTo: 1)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 1)))
    }

    func test_lessThanOrEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.compare(lessThanOrEqualTo: 1)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_greaterThan_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.compare(greaterThan: 1)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_greaterThan_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.compare(greaterThan: 1)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 0)))
    }

    func test_lessThan_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.compare(lessThan: 1)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 0)))
    }

    func test_lessThan_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.compare(lessThan: 1)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_beginsWith_shouldReturnTrue() {
        let sut = PropertyCondition<String>.string(beginsWith: "a")
        XCTAssertTrue(sut.evaluate(with: "abc"))
    }

    func test_beginsWith_shouldReturnFalse() {
        let sut = PropertyCondition<String>.string(beginsWith: "a")
        XCTAssertFalse(sut.evaluate(with: "bc"))
    }

    func test_endsWith_shouldReturnTrue() {
        let sut = PropertyCondition<String>.string(endsWith: "c")
        XCTAssertTrue(sut.evaluate(with: "abc"))
    }

    func test_endsWith_shouldReturnFalse() {
        let sut = PropertyCondition<String>.string(endsWith: "c")
        XCTAssertFalse(sut.evaluate(with: "ab"))
    }

    func test_like_shouldReturnTrue() {
        let sut = PropertyCondition<String>.string(like: "c*")
        XCTAssertTrue(sut.evaluate(with: "cba"))
    }

    func test_like_shouldReturnFalse() {
        let sut = PropertyCondition<String>.string(like: "c*")
        XCTAssertFalse(sut.evaluate(with: "ab"))
    }

    func test_match_shouldReturnTrue() {
        let sut = PropertyCondition<String>.string(matches: "^cba$")
        XCTAssertTrue(sut.evaluate(with: "cba"))
    }

    func test_match_shouldReturnFalse() {
        let sut = PropertyCondition<String>.string(matches: "^cba$")
        XCTAssertFalse(sut.evaluate(with: "dcba"))
    }

    func test_contains_shouldReturnTrue() {
        let sut = PropertyCondition<String>.string(contains: "a")
        XCTAssertTrue(sut.evaluate(with: "cba"))
    }

    func test_contains_shouldReturnFalse() {
        let sut = PropertyCondition<String>.string(contains: "d")
        XCTAssertFalse(sut.evaluate(with: "cba"))
    }

    func test_beginsWithStringValue_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.string(beginsWith: "1")
        XCTAssertTrue(sut.evaluate(with: 123))
    }

    func test_beginsWithStringValue_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.string(beginsWith: "1")
        XCTAssertFalse(sut.evaluate(with: 23))
    }

    func test_endsWithStringValue_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.string(endsWith: "1")
        XCTAssertTrue(sut.evaluate(with: 321))
    }

    func test_endsWithStringValue_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.string(endsWith: "1")
        XCTAssertFalse(sut.evaluate(with: 32))
    }

    func test_likeStringValue_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.string(like: "1*")
        XCTAssertTrue(sut.evaluate(with: 123))
    }

    func test_likeStringValue_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.string(like: "1*")
        XCTAssertFalse(sut.evaluate(with: 23))
    }

    func test_matchStringValue_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.string(matches: "^123$")
        XCTAssertTrue(sut.evaluate(with: 123))
    }

    func test_matchStringValue_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.string(matches: "^123$")
        XCTAssertFalse(sut.evaluate(with: 312))
    }

    func test_containsStringValue_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.string(contains: "1")
        XCTAssertTrue(sut.evaluate(with: 312))
    }

    func test_containsStringValue_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.string(contains: "1")
        XCTAssertFalse(sut.evaluate(with: 333))
    }

    func test_lengthEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<String>.length(equalTo: 5)
        XCTAssertTrue(sut.evaluate(with: "12345"))
    }

    func test_lengthEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<String>.length(equalTo: 5)
        XCTAssertFalse(sut.evaluate(with: "123"))
    }

    func test_lengthLargerThan_shouldReturnTrue() {
        let sut = PropertyCondition<String>.length(greaterThan: 5)
        XCTAssertTrue(sut.evaluate(with: "123456"))
    }

    func test_lengthLargerThan_shouldReturnFalse() {
        let sut = PropertyCondition<String>.length(greaterThan: 5)
        XCTAssertFalse(sut.evaluate(with: "1234"))
    }

    func test_lengthLargerThanOrEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<String>.length(greaterThanOrEqualTo: 5)
        XCTAssertTrue(sut.evaluate(with: "123456"))
    }

    func test_lengthLargerThanOrEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<String>.length(greaterThanOrEqualTo: 5)
        XCTAssertFalse(sut.evaluate(with: "1234"))
    }

    func test_lengthLessThan_shouldReturnTrue() {
        let sut = PropertyCondition<String>.length(lessThan: 5)
        XCTAssertTrue(sut.evaluate(with: "1234"))
    }

    func test_lengthLessThan_shouldReturnFalse() {
        let sut = PropertyCondition<String>.length(lessThan: 5)
        XCTAssertFalse(sut.evaluate(with: "123456"))
    }

    func test_lengthLessThanOrEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<String>.length(lessThanOrEqualTo: 5)
        XCTAssertTrue(sut.evaluate(with: "12345"))
    }

    func test_lengthLessThanOrEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<String>.length(lessThanOrEqualTo: 5)
        XCTAssertFalse(sut.evaluate(with: "123456"))
    }

    func test_lengthBetweenRange_shouldReturnTrue() {
        let sut = PropertyCondition<String>.length(between: 3..<5)
        XCTAssertTrue(sut.evaluate(with: "1234"))
    }

    func test_lengthBetweenRange_shouldReturnFalse() {
        let sut = PropertyCondition<String>.length(between: 3..<5)
        XCTAssertFalse(sut.evaluate(with: "12345"))
    }

    func test_lengthBetweenClosedRange_shouldReturnTrue() {
        let sut = PropertyCondition<String>.length(between: 3...5)
        XCTAssertTrue(sut.evaluate(with: "1234"))
    }

    func test_lengthBetweenClosedRange_shouldReturnFalse() {
        let sut = PropertyCondition<String>.length(between: 3...5)
        XCTAssertFalse(sut.evaluate(with: "123456"))
    }

    func test_lengthEqualTo_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.length(equalTo: 5)
        XCTAssertTrue(sut.evaluate(with: 12345))
    }

    func test_lengthEqualTo_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.length(equalTo: 5)
        XCTAssertFalse(sut.evaluate(with: 123))
    }

    func test_lengthLargerThan_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.length(greaterThan: 5)
        XCTAssertTrue(sut.evaluate(with: 123456))
    }

    func test_lengthLargerThan_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.length(greaterThan: 5)
        XCTAssertFalse(sut.evaluate(with: 1234))
    }

    func test_lengthLargerThanOrEqualTo_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.length(greaterThanOrEqualTo: 5)
        XCTAssertTrue(sut.evaluate(with: 123456))
    }

    func test_lengthLargerThanOrEqualTo_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.length(greaterThanOrEqualTo: 5)
        XCTAssertFalse(sut.evaluate(with: 1234))
    }

    func test_lengthLessThan_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.length(lessThan: 5)
        XCTAssertTrue(sut.evaluate(with: 1234))
    }

    func test_lengthLessThan_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.length(lessThan: 5)
        XCTAssertFalse(sut.evaluate(with: 123456))
    }

    func test_lengthLessThanOrEqualTo_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.length(lessThanOrEqualTo: 5)
        XCTAssertTrue(sut.evaluate(with: 12345))
    }

    func test_lengthLessThanOrEqualTo_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.length(lessThanOrEqualTo: 5)
        XCTAssertFalse(sut.evaluate(with: 123456))
    }

    func test_lengthBetweenRange_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.length(between: 3..<5)
        XCTAssertTrue(sut.evaluate(with: 1234))
    }

    func test_lengthBetweenRange_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.length(between: 3..<5)
        XCTAssertFalse(sut.evaluate(with: 12345))
    }

    func test_lengthBetweenClosedRange_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>.length(between: 3...5)
        XCTAssertTrue(sut.evaluate(with: 12345))
    }

    func test_lengthBetweenClosedRange_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>.length(between: 3...5)
        XCTAssertFalse(sut.evaluate(with: 123456))
    }
}

class PropertyCondiationOperatorsTests: XCTestCase {
    class TestEntity: Entity {
        @Optional
        var integerValue = Value.Int64("integerValue")
    }

    let storage = Storage.sqliteInMemory()
    var container: DataContainer!

    override func setUpWithError() throws {
        container = try DataContainer.load(
            storages: storage,
            dataModel: DataModel(
                name: "DATAMODEL",
                concrete: [TestEntity()]))
    }

    override func tearDownWithError() throws {
        try container.destroyStorages()
    }

    private func createObject() throws -> TestEntity.ReadOnly {
        try container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            try context.commit()
            return entity
        }
    }

    func test_equalToOperator_shouldReturnEqualToPropertyCondition() throws {
        let object = try createObject()
        let sut = \TestEntity.self == object
        XCTAssertEqual(sut, PropertyCondition.compare(equalTo: object))
    }

    func test_notEqualToOperator_shouldReturnNotEqualToPropertyCondition() throws {
        let object = try createObject()
        let sut = \TestEntity.self != object
        XCTAssertEqual(sut, PropertyCondition.compare(notEqualTo: object))
    }

    func test_inOperator_shouldReturnInArrayPropertyCondition() throws {
        let object = try createObject()
        let array: [TestEntity.ReadOnly] = [object]
        let sut = \TestEntity.self <> array
        XCTAssertEqual(sut, PropertyCondition.compare(in: array))
    }

    func test_inOperator_shouldReturnInSetPropertyCondition() throws {
        let object = try createObject()
        let set: Set<TestEntity.ReadOnly> = [object]
        let sut = \TestEntity.self <> `set`
        XCTAssertEqual(sut, PropertyCondition.compare(in: `set`))
    }
}
