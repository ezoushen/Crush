//
//  DataContainerTests.swift
//  
//
//  Created by EZOU on 2023/2/25.
//

import Foundation
import XCTest

@testable import Crush

final class DataContainerTests: XCTestCase {

    var storage: Storage!
    var container: DataContainer!

    class TestEntity: Entity {
        @Optional
        var property = Value.Bool("property")
    }

    override func setUpWithError() throws {
        storage = Storage.sqliteInMemory(
            options: .persistentHistoryTracking(true), .remoteChangeNotification(true))
        container = try DataContainer.load(
            storages: storage,
            dataModel: DataModel(name: "DATAMODEL", concrete: [TestEntity()]))
    }

    override func tearDown() {
        container = nil
    }

    func test_metadata_shouldReturnSavedMetadataAndGuaranteeThreadSafety() throws {
        let container = container!
        let storage = storage!
        DispatchQueue.concurrentPerform(iterations: 100) { i in
            container.setMetadata(key: "\(i)", value: i, storage: storage)
        }
        let metadata = container.metadata(of: storage)
        for i in 0...99 {
            XCTAssertEqual(metadata?["\(i)"] as? Int, i)
        }
    }

    func test_removeMetada_shouldRemoveValueIndexedByKey() {
        let container = container!
        let storage = storage!
        container.setMetadata(key: "TEST", value: 123, storage: storage)
        container.removeMetadata(key: "TEST", storage: storage)
        XCTAssertNil(container.metadata(of: storage)?["TEST"])
    }

    func test_batchRemoveMetada_shouldRemoveValueIndexedByKey() {
        let container = container!
        let storage = storage!
        container.setMetadata(["TEST": 123, "TEST2": 321], storage: storage)
        container.removeMetadata(keys: ["TEST", "TEST2"], storage: storage)
        XCTAssertNil(container.metadata(of: storage)?["TEST"])
        XCTAssertNil(container.metadata(of: storage)?["TEST2"])
    }

    func test_rebuildStorages_shouldCleanAllData() throws {
        container.setMetadata(key: "TEST", value: 123, storage: storage)
        try container.rebuildStorages()
        XCTAssertNil(container.metadata(of: storage)?["TEST"])
    }

    func test_destroyStorages_shouldRemoveAllStorages() throws {
        try container.destroyStorages()
        XCTAssertTrue(container.coreDataStack.storages.isEmpty)
    }

    func test_destroyStorage_shouldRemoveSpecifiedStorage() throws {
        try container.destroy(storage: storage)
        XCTAssertFalse(container.coreDataStack.storages.contains(storage))
    }

    func test_loadStorage_shouldLoadTheStorageIntoStack() throws {
        let storage = Storage.inMemory()
        try container.load(storage: storage)
        XCTAssertTrue(container.coreDataStack.isLoaded(storage: storage))
    }

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    func test_loadTransactionHistory_shouldBeNotEmpty() throws {
        let now = Date()
        try container.startSession().sync { context in
            let entity = context.create(entity: TestEntity.self)
            entity.property = true
            try context.commit()
        }
        try container.startSession().sync { context in
            let entity = context.create(entity: TestEntity.self)
            entity.property = false
            try context.commit()
        }
        let result = container.loadTransactionHistory(since: now)
        XCTAssertFalse(result.isEmpty)
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
    func test_uiContextDidRefreshNotification_shouldReceiveContextDidSave() throws {
        let expectation = expectation(description: #function)
        var receiveCount: Int = 0
        let cancellable = NotificationCenter.default
            .publisher(for: DataContainer.uiContextDidRefresh, object: container)
            .timeout(.seconds(3), scheduler: DispatchQueue.main)
            .first()
            .sink { _ in
                expectation.fulfill()
            } receiveValue: { _ in
                receiveCount += 1
            }
        defer { cancellable.cancel() }
        container.startSession().sync { context in
            let entity = context.create(entity: TestEntity.self)
            entity.property = true
            try! context.commit()
        }
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(receiveCount, 1)
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
    func test_uiContextDidRefreshNotification_shouldReceivePersistentHistoryChanges() throws {
        let expectation = expectation(description: #function)
        var receiveCount: Int = 0
        let cancellable = NotificationCenter.default
            .publisher(for: DataContainer.uiContextDidRefresh, object: container)
            .timeout(.seconds(3), scheduler: DispatchQueue.main)
            .first()
            .sink { _ in
                expectation.fulfill()
            } receiveValue: { _ in
                receiveCount += 1
            }
        defer { cancellable.cancel() }
        let anotherContainer = try DataContainer.load(
            storages: storage,
            dataModel: DataModel(name: "DATAMODEL", concrete: [TestEntity()]))
        anotherContainer.startSession().sync { context in
            let entity = context.create(entity: TestEntity.self)
            entity.property = true
            try! context.commit()
        }
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(receiveCount, 1)
    }
}
