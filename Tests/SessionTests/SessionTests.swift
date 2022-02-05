//
//  SessionTests.swift
//  
//
//  Created by ezou on 2022/2/5.
//

import XCTest

@testable import Crush

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
            storage: storage,
            dataModel: DataModel(name: "DATAMODEL", concrete: [TestEntity()]))
    }

    override func tearDownWithError() throws {
        try container.destroyStorages()
    }

    func test_asyncReturnPlainProperty_shouldReturnSameProperty() async throws {
        let result = try await container.startSession().`async` { context -> Int16? in
            let entity = context.create(entity: TestEntity.self)
            entity.integerValue = 10
            try context.commit()
            return entity.integerValue
        }
        XCTAssertEqual(result, 10)
    }

    func test_asyncReturnUnsafeProperty_shouldBeWrapped() async throws {
        let result: TestEntity.ReadOnly = try await container.startSession().`async` {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            entity.integerValue = 11
            try context.commit()
            return entity
        }
        XCTAssertEqual(result.integerValue, 11)
    }

    func test_asd() async throws {
        try await container.startSession().`async` { context in
            let entity = context.create(entity: TestEntity.self)
            entity.integerValue = 11
            try context.commit()
        }
        let result = await container.fetch(for: TestEntity.self).execAsync()
        print(result)
    }
}
