//
//  FetchedPropertyTests.swift
//  
//
//  Created by ezou on 2021/10/22.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

class FetchedPropertyTests: XCTestCase {
    class TestEntity: Entity {
        var int16value = Value.Int16("int16value")
        var feteched = Fetched<TestEntity>("fetched") {
            $0.where(\.int16value == FetchSource.int16value)
        }
    }

    static let model = DataModel(name: "NAME", concrete: [TestEntity()])

    let entity = TestEntity()
    let model = FetchedPropertyTests.model

    override class func setUp() {
        _ = NSPersistentStoreCoordinator(managedObjectModel: model.managedObjectModel)
    }

    func test_descriptionName_shouldBeName() {
        let sut = entity.feteched
        let description = sut.createPropertyDescription()
        XCTAssertEqual(description.name, sut.name)
    }

    func test_descriptionFetchedRequest_shouldNotBeNil() {
        let description = model.managedObjectModel
            .entitiesByName["TestEntity"]?
            .propertiesByName["fetched"] as! NSFetchedPropertyDescription
        XCTAssertNotNil(description.fetchRequest)
    }

    func test_descriptionFetchRequest_shouldBeCondfigured() {
        let configuration: Fetched<TestEntity>.Configuration = {
            $0.where(\.int16value == FetchSource.int16value)
        }
        let fetchBuilder = FetchBuilder<TestEntity>(config: .init(), context: .dummy())
        let request = configuration(fetchBuilder).config.createStoreRequest()
        let description = model.managedObjectModel
            .entitiesByName["TestEntity"]?
            .propertiesByName["fetched"] as! NSFetchedPropertyDescription
        XCTAssertEqual(
            description.fetchRequest, request)
    }
    
    func test_fetchedInDataContainer_shouldReturnEntities() throws {
        let container = try DataContainer.load(
            storages: .sqliteInMemory(),
            dataModel: FetchedPropertyTests.model)
        let entity: TestEntity.ReadOnly = try container.startSession().sync {
            let entity = $0.create(entity: TestEntity.self)
            entity.int16value = 1
            try $0.commit()
            return entity
        }
        let fetched = entity.feteched
        XCTAssertEqual(fetched.count, 1)
    }
}
