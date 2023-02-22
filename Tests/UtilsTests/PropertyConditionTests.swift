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
        let sut = PropertyCondition(equalTo: 2)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_equalTo_shouldReturnFalse() {
        let sut = PropertyCondition(equalTo: 3)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_notEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition(notEqualTo: 3)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 2)))
    }

    func test_notEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition(notEqualTo: 2)
        XCTAssertFalse(sut.evaluate(with: NSNumber(value: 2)))
    }

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

    func test_LessThanOrEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(lessThanOrEqualTo: 1)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 1)))
    }

    func test_LessThanOrEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(lessThanOrEqualTo: 1)
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

    func test_LessThan_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(lessThan: 1)
        XCTAssertTrue(sut.evaluate(with: NSNumber(value: 0)))
    }

    func test_LessThan_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(lessThan: 1)
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

    func test_lengthEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<String>(lengthEqualTo: 5)
        XCTAssertTrue(sut.evaluate(with: "12345"))
    }

    func test_lengthEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<String>(lengthEqualTo: 5)
        XCTAssertFalse(sut.evaluate(with: "123"))
    }

    func test_lengthLargerThan_shouldReturnTrue() {
        let sut = PropertyCondition<String>(lengthLargerThan: 5)
        XCTAssertTrue(sut.evaluate(with: "123456"))
    }

    func test_lengthLargerThan_shouldReturnFalse() {
        let sut = PropertyCondition<String>(lengthLargerThan: 5)
        XCTAssertFalse(sut.evaluate(with: "1234"))
    }

    func test_lengthLargerThanOrEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<String>(lengthLargerThanOrEqualTo: 5)
        XCTAssertTrue(sut.evaluate(with: "123456"))
    }

    func test_lengthLargerThanOrEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<String>(lengthLargerThanOrEqualTo: 5)
        XCTAssertFalse(sut.evaluate(with: "1234"))
    }

    func test_lengthLessThan_shouldReturnTrue() {
        let sut = PropertyCondition<String>(lengthLessThan: 5)
        XCTAssertTrue(sut.evaluate(with: "1234"))
    }

    func test_lengthLessThan_shouldReturnFalse() {
        let sut = PropertyCondition<String>(lengthLessThan: 5)
        XCTAssertFalse(sut.evaluate(with: "123456"))
    }

    func test_lengthLessThanOrEqualTo_shouldReturnTrue() {
        let sut = PropertyCondition<String>(lengthLessThanOrEqualTo: 5)
        XCTAssertTrue(sut.evaluate(with: "12345"))
    }

    func test_lengthLessThanOrEqualTo_shouldReturnFalse() {
        let sut = PropertyCondition<String>(lengthLessThanOrEqualTo: 5)
        XCTAssertFalse(sut.evaluate(with: "123456"))
    }

    func test_lengthBetweenRange_shouldReturnTrue() {
        let sut = PropertyCondition<String>(lengthBetween: 3..<5)
        XCTAssertTrue(sut.evaluate(with: "1234"))
    }

    func test_lengthBetweenRange_shouldReturnFalse() {
        let sut = PropertyCondition<String>(lengthBetween: 3..<5)
        XCTAssertFalse(sut.evaluate(with: "12345"))
    }

    func test_lengthEqualTo_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(lengthEqualTo: 5)
        XCTAssertTrue(sut.evaluate(with: 12345))
    }

    func test_lengthEqualTo_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(lengthEqualTo: 5)
        XCTAssertFalse(sut.evaluate(with: 123))
    }

    func test_lengthLargerThan_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(lengthLargerThan: 5)
        XCTAssertTrue(sut.evaluate(with: 123456))
    }

    func test_lengthLargerThan_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(lengthLargerThan: 5)
        XCTAssertFalse(sut.evaluate(with: 1234))
    }

    func test_lengthLargerThanOrEqualTo_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(lengthLargerThanOrEqualTo: 5)
        XCTAssertTrue(sut.evaluate(with: 123456))
    }

    func test_lengthLargerThanOrEqualTo_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(lengthLargerThanOrEqualTo: 5)
        XCTAssertFalse(sut.evaluate(with: 1234))
    }

    func test_lengthLessThan_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(lengthLessThan: 5)
        XCTAssertTrue(sut.evaluate(with: 1234))
    }

    func test_lengthLessThan_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(lengthLessThan: 5)
        XCTAssertFalse(sut.evaluate(with: 123456))
    }

    func test_lengthLessThanOrEqualTo_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(lengthLessThanOrEqualTo: 5)
        XCTAssertTrue(sut.evaluate(with: 12345))
    }

    func test_lengthLessThanOrEqualTo_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(lengthLessThanOrEqualTo: 5)
        XCTAssertFalse(sut.evaluate(with: 123456))
    }

    func test_lengthBetweenRange_stringExpressible_shouldReturnTrue() {
        let sut = PropertyCondition<Int16>(lengthBetween: 3..<5)
        XCTAssertTrue(sut.evaluate(with: 1234))
    }

    func test_lengthBetweenRange_stringExpressible_shouldReturnFalse() {
        let sut = PropertyCondition<Int16>(lengthBetween: 3..<5)
        XCTAssertFalse(sut.evaluate(with: 12345))
    }
}

class PropertyCondiationOperatorsTests: XCTestCase {
    class TestEntity: Entity {
        @Optional
        var integerValue = Value.Int("integerValue")
    }

    let storage = Storage.sqliteInMemory()
    var container: DataContainer!

    override func setUp() async throws {
        container = try DataContainer.load(
            storages: storage,
            dataModel: DataModel(
                name: "DATAMODEL",
                concrete: [TestEntity()]))
    }

    override func tearDown() async throws {
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
        XCTAssertEqual(sut, PropertyCondition(equalTo: object))
    }

    func test_notEqualToOperator_shouldReturnNotEqualToPropertyCondition() throws {
        let object = try createObject()
        let sut = \TestEntity.self != object
        XCTAssertEqual(sut, PropertyCondition(notEqualTo: object))
    }

    func test_inOperator_shouldReturnInArrayPropertyCondition() throws {
        let object = try createObject()
        let array: [TestEntity.ReadOnly] = [object]
        let sut = \TestEntity.self <> array
        XCTAssertEqual(sut, PropertyCondition(in: array))
    }

    func test_inOperator_shouldReturnInSetPropertyCondition() throws {
        let object = try createObject()
        let set: Set<TestEntity.ReadOnly> = [object]
        let sut = \TestEntity.self <> `set`
        XCTAssertEqual(sut, PropertyCondition(in: `set`))
    }
}
