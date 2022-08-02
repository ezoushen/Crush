//
//  FetchBuilderTests.swift
//  
//
//  Created by EZOU on 2022/7/12.
//

import Foundation
import XCTest

@testable import Crush

class FetchBuilderTestSuite {
    class ParentEntity: Entity {
        @Optional
        var parentValue = Value.Bool("parentValue")
    }
    
    class TestEntity: ParentEntity {
        @Optional
        var integerValue = Value.Int16("integerValue")
        
        @Optional
        var stringValue = Value.String("stringValue")
        
        @Optional
        var another = Relation.ToOne<TestEntity>("another")

        @Optional
        var other = Relation.ToOne<TestEntity>("other")

        @Optional
        var others = Relation.ToMany<TestEntity>("others")
    }

    let storage = Storage.sqliteInMemory()
    lazy var container: DataContainer = {
        try! DataContainer.load(
            storages: storage,
            dataModel: DataModel(
                name: "DATAMODEL",
                concrete: [
                    ParentEntity(), TestEntity()
                ]))
    }()
    
    func createFetchBuilder<T: FetchBuilder<TestEntity>>() -> T {
        T(config: .init(), context: container.querySessionContext())
    }
    
    func createParentEntities(amount: Int) {
        container.startSession().sync {
            let objects = (0..<amount).map { _ in ["parentValue": true] }
            _ = try! $0
                .insert(for: ParentEntity.self)
                .object(contentsOf: objects)
                .exec()
        }
    }
    
    func createTestEntities(amount: Int) {
        container.startSession().sync {
            let objects = (0..<amount).map { ["integerValue": $0] }
            _ = try! $0
                .insert(for: TestEntity.self)
                .object(contentsOf: objects)
                .exec()
        }
    }
    
    func destroyStorage() throws {
        try container.destroyStorages()
    }
    
    func rebuildStorage() throws {
        container = try DataContainer.load(
            storages: storage,
            dataModel: DataModel(name: "DATAMODEL", concrete: [TestEntity()]))
    }
    
    deinit {
        try! container.destroyStorages()
    }
}

class FetchBuilderRequestTests: XCTestCase {
    typealias TestEntity = FetchBuilderTestSuite.TestEntity
    let suite = FetchBuilderTestSuite()

    var sut: FetchBuilder<TestEntity>!

    override func setUpWithError() throws {
        sut = suite.createFetchBuilder()
    }
    
    func test_request_limit_shouldUpdateFetchLimit() {
        let request = sut
            .limit(2)
            .config
            .createFetchRequest()
        XCTAssertEqual(request.fetchLimit, 2)
    }
    
    func test_request_offset_shouldUpdateFetchOffset() {
        let request = sut
            .offset(3)
            .config
            .createFetchRequest()
        
        XCTAssertEqual(request.fetchOffset, 3)
    }
    
    func test_request_includesPendingChangesWithoutParameter_includesPendingChangesShouldBeTrue() {
        let request = sut
            .includesPendingChanges()
            .config
            .createFetchRequest()
        
        XCTAssertTrue(request.includesPendingChanges)
    }
    
    func test_request_includesPendingChangesTrue_includesPendingChangesShouldBeTrue() {
        let request = sut
            .includesPendingChanges(true)
            .config
            .createFetchRequest()
        
        XCTAssertTrue(request.includesPendingChanges)
    }
    
    func test_request_includesPendingChangesFalse_includesPendingChangesShouldBeFalse() {
        let request = sut
            .includesPendingChanges(false)
            .config
            .createFetchRequest()
        
        XCTAssertFalse(request.includesPendingChanges)
    }
    
    func test_request_prefetchRelationship_shouldBeInRelationshipKeyPathsForPrefetching() {
        let request = sut
            .prefetch(relationship: \.another)
            .config
            .createFetchRequest()
        
        XCTAssertTrue(request.relationshipKeyPathsForPrefetching?.contains("another") ?? false)
    }
    
    func test_request_sort_shouldUpdateSortDescriptiors() {
        let request = sut
            .sort(\.integerValue, ascending: false, option: .localized)
            .config
            .createFetchRequest()
        
        XCTAssertEqual(request.sortDescriptors?.count ?? 0, 1)
    }
    
    func test_request_sort_shouldFollowingOrder() {
        let request = sut
            .sort(\.integerValue, ascending: false, option: .localized)
            .config
            .createFetchRequest()

        XCTAssertFalse(request.sortDescriptors![0].ascending)
    }
    
    func test_request_sort_keyShouldEqualToPropertyName() {
        let request = sut
            .sort(\.integerValue, ascending: false, option: .localized)
            .config
            .createFetchRequest()
        
        XCTAssertEqual(request.sortDescriptors![0].key, "integerValue")
    }
    
    func test_request_sort_selectorShouldEqualToSelectorFromSorterOption() {
        let request = sut
            .sort(\.integerValue, ascending: false, option: .localized)
            .config
            .createFetchRequest()

        XCTAssertEqual(request.sortDescriptors![0].selector, FetchSorterOption.localized.selector)
    }
    
    func test_request_asFaultsWithNoParameter_updateReturnsObjectsAsFaultsShouldEqualToTrue() {
        let request = sut
            .asFaults()
            .config
            .createFetchRequest()
        
        XCTAssertTrue(request.returnsObjectsAsFaults)
    }
    
    func test_request_asFaultsTrue_updateReturnsObjectsAsFaultsShouldEqualToTrue() {
        let request = sut
            .asFaults(true)
            .config
            .createFetchRequest()
        
        XCTAssertTrue(request.returnsObjectsAsFaults)
    }
    
    func test_request_asFaultsFalse_updateReturnsObjectsAsFaultsShouldEqualToFalse() {
        let request = sut
            .asFaults(false)
            .config
            .createFetchRequest()
        
        XCTAssertFalse(request.returnsObjectsAsFaults)
    }
}

class ObjectProxyBuilderRequestTests: XCTestCase {
    typealias TestEntity = FetchBuilderTestSuite.TestEntity
    let suite = FetchBuilderTestSuite()

    var sut: ObjectProxyFetchBuilder<TestEntity, TestEntity.ReadOnly>!

    override func setUpWithError() throws {
        sut = suite.createFetchBuilder()
    }
    
    func test_request_includesSubentitiesWithoutParameter_includeSubentitiesShouldBeTrue() {
        let request = sut
            .includesSubentities()
            .config
            .createFetchRequest()
        
        XCTAssertTrue(request.includesSubentities)
    }
    
    func test_request_includesSubentitiesTrue_includeSubentitiesShouldBeTrue() {
        let request = sut
            .includesSubentities(true)
            .config
            .createFetchRequest()
        
        XCTAssertTrue(request.includesSubentities)
    }
    
    func test_request_includesSubentitiesFalse_includeSubentitiesShouldBeFalse() {
        let request = sut
            .includesSubentities(false)
            .config
            .createFetchRequest()
        
        XCTAssertFalse(request.includesSubentities)
    }
}

class LazyFetchBuilderRequestTests: XCTestCase {
    typealias TestEntity = FetchBuilderTestSuite.TestEntity
    let suite = FetchBuilderTestSuite()

    var sut: ArrayExecutableFetchBuilder<TestEntity, TestEntity.ReadOnly>!

    override func setUpWithError() throws {
        sut = suite.createFetchBuilder()
    }
    
    func test_request_batch_shouldUpdateFetchBatchSize() {
        let builder = sut.batch(5)
        let request = builder.config.createFetchRequest()
        XCTAssertEqual(request.fetchBatchSize, 5)
    }
    
    func test_request_batch_shouldReturnAllObjects() {
        suite.createTestEntities(amount: 10)
        let builder = sut.lazy().batch(5)
        let count = builder.exec().count
        XCTAssertEqual(count, 10)
    }
    
    func test_request_includesSubentitiesTrue_shouldUpdateFlag() {
        let builder = sut.batch(5)
        let request = builder
            .includesSubentities(true)
            .config
            .createFetchRequest()
        XCTAssertTrue(request.includesSubentities)
    }
    
    func test_request_includesSubentitiesFalse_shouldUpdateFlag() {
        let builder = sut.batch(5)
        let request = builder
            .includesSubentities(false)
            .config
            .createFetchRequest()
        XCTAssertFalse(request.includesSubentities)
    }
}

class FetchBuilderPostPredicateTests: XCTestCase {
    typealias TestEntity = FetchBuilderTestSuite.TestEntity
    let suite = FetchBuilderTestSuite()
    
    var sut: FetchBuilder<TestEntity>!
    
    override func setUp() async throws {
        sut = suite.createFetchBuilder()
    }
    
    func test_predicate_shouldUpdatePostPredicate() {
        let predicate = sut
            .predicate(\TestEntity.integerValue == 1)
            .config
            .postPredicate
        XCTAssertEqual(predicate, \TestEntity.integerValue == 1)
    }
    
    func test_andPredicate_shouldUpdatePostPredicate() {
        let predicate = sut
            .predicate(.true)
            .andPredicate(\TestEntity.integerValue == 1)
            .config
            .postPredicate
        XCTAssertEqual(.true && \TestEntity.integerValue == 1, predicate)
    }
    
    func test_orPredicate_shouldUpdatePostPredicate() {
        let predicate = sut
            .predicate(.true)
            .orPredicate(\TestEntity.integerValue == 1)
            .config
            .postPredicate
        XCTAssertEqual(.true || \TestEntity.integerValue == 1, predicate)
    }
    
    func test_predicate_shouldConstructPredicate() {
        let predicate = sut
            .predicate("integerValue == %d", 1)
            .config
            .postPredicate
        XCTAssertEqual(predicate, \TestEntity.integerValue == 1)
    }
    
    func test_andPredicate_shouldConstructPredicate() {
        let predicate = sut
            .predicate(.true)
            .andPredicate("integerValue == %d", 1)
            .config
            .postPredicate
        XCTAssertEqual(.true && \TestEntity.integerValue == 1, predicate)
    }
    
    func test_orPredicate_shouldConstructPredicate() {
        let predicate = sut
            .predicate(.true)
            .orPredicate("integerValue == %d", 1)
            .config
            .postPredicate
        XCTAssertEqual(.true || \TestEntity.integerValue == 1, predicate)
    }
}

class FetchBuilderCountTests: XCTestCase {
    typealias TestEntity = FetchBuilderTestSuite.TestEntity
    let suite = FetchBuilderTestSuite()
    
    var sut: ReadOnlyFetchBuilder<TestEntity>!
    
    override func setUp() async throws {
        sut = suite.createFetchBuilder()
    }
    
    func test_count_shouldEqualToEntitiesAmountJustCreate() {
        suite.createTestEntities(amount: 10)
        let result = sut.count()
        XCTAssertEqual(10, result)
    }
}

class FetchBuilderExistsTests: XCTestCase {
    typealias TestEntity = FetchBuilderTestSuite.TestEntity
    let suite = FetchBuilderTestSuite()

    var sut: ReadOnlyFetchBuilder<TestEntity>!

    override func setUp() async throws {
        sut = suite.createFetchBuilder()
    }

    func test_exists_shouldReturnTrue() {
        suite.createTestEntities(amount: 1)
        let result = sut.exists()
        XCTAssertTrue(result)
    }

    func test_exists_shouldReturnFalse() {
        let result = sut.exists()
        XCTAssertFalse(result)
    }
}

class FetchBuilderObjectIDsTests: XCTestCase {
    typealias TestEntity = FetchBuilderTestSuite.TestEntity
    let suite = FetchBuilderTestSuite()

    var sut: ReadOnlyFetchBuilder<TestEntity>!

    override func setUp() async throws {
        sut = suite.createFetchBuilder()
    }

    func test_objectIDs_shouldReturnAllObjectIDs() {
        suite.createTestEntities(amount: 10)
        let result = sut.objectIDs()
        XCTAssertEqual(10, result.count)
    }
}

class FetchBuilderExecutionTests: XCTestCase {
    typealias TestEntity = FetchBuilderTestSuite.TestEntity
    typealias ParentEntity = FetchBuilderTestSuite.ParentEntity
    let suite = FetchBuilderTestSuite()

    var container: DataContainer { suite.container }

    override func setUp() async throws {
        try container.rebuildStorages()
    }
    
    override func tearDown() async throws {
        try container.destroyStorages()
    }

    func test_limit_shouldLimitReturnedObjects() {
        suite.createTestEntities(amount: 10)
        let results = container
            .fetch(for: TestEntity.self)
            .limit(2)
            .exec()
        XCTAssertEqual(results.count, 2)
    }
    
    func test_offset_shouldSkipGivenAmountOfEntities() {
        suite.createTestEntities(amount: 10)
        let results = container
            .fetch(for: TestEntity.self)
            .offset(5)
            .exec()
        XCTAssertEqual(results.count, 5)
    }
    
    func test_includesSubentitiesTrue_shouldReturnAllEntities() {
        suite.createParentEntities(amount: 5)
        suite.createTestEntities(amount: 5)
        container.startSession().sync { context in
            let results = context
                .fetch(for: ParentEntity.self)
                .includesSubentities(true)
                .exec()
            XCTAssertEqual(results.count, 10)
        }
    }
    
    func test_includesSubentitiesFalse_shouldReturnParentEntities() {
        suite.createParentEntities(amount: 5)
        suite.createTestEntities(amount: 5)
        let results = container
            .fetch(for: ParentEntity.self)
            .includesSubentities(false)
            .exec()
        XCTAssertEqual(results.count, 5)
    }
    
    func test_includesPendingChangesTrue_shouldReturnUncommittedEntities() {
        container.startSession().sync { context in
            _ = context.create(entity: TestEntity.self)
            let count = context
                .fetch(for: ParentEntity.self)
                .includesPendingChanges()
                .count()
            XCTAssertEqual(count, 1)
        }
    }
    
    func test_includesPendingChangesFalse_shouldNotReturnUncommittedEntities() {
        container.startSession().sync { context in
            _ = context.create(entity: TestEntity.self)
            let count = context
                .fetch(for: ParentEntity.self)
                .includesPendingChanges(false)
                .count()
            XCTAssertEqual(count, 0)
        }
    }
    
    func test_sortAscending_shouldOrderedByIntegerValueWithAscendingOrder() {
        suite.createTestEntities(amount: 3)
        let values = container
            .fetch(for: TestEntity.self)
            .sort(\.integerValue, ascending: true)
            .exec()
            .map(\.integerValue)
        XCTAssertEqual(values, [0,1,2])
    }
    
    func test_sortOptionCaseInsensitive_shouldIgnoreCase() throws {
        try container.startSession().sync { context in
            for value in ["a", "B", "c", "D"] {
                let object = context.create(entity: TestEntity.self)
                object.stringValue = value
            }
            try context.commit()
            let results = context
                .fetch(for: TestEntity.self)
                .sort(\.stringValue, ascending: true, option: .caseInsensitive)
                .asDictionary()
                .select(\.stringValue)
                .exec() as NSArray
            XCTAssertTrue(results.isEqual(to: [
                ["stringValue": "a"],
                ["stringValue": "B"],
                ["stringValue": "c"],
                ["stringValue": "D"],
            ]))
        }
    }
    
    func test_sortDescending_shouldOrderedByIntegerValueWithDescendingOrder() {
        suite.createTestEntities(amount: 3)
        let values = container
            .fetch(for: TestEntity.self)
            .sort(\.integerValue, ascending: false)
            .exec()
            .map(\.integerValue)
        XCTAssertEqual(values, [2,1,0])
    }
    
    func test_exists_shouldReturnTrueIfAnyEntityExists() {
        suite.createTestEntities(amount: 1)
        let result = container
            .fetch(for: TestEntity.self)
            .exists()
        XCTAssertTrue(result)
    }
    
    func test_exists_shouldReturnFalseIfNoEntityExists() {
        let result = container
            .fetch(for: TestEntity.self)
            .exists()
        XCTAssertFalse(result)
    }
    
    func test_objectIDs_shouldReturnCorrespondingAmountOfObjectIDs() {
        suite.createTestEntities(amount: 5)
        let objectIDs = container
            .fetch(for: TestEntity.self)
            .objectIDs()
        XCTAssertEqual(objectIDs.count, 5)
    }
    
    func test_predicate_shouldFilterResults() {
        suite.createTestEntities(amount: 5)
        let count = container
            .fetch(for: TestEntity.self)
            .predicate(\.integerValue > 3)
            .exec()
            .count
        XCTAssertEqual(1, count)
    }
    
    func test_andPredicate_shouldCompoundAndPredicate() {
        suite.createTestEntities(amount: 5)
        let count = container
            .fetch(for: TestEntity.self)
            .predicate(\.integerValue < 3)
            .andPredicate(\.integerValue > 0)
            .exec()
            .count
        XCTAssertEqual(2, count)
    }
    
    func test_orPredicate_shouldCompoundOrPredicate() {
        suite.createTestEntities(amount: 5)
        let count = container
            .fetch(for: TestEntity.self)
            .predicate(\.integerValue > 2)
            .orPredicate(\.integerValue < 1)
            .exec()
            .count
        XCTAssertEqual(3, count)
    }
}
