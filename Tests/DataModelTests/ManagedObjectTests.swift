//
//  ManagedObjectTests.swift
//  
//
//  Created by ezou on 2021/10/22.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

final class ManagedObjectTests: XCTestCase {
    class TestEntity: Entity {
        static var willSaveEvent: ((NSManagedObject) -> Void)?
        static var didSaveEvent: ((NSManagedObject) -> Void)?
        static var prepareForDeletionEvent: ((NSManagedObject) -> Void)?
        static var willTurnIntoFaultEvent: ((NSManagedObject) -> Void)?
        static var didTurnIntoFaultEvent: ((NSManagedObject) -> Void)?
        static var awakeFromFetchEvent: ((NSManagedObject) -> Void)?
        static var awakeFromInsertEvent: ((NSManagedObject) -> Void)?
        static var awakeFromSnapshotEvents: ((NSManagedObject, NSSnapshotEventType) -> Void)?

        override class func willSave(_ managedObject: NSManagedObject) {
            willSaveEvent?(managedObject)
        }

        override class func didSave(_ managedObject: NSManagedObject) {
            didSaveEvent?(managedObject)
        }

        override class func prepareForDeletion(_ managedObject: NSManagedObject) {
            prepareForDeletionEvent?(managedObject)
        }

        override class func willTurnIntoFault(_ managedObject: NSManagedObject) {
            willTurnIntoFaultEvent?(managedObject)
        }

        override class func didTurnIntoFault(_ managedObject: NSManagedObject) {
            didTurnIntoFaultEvent?(managedObject)
        }

        override class func awakeFromFetch(_ managedObject: NSManagedObject) {
            awakeFromFetchEvent?(managedObject)
        }

        override class func awakeFromInsert(_ managedObject: NSManagedObject) {
            awakeFromInsertEvent?(managedObject)
        }

        override class func awake(_ managedObject: NSManagedObject, fromSnapshotEvents: NSSnapshotEventType) {
            awakeFromSnapshotEvents?(managedObject, fromSnapshotEvents)
        }

        var integerValue = Value.Int64("integerValue")
        var ordered = Relation.ToOrdered<TestEntity>("ordered")
        var unordered = Relation.ToMany<TestEntity>("unordered")
        var testEntity = Relation.ToOne<TestEntity>("testEntity")
    }

    static var container: DataContainer! = try! DataContainer.load(
        storage: .inMemory(),
        dataModel: DataModel(
            name: "model",
            concrete: [TestEntity()]))

    let container: DataContainer = ManagedObjectTests.container
    var sut: ReadOnly<TestEntity>!

    override class func tearDown() {
        container = nil
    }

    override func setUp() {
        TestEntity.willSaveEvent = nil
        TestEntity.didSaveEvent = nil
        TestEntity.prepareForDeletionEvent = nil
        TestEntity.willTurnIntoFaultEvent = nil
        TestEntity.didTurnIntoFaultEvent = nil
        TestEntity.awakeFromFetchEvent = nil
        TestEntity.awakeFromInsertEvent = nil
        TestEntity.awakeFromSnapshotEvents = nil

        sut = container.startSession().sync {
            context -> TestEntity.Managed in
            defer { try! context.commit() }
            return context.create(entity: TestEntity.self)
        }
    }

    override func tearDown() {
        try! container.rebuildStorage()
    }

    func test_willSaveEvent_shouldBeCalled() {
        var called: Bool = false
        TestEntity.willSaveEvent = { _ in called = true }
        container.startSession().sync {
            let entity = $0.edit(object: sut)
            entity.integerValue = 10
            try! $0.commit()
        }
        XCTAssertTrue(called)
    }

    func test_didSaveEvent_shouldBeCalled() {
        var called: Bool = false
        TestEntity.didSaveEvent = { _ in called = true }
        container.startSession().sync {
            let entity = $0.edit(object: sut)
            entity.integerValue = 10
            try! $0.commit()
        }
        XCTAssertTrue(called)
    }

    func test_prepareForDeletionEvent_shouldBeCalled() {
        var called: Bool = false
        TestEntity.prepareForDeletionEvent = { _ in called = true }
        container.startSession().sync {
            let entity = $0.edit(object: sut)
            $0.delete(entity)
            try! $0.commit()
        }
        XCTAssertTrue(called)
    }

    func test_willTurnIntoFault_shouldBeCalled() {
        var called: Bool = false
        TestEntity.willTurnIntoFaultEvent = { _ in called = true }
        container.startSession().sync {
            let context = $0 as! RawContextProviderProtocol
            let entity = $0.edit(object: sut)
            context.executionContext.refresh(entity, mergeChanges: true)
        }
        XCTAssertTrue(called)
    }

    func test_didTurnIntoFault_shouldBeCalled() {
        var called: Bool = false
        TestEntity.didTurnIntoFaultEvent = { _ in called = true }
        container.startSession().sync {
            let context = $0 as! RawContextProviderProtocol
            let entity = $0.edit(object: sut)
            context.executionContext.refresh(entity, mergeChanges: true)
        }
        XCTAssertTrue(called)
    }

    func test_awakeFromSnapshotEvents_shouldBeCalled() {
        var called: Bool = false
        TestEntity.awakeFromSnapshotEvents = { _, _ in called = true }
        let session = container.startUiSession()
        session.enableUndoManager()
        session.enabledWarningForUnsavedChanges = false
        session.sync { context in
            let object = context.edit(object: sut)
            object.integerValue = 10
        }
        session.undo()
        XCTAssertTrue(called)
    }

    func test_awakeFromFetch_shouldBeCalled() {
        var called: Bool = false
        TestEntity.awakeFromFetchEvent = { _ in called = true }
        container.startSession().sync {
            _ = $0.fetch(for: TestEntity.self).findOne()
        }
        XCTAssertTrue(called)
    }

    func test_awakeFromInsert_shouldBeCalled() {
        var called: Bool = false
        TestEntity.awakeFromInsertEvent = { _ in called = true }
        container.startSession().sync {
            _ = $0.create(entity: TestEntity.self)
            try! $0.commit()
        }
        XCTAssertTrue(called)
    }

    func test_keyPathLookupValue_shouldBeSet() {
        let session = container.startSession()
        session.enabledWarningForUnsavedChanges = false
        session.sync {
            let object = $0.edit(object: sut)
            object.integerValue = 10
            XCTAssertEqual(object.integerValue, 10)
        }
    }

    func test_keyPathLookupToOneRelation_shouldBeSet() {
        let session = container.startSession()
        session.enabledWarningForUnsavedChanges = false
        session.sync {
            let newObject = $0.create(entity: TestEntity.self)
            let object = $0.edit(object: sut)
            object.testEntity = newObject
            XCTAssertEqual(object.testEntity, newObject)
        }
    }

    func test_keyPathLookupToManyRelation_shouldBeSet() {
        let session = container.startSession()
        session.enabledWarningForUnsavedChanges = false
        session.sync {
            let newObject = $0.create(entity: TestEntity.self)
            let object = $0.edit(object: sut)
            object.unordered.insert(newObject)
            XCTAssertTrue(object.unordered.contains(newObject))
        }
    }

    func test_keyPathLookupToOrderedRelation_shouldBeSet() {
        let session = container.startSession()
        session.enabledWarningForUnsavedChanges = false
        session.sync {
            let newObject = $0.create(entity: TestEntity.self)
            let object = $0.edit(object: sut)
            object.ordered.insert(newObject)
            XCTAssertTrue(object.ordered.contains(newObject))
        }
    }
}
