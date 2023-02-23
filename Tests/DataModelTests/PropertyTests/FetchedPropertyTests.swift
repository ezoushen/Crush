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
        var value = Value.Int16("value")
        var feteched = Fetched<TestEntity>("fetched") { $0.where(\.value == 1) }
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
            $0.where(\.value == 1)
        }
        let fetchBuilder = FetchBuilder<TestEntity>(
            config: .init(), context: DummyContext())
        let request = configuration(fetchBuilder).config.createStoreRequest()
        let description = model.managedObjectModel
            .entitiesByName["TestEntity"]?
            .propertiesByName["fetched"] as! NSFetchedPropertyDescription
        XCTAssertEqual(
            description.fetchRequest, request)
    }
}
