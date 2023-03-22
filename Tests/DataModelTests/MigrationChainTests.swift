//
//  MigrationChainTests.swift
//  
//
//  Created by EZOU on 2023/2/28.
//

import CoreData
import XCTest

@testable import Crush

class MigrationChainTests: XCTestCase {
    class C: Entity {
        let name = Value.String("name")
    }

    class A: C {
        let orderedB = Relation.ToOrdered<B>("orderedB")
        let unorderedB = Relation.ToMany<B>("unorderedB")
    }

    class B: Entity {
        @Inverse(\.orderedB)
        var a = Relation.ToOne<A>("a")
    }

    var migrationChain: MigrationChain {
        MigrationChain {
            ModelMigration("V0") {
                AddEntity("A", configurations: ["configuration"]) {
                    AddAttribute("name", type: String.self, isOptional: true)
                    AddAttribute("integer", type: Int.self)
                }
                AddEntity("D") {
                    AddAttribute("value", type: Bool.self)
                }
            }
            ModelMigration("V1") {
                UpdateEntity("A", configurations: ["configuration"]) {
                    RemoveAttribute("integer")
                    AddRelationship("orderedB", toMany: "B", inverse: "a", isOptional: true, isOrdered: true)
                    AddRelationship("unorderedB", toMany: "B", isOptional: true)
                }
                RemoveEntity("D")
                AddEntity("B") {
                    AddRelationship("a", toOne: "A", inverse: "orderedB", isOptional: true)
                }
            }
        }
    }

    var dataModel: DataModel {
        class V1: EntityMap {
            @Abstract(inheritance: .multiTable)
            var c = C()

            @Configuration("configuration")
            var a = A()

            var b = B()
        }
        return DataModel(entityMap: V1())
    }

    func test_configurations_modelConfigurationsShouldEqualToMigrationModel() throws {
        let modelFromMigrationChain = try migrationChain.managedObjectModels().last!
        let model = dataModel.managedObjectModel
        XCTAssertEqual(Set(model.configurations), Set(modelFromMigrationChain.configurations))
    }

    func test_dataModel_shouldBeCompatibleToMigrationChain() throws {
        let modelFromMigrationChain = try migrationChain.managedObjectModels().last!
        let model = dataModel.managedObjectModel
        XCTAssertTrue(model.isCompactible(with: modelFromMigrationChain))
    }
}
