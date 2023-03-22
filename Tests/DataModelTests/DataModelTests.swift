//
//  DataModelTests.swift
//  Tests
//
//  Created by 沈昱佐 on 2020/3/16.
//  Copyright © 2020 ezoushen. All rights reserved.
//

import CoreData
import XCTest

@testable import Crush

class DataModelTests: XCTestCase {
    class AbstractEntity: Entity { }
    class EmbeddedEntity: Entity { }
    class ConcreteEntity_A: AbstractEntity { }
    class ConcreteEntity_B: EmbeddedEntity { }

    let sut: DataModel = {
        class V1: EntityMap {
            override var name: String {
                "Model"
            }

            @Abstract(inheritance: .multiTable)
            var embedded = EmbeddedEntity()

            @Configuration("A_CONF")
            @Abstract(inheritance: .singleTable)
            var abstract = AbstractEntity()

            @Concrete
            var concreteA = ConcreteEntity_A()

            var concreteB = ConcreteEntity_B()
        }
        return DataModel(entityMap: V1())
    }()

    func test_configuration_shouldBeSet() {
        let model = sut.managedObjectModel
        let entities = model.entities(forConfigurationName: "A_CONF") ?? []
        XCTAssertEqual(model.configurations, ["A_CONF"])
        XCTAssertEqual(entities.map(\.name), ["AbstractEntity"])
    }

    func test_name_shouldBeSet() {
        XCTAssertEqual(sut.name, "Model")
    }

    func test_shouldBeCompatibleToModelContainingSameEntities() {
        let target: DataModel = {
            DataModel(
                name: "Model",
                abstract: [
                    Configuration(wrappedValue: AbstractEntity(), "A_CONF")
                ],
                embedded: [
                    EmbeddedEntity()
                ],
                concrete: [
                    ConcreteEntity_A(), ConcreteEntity_B()
                ])
        }()
        XCTAssertTrue(sut.managedObjectModel.isCompactible(with: target.managedObjectModel))
    }

    func test_hashValueEffedctedByAbstractEntities_shouldNotBeEqual() {
        let target: DataModel = {
            DataModel(
                name: "Model",
                embedded: [
                    EmbeddedEntity()
                ],
                concrete: [
                    ConcreteEntity_B()
                ])
        }()
        XCTAssertNotEqual(sut.uniqueIdentifier, target.uniqueIdentifier)
    }

    func test_hashValueEffedctedByEmbeddedEntities_shouldNotBeEqual() {
        let target: DataModel = {
            DataModel(
                name: "Model",
                abstract: [
                    AbstractEntity()
                ],
                concrete: [
                    ConcreteEntity_A()
                ])
        }()
        XCTAssertNotEqual(sut.uniqueIdentifier, target.uniqueIdentifier)
    }

    func test_hashValueEffedctedByConcreteEntities_shouldNotBeEqual() {
        let target: DataModel = {
            DataModel(
                name: "Model",
                abstract: [
                    AbstractEntity()
                ],
                embedded: [
                    EmbeddedEntity()
                ], concrete: [
                ])
        }()
        XCTAssertNotEqual(sut.uniqueIdentifier, target.uniqueIdentifier)
    }

    func test_hashValueEffedctedByName_shouldNotBeEqual() {
        let target: DataModel = {
            DataModel(
                name: "Model2",
                abstract: [
                    AbstractEntity()
                ],
                embedded: [
                    EmbeddedEntity()
                ], concrete: [
                    ConcreteEntity_A(), ConcreteEntity_B()
                ])
        }()
        XCTAssertNotEqual(sut.uniqueIdentifier, target.uniqueIdentifier)
    }

    func test_managedObjectModelEntitiesCount_shouldEqualToNumberOfAllEntitiesMinusEmbeddedEntities() {
        XCTAssertEqual(sut.managedObjectModel.entities.count, 3)
    }

    func test_managedObjectModelVersionIdentifiers_shouldEqualToModelName() {
        XCTAssertEqual(sut.managedObjectModel.versionIdentifiers, [sut.name])
    }
}
