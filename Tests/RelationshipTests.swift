//
//  RelationshipTests.swift
//  
//
//  Created by ezou on 2021/10/9.
//

import CoreData
import XCTest

@testable import Crush

public class RelationshipTests: XCTestCase {

    class Entity_A: Entity {
        @Required
        var toOne_B = Relation.ToOne<Entity_B>("toOne_B", inverse: \.toMany_A)

        @MaxCount(10)
        @MinCount(2)
        var toOrderedMany_B = Relation.ToOrdered<Entity_B>("toOrderedMany_B")
    }

    class Entity_B: Entity {
        @DeleteRule(.noActionDeleteRule)
        var toMany_A = Relation.ToMany<Entity_A>("toMany_A")
    }

    private static var dataModel = DataModel("RelationshipTest") {
        EntityDescription<Entity_A>(inheritance: .concrete)
        EntityDescription<Entity_B>(inheritance: .concrete)
    }

    public lazy var dataModel: DataModel = {
        Self.dataModel
    }()

    public override class func setUp() {
        _ = NSPersistentStoreCoordinator(managedObjectModel: dataModel.managedObjectModel)
    }

    func test_optionalRelationship_isOptionalShouldBeTrue() {
        let sut = Entity_A.entityDescription()
            .relationshipsByName["toOrderedMany_B"]!
        XCTAssertTrue(sut.isOptional)
    }

    func test_defaultDeleteRule_shouldBeNullify() {
        let sut = Entity_A.entityDescription()
            .relationshipsByName["toOrderedMany_B"]!
        XCTAssertEqual(sut.deleteRule, .nullifyDeleteRule)
    }

    func test_deleteRule_shouldBeNoAction() {
        let sut = Entity_B.entityDescription()
            .relationshipsByName["toMany_A"]!
        XCTAssertEqual(sut.deleteRule, .noActionDeleteRule)
    }

    func test_minCount_shouldBe2() {
        let sut = Entity_A.entityDescription()
            .relationshipsByName["toOrderedMany_B"]!
        XCTAssertEqual(sut.minCount, 2)
    }

    func test_maxCount_shouldBe10() {
        let sut = Entity_A.entityDescription()
            .relationshipsByName["toOrderedMany_B"]!
        XCTAssertEqual(sut.maxCount, 10)
    }
}
