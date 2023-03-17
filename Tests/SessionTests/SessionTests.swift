//
//  SessionTests.swift
//  
//
//  Created by ezou on 2022/2/5.
//

import CoreData
import XCTest

@testable import Crush
#if canImport(_Concurrency) && compiler(>=5.5.2)
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
class SessionTests: XCTestCase {
    class TestEntity: Entity {
        @Optional
        var integerValue = Value.Int16("integerValue")
    }

    let storage = Storage.sqliteInMemory()
    var container: DataContainer!

    override func setUpWithError() throws {
        try container = .load(
            storages: storage,
            dataModel: DataModel(name: "DATAMODEL", concrete: [TestEntity()]))
    }

    override func tearDownWithError() throws {
        try container.destroyStorages()
    }

    func test_asyncReturnPlainProperty_shouldReturnSameProperty() async throws {
        let result = try await container.startSession().asyncThrowing { context -> Int16? in
            let entity = context.create(entity: TestEntity.self)
            entity.integerValue = 10
            try context.commit()
            return entity.integerValue
        }
        XCTAssertEqual(result, 10)
    }

    func test_asyncReturnUnsafeProperty_shouldBeWrapped() async throws {
        let result: TestEntity.ReadOnly = try await container.startSession().asyncThrowing {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            entity.integerValue = 11
            try context.commit()
            return entity
        }
        XCTAssertEqual(result.integerValue, 11)
    }

    func test_returnUnsafeReadOnlyObject_shouldBeWrapped() throws {
        let session = container.startSession()
        var fetchedContext: NSManagedObjectContext!
        let result = try session.sync {
            context -> TestEntity.ReadOnly in
            let entity = context.create(entity: TestEntity.self)
            entity.integerValue = 11
            try context.commit()
            let fetched = context
                .fetch(for: TestEntity.self)
                .asReadOnly()
                .findOne()!
            fetchedContext = fetched.context
            return fetched
        }
        XCTAssertNotEqual(fetchedContext, result.context)
    }
    
    func test_async_shouldNotBlock() {
        var flag = false
        container.startSession().async { _ in
            sleep(10)
            flag = true
        }
        XCTAssertFalse(flag)
    }
    
    func test_sync_shouldBlock() {
        var flag = false
        container.startSession().sync { _ in
            flag = true
        }
        XCTAssertTrue(flag)
    }
    
    func test_sync_shouldReturnIntegerValue() {
        let result: Int = container.startSession().sync { _ in 11 }
        XCTAssertEqual(result, 11)
    }
    
    func test_sync_shouldReturnEntity() throws {
        var objectID: NSManagedObjectID?
        let result: TestEntity.ReadOnly = try container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            try context.commit()
            try context.obtainPermanentIDs(for: [entity])
            objectID = entity.objectID
            return entity
        }
        XCTAssertEqual(result.objectID, objectID)
    }
}
#endif
