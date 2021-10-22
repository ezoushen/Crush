//
//  File.swift
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
        var derived = Derived.Int16("derived", from: \TestEntity.integerValue)
        var ordered = Relation.ToOrdered<TestEntity>("ordered")
        var many = Relation.ToMany<TestEntity>("many")
        var one = Relation.ToOne<TestEntity>("one")
        var fetched = Fetched<TestEntity>("fetched") { $0.where(\.integerValue == 0) }
    }
    
    let container = try! DataContainer.load(
        storage: .sqlite(name: "Test"),
        dataModel: DataModel(
            name: "NAME",
            concrete: [TestEntity()]))
    
    override func setUp() {
        try? container.buildStorage()
    }
    
    override func tearDown() {
        try! container.destroyStorage()
    }
    
    func test_readAttribute_shouldReturnUpdatedValue() {
        let entity: TestEntity.ReadOnly =  container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            entity.integerValue = 10
            try! context.commit()
            return entity
        }
        XCTAssertEqual(entity.integerValue, 10)
    }
    
    func test_readDerivedAttribute_shouldReturnDerivedValue() {
        let entity: TestEntity.ReadOnly =  container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            entity.integerValue = 10
            try! context.commit()
            return entity
        }
        XCTAssertEqual(entity.derived, 10)
    }
    
    func test_readOrderedRelations_shouldReturnOrderedSet() {
        let entity: TestEntity.ReadOnly =  container.startSession().sync {
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
        let entity: TestEntity.ReadOnly =  container.startSession().sync {
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
        let entity: TestEntity.ReadOnly =  container.startSession().sync {
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
        let entity: TestEntity.ReadOnly =  container.startSession().sync {
            context -> TestEntity.Managed in
            let entity = context.create(entity: TestEntity.self)
            let entity2 = context.create(entity: TestEntity.self)
            entity2.integerValue = 0
            try! context.commit()
            return entity
        }
        XCTAssertEqual(entity.fetched.count, 1)
    }
}
