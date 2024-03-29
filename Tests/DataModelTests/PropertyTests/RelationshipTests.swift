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
        @UnidirectionalInverse
        @Inverse(\.toMany_A)
        var toOne_B = Relation.ToOne<Entity_B>("toOne_B")

        @MaxCount(10)
        @MinCount(2)
        var toOrdered_B = Relation.ToOrdered<Entity_B>("toOrdered_B")

        @Optional
        var toOne_B_noInverse = Relation.ToOne("toOne_B_noInverse")
    }

    class Entity_B: Entity {
        @DeleteRule(.noActionDeleteRule)
        var toMany_A = Relation.ToMany<Entity_A>("toMany_A")

        @Optional
        @Inverse(\.toOrdered_B)
        var toOne_A = Relation.ToOne<Entity_A>("toOne_A")
    }

    private static var dataModel: DataModel! = DataModel(
        name: "RelationshipTest",
        concrete: [
            Entity_A(), Entity_B()
        ])

    public lazy var dataModel: DataModel = {
        Self.dataModel
    }()

    public override class func setUp() {
        _ = NSPersistentStoreCoordinator(managedObjectModel: dataModel.managedObjectModel)
    }

    public override class func tearDown() {
        dataModel = nil
    }

    func test_optionalRelationship_isOptionalShouldBeTrue() {
        let sut = Entity_A.entity()
            .relationshipsByName["toOrdered_B"]!
        XCTAssertTrue(sut.isOptional)
    }

    func test_defaultDeleteRule_shouldBeNullify() {
        let sut = Entity_A.entity()
            .relationshipsByName["toOrdered_B"]!
        XCTAssertEqual(sut.deleteRule, .nullifyDeleteRule)
    }

    func test_deleteRule_shouldBeNoAction() {
        let sut = Entity_B.entity()
            .relationshipsByName["toMany_A"]!
        XCTAssertEqual(sut.deleteRule, .noActionDeleteRule)
    }

    func test_minCount_shouldBe2() {
        let sut = Entity_A.entity()
            .relationshipsByName["toOrdered_B"]!
        XCTAssertEqual(sut.minCount, 2)
    }

    func test_maxCount_shouldBe10() {
        let sut = Entity_A.entity()
            .relationshipsByName["toOrdered_B"]!
        XCTAssertEqual(sut.maxCount, 10)
    }

    func test_inverse_shouldBeUniDirectional() {
        let sut = Entity_B.entity()
            .relationshipsByName["toMany_A"]!
        XCTAssertNil(sut.inverseRelationship)
    }

    func test_inverse_shouldBeBiDirectional() {
        let sut = Entity_B.entity()
            .relationshipsByName["toOne_A"]!
        let target = Entity_A.entity()
            .relationshipsByName["toOrdered_B"]!
        XCTAssertIdentical(sut.inverseRelationship, target)
    }

    func test_inverse_shouldBeNil() {
        let sut = Entity_A.entity()
            .relationshipsByName["toOne_B_noInverse"]!
        XCTAssertNil(sut.inverseRelationship)
    }

    func test_mapping_shouldBeToOne() {
        let sut = Entity_A.entity()
            .relationshipsByName["toOne_B_noInverse"]!
        XCTAssertFalse(sut.isToMany)
    }

    func test_mapping_shouldBeToMany() {
        let sut = Entity_B.entity()
            .relationshipsByName["toMany_A"]!
        XCTAssertTrue(sut.isToMany)
    }

    func test_mapping_shouldBeToOrdered() {
        let sut = Entity_A.entity()
            .relationshipsByName["toOrdered_B"]!
        XCTAssertTrue(sut.isToMany)
        XCTAssertTrue(sut.isOrdered)
    }

    func test_destination_shouldBeSetProperly() {
        let sut = Entity_A.entity()
            .relationshipsByName["toOrdered_B"]!
        let target = Entity_B.entity()
        XCTAssertEqual(sut.destinationEntity, target)
    }
}
