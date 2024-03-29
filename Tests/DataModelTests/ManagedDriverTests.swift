//
//  ManagedDriverTests.swift
//  
//
//  Created by ezou on 2021/10/24.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

class ManagedDriverTests: XCTestCase {
    struct StructValue: CodableAttributeType {
        let value: Int
    }
    
    class TestEntity: Entity {
        var integerValue = Value.Int64("integerValue")
        var structValue = Value.Codable<StructValue>("structValue")
        
        var ordered = Relation.ToOrdered<TestEntity>("ordered")
        var unordered = Relation.ToMany<TestEntity>("unordered")
        var testEntity = Relation.ToOne<TestEntity>("testEntity")
    }

    static var container: DataContainer! = try! DataContainer.load(
        storages: .sqliteInMemory(),
        dataModel: DataModel(
            name: "model",
            concrete: [TestEntity()]))

    let container: DataContainer = ManagedDriverTests.container
    var sut: ReadOnly<TestEntity>!

    override class func tearDown() {
        container = nil
    }

    override func setUp() {
        sut = container.startSession().sync {
            context -> TestEntity.Driver in
            defer { try! context.commit() }
            return context.create(entity: TestEntity.self)
        }
    }

    override func tearDown() {
        try! container.rebuildStorages()
    }
    
    func test_keyPathLookupValue_shouldBeSet() {
        let session = container.startSession()
        session.enabledWarningForUnsavedChanges = false
        session.sync {
            let object = $0.edit(object: sut).driver()
            object.integerValue = 10
            XCTAssertEqual(object.integerValue, 10)
        }
    }

    func test_keyPathLookupToOneRelation_shouldBeSet() {
        let session = container.startSession()
        session.enabledWarningForUnsavedChanges = false
        session.sync {
            let newObject = $0.create(entity: TestEntity.self)
            let object = $0.edit(object: sut).driver()
            object.testEntity = newObject
            XCTAssertEqual(object.testEntity, newObject)
        }
    }

    func test_keyPathLookupToManyRelation_shouldBeSet() {
        let session = container.startSession()
        session.enabledWarningForUnsavedChanges = false
        session.sync {
            let newObject = $0.create(entity: TestEntity.self)
            let object = $0.edit(object: sut).driver()
            object.unordered.insert(newObject)
            XCTAssertTrue(object.unordered.contains(newObject))
        }
    }

    func test_keyPathLookupToOrderedRelation_shouldBeSet() {
        let session = container.startSession()
        session.enabledWarningForUnsavedChanges = false
        session.sync {
            let newObject = $0.create(entity: TestEntity.self)
            let object = $0.edit(object: sut).driver()
            object.ordered.insert(newObject)
            XCTAssertTrue(object.ordered.contains(newObject))
        }
    }
    
    func test_keyPathLookupRawValue_shouldEqual() throws {
        let session = container.startSession()
        try session.sync {
            let object = $0.edit(object: sut)
            let value = StructValue(value: 10)
            object.structValue = value
            XCTAssertEqual(try JSONEncoder().encode(value), object.raw.structValue)
        }
    }
}
