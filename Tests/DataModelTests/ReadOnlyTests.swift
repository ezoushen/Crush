//
//  ReadOnlyTests.swift
//  
//
//  Created by ezou on 2021/10/22.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

class ReadOnlyTests: XCTestCase {
    class TestEntity: Entity {
        var integerValue = Value.Int16("integerValue")
        var ordered = Relation.ToOrdered<TestEntity>("ordered")
        var many = Relation.ToMany<TestEntity>("many")
        var one = Relation.ToOne<TestEntity>("one")
        var fetched = Fetched<TestEntity>("fetched") { $0.where(\.integerValue == 0) }
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    class DerivedTestEntity: Entity {
        var integerValue = Value.Int16("integerValue")
        var derived = Derived.Int16("derived", from: \TestEntity.integerValue)
    }
    
    var container: DataContainer!
    
    override func setUpWithError() throws {
        let dataModel: DataModel = {
            if #available(iOS 13.0, watchOS 6.0, macOS 10.15, *) {
                return DataModel(
                    name: "NAME",
                    concrete: [TestEntity(), DerivedTestEntity()])
            } else {
                return DataModel(
                    name: "NAME",
                    concrete: [TestEntity()])
            }
        }()
        container = try DataContainer.load(
            storages: .sqlite(
                name: "\(UUID())",
                options: .sqlitePragma(key: "journal_mode", value: "DELETE" as NSObject)),
            dataModel: dataModel)
    }
    
    override func tearDownWithError() throws {
        try container.destroyStorages()
    }
    
    func test_readAttribute_shouldReturnUpdatedValue() {
        let entity: TestEntity.ReadOnly = container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            entity.integerValue = 10
            try! context.commit()
            return entity
        }
        XCTAssertEqual(entity.integerValue, 10)
    }
    
    func test_readOrderedRelations_shouldReturnOrderedSet() {
        let entity: TestEntity.ReadOnly = container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            let entity2 = context.create(entity: TestEntity.self)
            entity.ordered.insert(entity2)
            try! context.commit()
            return entity
        }
        XCTAssertEqual(entity.ordered.count, 1)
    }
    
    func test_readManyRelations_shouldReturnSet() {
        let entity: TestEntity.ReadOnly = container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            let entity2 = context.create(entity: TestEntity.self)
            entity.many.insert(entity2)
            try! context.commit()
            return entity
        }
        XCTAssertEqual(entity.many.count, 1)
    }
    
    func test_readOneRelation_shouldReturnReadOnlyObject() {
        let entity: TestEntity.ReadOnly = container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            let entity2 = context.create(entity: TestEntity.self)
            entity.one = entity2
            try! context.commit()
            return entity
        }
        XCTAssertNotNil(entity.one)
    }
    
    func test_readFetchProperty_shouldReturnObjects() {
        let entity: TestEntity.ReadOnly = container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 0
            try! context.commit()
            return entity
        }
        XCTAssertEqual(entity.fetched.count, 1)
    }

    func createDefaultEntity(integerValue: Int16) -> TestEntity.ReadOnly {
        container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            entity.integerValue = integerValue
            try! context.commit()
            return entity
        }
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    func test_readDerivedAttribute_shouldReturnDerivedValue() {
        let entity: DerivedTestEntity.ReadOnly = container.startSession().sync {
            context -> DerivedTestEntity.Managed in
            let entity = context.create(entity: DerivedTestEntity.self)
            entity.integerValue = 10
            try! context.commit()
            return entity
        }
        XCTAssertEqual(entity.derived, 10)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func test_combineKVOPublisher_shouldGetInitialValue() throws {
        let entity = createDefaultEntity(integerValue: 10)
        let value: Int16? = try awaitPublisher(
            entity.observe(\.integerValue, options: [.initial, .new]).first())
        XCTAssertEqual(value, 10)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func test_combineKVOPublisher_shouldGetNewValue() throws {
        let entity = createDefaultEntity(integerValue: 10)
        let value: Int16? = try
            awaitPublisher(entity.observe(\.integerValue, options: [.new]).first()) {
                try container.startSession().sync { context in
                    let entity = context.edit(object: entity)
                    entity.integerValue = 11
                    try context.commit()
                }
            }
        XCTAssertEqual(value, 11)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func test_combineKVOPublisher_shouldGetNewAndOldValues() throws {
        let entity = createDefaultEntity(integerValue: 10)
        let value: [Int16?] = try
            awaitPublisher(
                entity.observe(\.integerValue, options: [.new, .old])
                    .removeDuplicates().prefix(2).collect()
            ) {
                try container.startSession().sync { context in
                    let entity = context.edit(object: entity)
                    entity.integerValue = 11
                    try context.commit()
                }
            }
        XCTAssertEqual(value, [10, 11])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func test_combineKVOPublisher_shouldReceiveCompletionOnceTheObjectDeleted() throws {
        let entity = createDefaultEntity(integerValue: 10)
        let expectation = expectation(description: "")
        var finished: Bool = false
        let cancellable = entity
            .observe(\.integerValue, options: [ .new, .initial ])
            .sink {
                guard case .finished = $0 else { return }
                finished = true
                expectation.fulfill()
            } receiveValue: { _ in }

        try container.startSession().sync { context in
            let entity = context.edit(object: entity)
            context.delete(entity)
            try context.commit()
        }

        defer { cancellable.cancel() }

        wait(for: [expectation], timeout: 3.0)

        XCTAssertTrue(finished)
    }
}
