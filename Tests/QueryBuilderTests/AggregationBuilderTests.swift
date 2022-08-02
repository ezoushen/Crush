//
//  AggregationBuilderTests.swift
//  
//
//  Created by EZOU on 2022/7/19.
//

import Foundation
import XCTest

@testable import Crush

class AggregationBuilderTests: XCTestCase {
    class TestEntity: Entity {
        @Optional
        var integerValue = Value.Int("integerValue")
        
        @Optional
        var stringValue = Value.String("stringValue")
    }
    
    let storage = Storage.sqliteInMemory()
    var container: DataContainer!
    
    override func setUp() async throws {
        container = try .load(
            storages: storage,
            dataModel: DataModel(
                name: "DATAMODEL",
                concrete: [TestEntity()]))
    }
    
    func test_groupBy_shouldGroupByIntegerValue() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 1
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .group(by: \.integerValue)
            .exec()
        XCTAssertEqual(results as! [[String: Int]], [["integerValue": 1]])
    }
    
    func test_groupBy_shouldGroupByIntegerValueAndStringValue() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            entity1.stringValue = "a"
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 1
            entity2.stringValue = "b"
            let entity3 = context.create(entity: TestEntity.self)
            entity3.integerValue = 2
            entity3.stringValue = "b"
            let entity4 = context.create(entity: TestEntity.self)
            entity4.integerValue = 1
            entity4.stringValue = "a"
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .group(by: \.integerValue)
            .group(by: \.stringValue)
            .exec() as NSArray
        XCTAssertTrue(results
            .isEqual(to: [
                ["integerValue": 1, "stringValue": "a"],
                ["integerValue": 1, "stringValue": "b"],
                ["integerValue": 2, "stringValue": "b"],
            ]))
    }
    
    func test_orHavingPredicate_shouldFilterByOrHavingPredicate() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            entity1.stringValue = "a"
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 1
            entity2.stringValue = "b"
            let entity3 = context.create(entity: TestEntity.self)
            entity3.integerValue = 2
            entity3.stringValue = "b"
            let entity4 = context.create(entity: TestEntity.self)
            entity4.integerValue = 1
            entity4.stringValue = "a"
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .group(by: \.integerValue)
            .aggregate(.count(\.stringValue), as: "stringCount")
            .aggregate(.max(\.stringValue), as: "maxString")
            .havingPredicate("$stringCount > 1")
            .orHavingPredicate("$maxString == %@", "b")
            .exec() as NSArray
        XCTAssertTrue(results
            .isEqual(to: [
                ["integerValue": 1, "stringCount": 3, "maxString": "b"],
                ["integerValue": 2, "stringCount": 1, "maxString": "b"],
            ]))
    }
    
    func test_andHavingPredicate_shouldFilterByAndHavingPredicate() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            entity1.stringValue = "a"
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 1
            entity2.stringValue = "b"
            let entity3 = context.create(entity: TestEntity.self)
            entity3.integerValue = 2
            entity3.stringValue = "b"
            let entity4 = context.create(entity: TestEntity.self)
            entity4.integerValue = 3
            entity4.stringValue = "a"
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .group(by: \.integerValue)
            .aggregate(.count(\.stringValue), as: "stringCount")
            .aggregate(.max(\.stringValue), as: "maxString")
            .havingPredicate("$stringCount >= 1")
            .andHavingPredicate("$maxString == %@", "b")
            .exec() as NSArray
        XCTAssertTrue(results
            .isEqual(to: [
                ["integerValue": 1, "stringCount": 2, "maxString": "b"],
                ["integerValue": 2, "stringCount": 1, "maxString": "b"],
            ]))
    }
    
    func test_havingPredicate_shouldFilterByHavingPredicate() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            entity1.stringValue = "a"
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 1
            entity2.stringValue = "b"
            let entity3 = context.create(entity: TestEntity.self)
            entity3.integerValue = 2
            entity3.stringValue = "b"
            let entity4 = context.create(entity: TestEntity.self)
            entity4.integerValue = 1
            entity4.stringValue = "a"
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .group(by: \.integerValue)
            .aggregate(.count(\.stringValue), as: "stringCount")
            .havingPredicate("$stringCount > 1")
            .exec() as NSArray
        XCTAssertTrue(results
            .isEqual(to: [
                ["integerValue": 1, "stringCount": 3],
            ]))
    }
    
    func test_aggregate_shouldCountInstances() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            entity1.stringValue = "string"
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 1
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .group(by: \.integerValue)
            .aggregate(.count(\.stringValue), as: "stringCount")
            .exec()
        XCTAssertEqual(
            results as! [[String: Int]],
            [["integerValue": 1, "stringCount": 1]])
    }
    
    func test_aggregate_shouldFindMaxInstance() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            entity1.stringValue = "string"
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 2
            entity2.stringValue = "string"
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .group(by: \.stringValue)
            .aggregate(.max(\.integerValue), as: "maxInt")
            .exec() as NSArray
        XCTAssertTrue(results
            .isEqual(to: [["stringValue": "string", "maxInt": 2]]))
    }
    
    func test_aggregate_shouldFindMinInstance() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            entity1.stringValue = "string"
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 2
            entity2.stringValue = "string"
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .group(by: \.stringValue)
            .aggregate(.min(\.integerValue), as: "minInt")
            .exec() as NSArray
        XCTAssertTrue(results
            .isEqual(to: [["stringValue": "string", "minInt": 1]]))
    }
    
    func test_aggregate_shouldSum() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            entity1.stringValue = "string"
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 2
            entity2.stringValue = "string"
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .group(by: \.stringValue)
            .aggregate(.sum(\.integerValue), as: "sum")
            .exec() as NSArray
        XCTAssertTrue(results
            .isEqual(to: [["stringValue": "string", "sum": 3]]))
    }
    
    func test_aggregate_shouldCalculateAverage() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            entity1.stringValue = "string"
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 2
            entity2.stringValue = "string"
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .group(by: \.stringValue)
            .aggregate(.average(\.integerValue), as: "avg")
            .exec() as NSArray
        XCTAssertTrue(results
            .isEqual(to: [["stringValue": "string", "avg": 1.5]]))
    }
}

class SelectBuilderTests: XCTestCase {
    class TestEntity: Entity {
        @Optional
        var integerValue = Value.Int("integerValue")
    }
    
    let storage = Storage.sqliteInMemory()
    var container: DataContainer!
    
    override func setUp() async throws {
        container = try .load(
            storages: storage,
            dataModel: DataModel(
                name: "DATAMODEL",
                concrete: [TestEntity()]))
    }
    
    func test_select_shouldContainSpecifiedField() throws {
        try container.startSession().sync { context in
            for i in 0...10 {
                let entity = context.create(entity: TestEntity.self)
                entity.integerValue = i
            }
            try context.commit()
        }
        
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .select(\.integerValue)
            .exec()
        
        let allContainIntegerValue = results
            .map(\.keys)
            .map { $0.contains("integerValue") }
            .contains(false) == false
        
        XCTAssertTrue(allContainIntegerValue)
    }
    
    func test_select_shouldProjectSpecifiedField() throws {
        try container.startSession().sync { context in
            for i in 0...10 {
                let entity = context.create(entity: TestEntity.self)
                entity.integerValue = i
            }
            try context.commit()
        }
        
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .select(SelectPath(\TestEntity.integerValue, as: "PROJECTED"))
            .exec()
        
        let allContainProjectedName = results
            .map(\.keys)
            .map { $0.contains("PROJECTED") }
            .contains(false) == false
        
        XCTAssertTrue(allContainProjectedName)
    }
    
    func test_returnsDistinctValuesTrue_shouldRemoveDupes() throws {
        try container.startSession().sync { context in
            for _ in 0...10 {
                let entity = context.create(entity: TestEntity.self)
                entity.integerValue = 1
            }
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .select(\.integerValue)
            .returnsDistinctResults()
            .exec() as NSArray
        XCTAssertTrue(results.isEqual(to: [["integerValue": 1]]))
    }
    
    func test_returnsDistinctValuesFalse_shouldRemoveDupes() throws {
        try container.startSession().sync { context in
            let entity1 = context.create(entity: TestEntity.self)
            entity1.integerValue = 1
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 1
            try context.commit()
        }
        let results = container
            .fetch(for: TestEntity.self)
            .asDictionary()
            .select(\.integerValue)
            .returnsDistinctResults(false)
            .exec() as NSArray
        XCTAssertTrue(results.isEqual(to: [["integerValue": 1], ["integerValue": 1]]))
    }
}
