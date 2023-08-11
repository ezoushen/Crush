//
//  PrimaryKeyTests.swift
//  
//
//  Created by EZOU on 2023/8/12.
//

import XCTest

@testable import Crush

final class PrimaryKeyTests: XCTestCase {

    class TestEntity: Entity {
        @Optional
        var property = Value.Bool("property")
    }

    var container: DataContainer!
    var entity: TestEntity.ReadOnly!

    override func setUpWithError() throws {
        container = try .load(
            storages: .sqliteInMemory(),
            dataModel: DataModel(name: "DATAMODEL", [TestEntity()]))
        entity = try container.startSession().sync {
            let entity = $0.create(entity: TestEntity.self)
            try $0.commit()
            return entity
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_containerLoadObjectByPrimaryKey_shouldLoadObject() {
        let object: TestEntity.ReadOnly? =
            container.load(primaryKeys: [.init(1)]).first!
        XCTAssertNotNil(object)
    }

    func test_containerLoadObjectByPrimaryKey_shouldReturnNilIfObjectDoesNotExist() {
        let object: TestEntity.ReadOnly? =
            container.load(primaryKeys: [.init(2)]).first!
        XCTAssertNil(object)
    }

    func test_containerLoadObjectIDFromPrimaryKey_shouldEqualToObjectID() {
        let sut = entity.objectID
        let result = container.objectID(
            from: PrimaryKey<TestEntity>(1))
        XCTAssertEqual(sut, result)
    }

    func test_sessionLoadObjectByPrimaryKey_shouldLoadObject() {
        let session = container.startSession()
        let object = session.load(
            primaryKeys: [PrimaryKey<TestEntity>(1)]).first!
        XCTAssertNotNil(object)
    }

    func test_sessionLoadObjectByPrimaryKey_shouldReturnNilIfObjectDoesNotExist() {
        let session = container.startSession()
        let object = session.load(
            primaryKeys: [PrimaryKey<TestEntity>(2)]).first!
        XCTAssertNil(object)
    }

    func test_sessionLoadObjectIDFromPrimaryKey_shouldEqualToObjectID() {
        let sut = entity.objectID
        let result = container.startSession().objectID(
            from: PrimaryKey<TestEntity>(1))
        XCTAssertEqual(sut, result)
    }

    func test_sessionContextLoadObjectByPrimaryKey_shouldLoadObject() {
        let session = container.startSession()
        session.sync {
            let object = $0.load(primaryKeys: [PrimaryKey<TestEntity>(1)]).first!
            XCTAssertNotNil(object)
        }
    }

    func test_sessionContextLoadObjectByPrimaryKey_shouldReturnNilIfObjectDoesNotExist() {
        let session = container.startSession()
        session.sync {
            let object = $0.load(primaryKeys: [PrimaryKey<TestEntity>(2)]).first!
            XCTAssertNil(object)
        }
    }

    func test_sessionContextLoadObjectIDFromPrimaryKey_shouldEqualToObjectID() {
        let sut = entity.objectID
        let result = container.startSession().sync {
            $0.objectID(from: PrimaryKey<TestEntity>(1))
        }
        XCTAssertEqual(sut, result)
    }

    func test_managedObjectPrimaryKey() {
        container.startSession().sync {
            let entity = $0.edit(object: entity)
            let sut = entity.primaryKey
            let primarykey = PrimaryKey<TestEntity>(1)
            XCTAssertEqual(sut, primarykey)
        }
    }

    func test_readOnlyPrimaryKey() {
        let sut = entity.primaryKey
        let primarykey = PrimaryKey<TestEntity>(1)
        XCTAssertEqual(sut, primarykey)
    }

    func test_driverPrimaryKey() {
        let sut = entity.driver.primaryKey
        let primarykey = PrimaryKey<TestEntity>(1)
        XCTAssertEqual(sut, primarykey)
    }

    func test_fetchPredicateByPrimaryKey() {
        let primarykey = PrimaryKey<TestEntity>(1)
        let sut = container
            .fetch(for: TestEntity.self)
            .where(\.self == primarykey.objectID(container)!)
            .findOne()
        XCTAssertEqual(sut, entity)
    }
}
