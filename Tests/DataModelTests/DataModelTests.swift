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

class C: Entity {
    let name = Value.String("name")
}

class A: C {
    let orderedList = Relation.ToOrdered<B>("orderedList")
    let unorderedList = Relation.ToMany<B>("unorderedList")
}

class B: Entity {
    @Inverse(\A.orderedList)
    var owner = Relation.ToOne<A>("owner")
}

class Entity_Root: Entity {
    let attribute_optional = Value.Bool("optional_attribute")
}

class Entity_1: Entity {
    @Required
    var attribute_required = Value.String("required_attribute")

    @Required
    var attribute_string = Value.String("string_value")

    @Required
    var atrribute_integer16 = Value.Int16("attribute_integer16")

    @Required
    var atrribute_integer32 = Value.Int16("attribute_integer32")

    @Required
    var atrribute_integer64 = Value.Int16("attribute_integer64")
}

extension DataModel {
    static var v_1: DataModel {
        DataModel(
            name: "V1",
            embedded: [
                C()
            ],
            concrete: [
                A(), B()
            ]
        )
    }
}

extension MigrationPolicy {
    static func chain() -> MigrationPolicy {
        .chain(MigrationChain {
            ModelMigration("V1") {
                AddEntity("A") {
                    AddAttribute("name", type: String.self, isOptional: true)
                    AddRelationship("orderedList", toMany: "B", inverse: "owner", isOptional: true, isOrdered: true)
                    AddRelationship("unorderedList", toMany: "B", isOptional: true)
                }
                AddEntity("B") {
                    AddRelationship("owner", toOne: "A", inverse: "orderedList", isOptional: true)
                }
            }
        })
    }
}

class DataModelTests: XCTestCase {
    class AbstractEntity: Entity { }
    class EmbeddedEntity: Entity { }
    class ConcreteEntity_A: AbstractEntity { }
    class ConcreteEntity_B: EmbeddedEntity { }

    let sut: DataModel = {
        DataModel(
            name: "Model",
            abstract: [
                AbstractEntity()
            ],
            embedded: [
                EmbeddedEntity()
            ],
            concrete: [
                ConcreteEntity_A(), ConcreteEntity_B()
            ])
    }()

    func test_name_shouldBeSet() {
        XCTAssertEqual(sut.name, "Model")
    }

    func test_hashValueEffectedByAllEntities_shouldBeEqual() {
        let target: DataModel = {
            DataModel(
                name: "Model",
                abstract: [
                    AbstractEntity()
                ],
                embedded: [
                    EmbeddedEntity()
                ],
                concrete: [
                    ConcreteEntity_A(), ConcreteEntity_B()
                ])
        }()
        XCTAssertEqual(sut.uniqueIdentifier, target.uniqueIdentifier)
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
