//
//  RelationshipMigrationTests.swift
//  
//
//  Created by ezou on 2021/10/25.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

class AddRelationshipTests: XCTestCase {
    func test_createProperty_shouldBeRelationshipDescription() {
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toOne", toOne: "ENTITY")
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertTrue(description is NSRelationshipDescription)
    }

    func test_createProperty_shouldSetName() {
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toOne", toOne: "ENTITY")
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertEqual(description.name, sut.name)
    }

    func test_createProperty_shouldSetIsOptional() {
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toOne", toOne: "ENTITY", isOptional: false)
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertEqual(description.isOptional, sut.isOptional)
    }

    func test_createProperty_shouldSetDeleteRule() {
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toOne", toOne: "ENTITY", deleteRule: .cascadeDeleteRule)
        let description = sut.createProperty(callbackStore: &store) as! NSRelationshipDescription
        XCTAssertEqual(description.deleteRule, .cascadeDeleteRule)
    }

    func test_createProperty_shouldBeToOneRelationship() {
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toOne", toOne: "ENTITY")
        let description = sut.createProperty(callbackStore: &store) as! NSRelationshipDescription
        XCTAssertFalse(description.isToMany)
    }

    func test_createProperty_shouldBeToManyRelationship() {
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toMany", toMany: "ENTITY")
        let description = sut.createProperty(callbackStore: &store) as! NSRelationshipDescription
        XCTAssertTrue(description.isToMany)
    }

    func test_createProperty_shouldSetMinCount() {
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toMany", toMany: "ENTITY", minCount: 2)
        let description = sut.createProperty(callbackStore: &store) as! NSRelationshipDescription
        XCTAssertEqual(description.minCount, 2)
    }

    func test_createProperty_shouldSetMaxCount() {
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toMany", toMany: "ENTITY", maxCount: 2)
        let description = sut.createProperty(callbackStore: &store) as! NSRelationshipDescription
        XCTAssertEqual(description.maxCount, sut.maxCount)
    }

    func test_createProperty_shouldSetIdOrdered() {
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toMany", toMany: "ENTITY", isOrdered: true)
        let description = sut.createProperty(callbackStore: &store) as! NSRelationshipDescription
        XCTAssertTrue(description.isOrdered)
    }

    func test_createProperty_shouldSetIsTransient() {
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toMany", toMany: "ENTITY", isTransient: true)
        let description = sut.createProperty(callbackStore: &store) as! NSRelationshipDescription
        XCTAssertTrue(description.isTransient)
    }

    func test_createProperty_shouldSetInverse() throws {
        let inverse = NSRelationshipDescription()
        inverse.name = "inverse"
        let entityDescription = NSEntityDescription()
        entityDescription.name = "ENTITY"
        entityDescription.properties = [inverse]
        var store = [EntityMigrationCallback]()
        let sut = AddRelationship("toMany", toMany: "ENTITY", inverse: "inverse")
        let description = sut.createProperty(callbackStore: &store) as! NSRelationshipDescription
        try store.forEach { try $0(["ENTITY": entityDescription] )}
        XCTAssertEqual(description.inverseRelationship, inverse)
    }

    func test_createPropertyMapping_shouldSetName() {
        let sut = AddRelationship("toMany", toMany: "ENTITY", inverse: "inverse")
        let mapping = sut.createPropertyMapping(from: nil, to: nil, of: NSEntityDescription())
        XCTAssertEqual(sut.name, mapping?.name)
    }
}

class UpdateRelationshipTests: XCTestCase {

    var store: [EntityMigrationCallback] = []
    var relationship: NSRelationshipDescription!

    override func setUp() {
        relationship = NSRelationshipDescription()
    }

    override func tearDown() {
        store = []
    }

    func test_migrateRelationship_shouldThrow() {
        let sut = UpdateRelationship("name", name: "NAME")
        XCTAssertThrowsError(try sut.migrateRelationship(nil, callbackStore: &store))
    }

    func test_migrateRelationship_shouldUpdateName() throws {
        let sut = UpdateRelationship("name", name: "NAME")
        let description = try sut.migrateRelationship(relationship, callbackStore: &store)
        XCTAssertEqual(description?.name, sut.name)
    }

    func test_migrateRelationship_shouldUpdateIsOptional() throws {
        let sut = UpdateRelationship("name", isOptional: false)
        let description = try sut.migrateRelationship(relationship, callbackStore: &store)
        XCTAssertFalse(description?.isOptional ?? true)
    }

    func test_migrateRelationship_shouldupdateDeleteRule() throws {
        let sut = UpdateRelationship("name", deleteRule: .cascadeDeleteRule)
        let description = try sut.migrateRelationship(relationship, callbackStore: &store)
        XCTAssertEqual(description?.deleteRule, .cascadeDeleteRule)
    }

    func test_migrateRelationship_shouldUpdateIsTransient() throws {
        let sut = UpdateRelationship("name", isTransient: true)
        let description = try sut.migrateRelationship(relationship, callbackStore: &store)
        XCTAssertEqual(description?.isTransient, true)
    }

    func test_migrateRelationship_shouldUpdateMaxCount() throws {
        let sut = UpdateRelationship("name", maxCount: 10)
        let description = try sut.migrateRelationship(relationship, callbackStore: &store)
        XCTAssertEqual(description?.maxCount, 10)
    }

    func test_migrateRelationship_shouldUpdateMinCount() throws {
        let sut = UpdateRelationship("name", minCount: 2)
        let description = try sut.migrateRelationship(relationship, callbackStore: &store)
        XCTAssertEqual(description?.minCount, 2)
    }

    func test_migrateRelationship_shouldUpdateDestination() throws {
        let sut = UpdateRelationship("name", toMany: "ENTITY")
        let description = try sut.migrateRelationship(relationship, callbackStore: &store)
        let entity = NSEntityDescription()
        entity.name = "ENTITY"
        let entitiesByName = [ "ENTITY": entity ]
        try store.forEach { try $0(entitiesByName) }
        XCTAssertEqual(description?.destinationEntity, entity)
    }

    func test_migrateRelationship_shouldThrowErrorWhileDestinationNotFound() throws {
        let sut = UpdateRelationship("name", toMany: "ENTITY")
        _ = try sut.migrateRelationship(relationship, callbackStore: &store)
        let entitiesByName = [String: NSEntityDescription]()
        XCTAssertThrowsError(try store.forEach { try $0(entitiesByName) })
    }

    func test_migrateRelationship_shouldUpdateInverse() throws {
        let inverse = NSRelationshipDescription()
        inverse.name = "inverse"
        let entity = NSEntityDescription()
        entity.name = "ENTITY"
        entity.properties = [inverse]
        inverse.destinationEntity = entity
        relationship.destinationEntity = entity
        let sut = UpdateRelationship("name", inverse: "inverse")
        let description = try sut.migrateRelationship(relationship, callbackStore: &store)
        let entitiesByName = [ "ENTITY": entity ]
        try store.forEach { try $0(entitiesByName) }
        XCTAssertEqual(description?.inverseRelationship, inverse)
    }

    func test_migrateRelationship_shouldThrowErrorWhileDestinationNotSet() throws {
        let inverse = NSRelationshipDescription()
        inverse.name = "inverse"
        let entity = NSEntityDescription()
        entity.name = "ENTITY"
        entity.properties = [inverse]
        inverse.destinationEntity = entity
        let sut = UpdateRelationship("name", inverse: "inverse")
        _ = try sut.migrateRelationship(relationship, callbackStore: &store)
        let entitiesByName = [ "ENTITY": entity ]
        XCTAssertThrowsError(try store.forEach { try $0(entitiesByName) })
    }

    func test_migrateRelationship_shouldThrowErrorWhileInverseNotFound() throws {
        let inverse = NSRelationshipDescription()
        inverse.name = "anotherInverse"
        let entity = NSEntityDescription()
        entity.name = "ENTITY"
        entity.properties = [inverse]
        inverse.destinationEntity = entity
        relationship.destinationEntity = entity
        let sut = UpdateRelationship("name", inverse: "inverse")
        _ = try sut.migrateRelationship(relationship, callbackStore: &store)
        let entitiesByName = [ "ENTITY": entity ]
        XCTAssertThrowsError(try store.forEach { try $0(entitiesByName) })
    }

    func test_createPropertyMapping_shouldThrowIfSourceOrDestinationNotSpecified() {
        let sut = UpdateRelationship("name", name: "newName")
        XCTAssertThrowsError(try sut.createPropertyMapping(from: nil, to: nil, of: NSEntityDescription()))
    }

    func test_createPropertyMapping_shouldSetName() throws {
        let sut = UpdateRelationship("name", name: "newName")
        let source = NSRelationshipDescription()
        source.name = sut.originPropertyName!
        let desitnation = NSRelationshipDescription()
        desitnation.name = sut.name!
        let entity = NSEntityDescription()
        entity.name = "name"
        entity.properties = [source]
        let mapping = try sut.createPropertyMapping(from: source, to: desitnation, of: entity)
        XCTAssertEqual(mapping?.name, sut.name)
    }

    func test_createPropertyMapping_shouldSetExpression() throws {
        let sut = UpdateRelationship("name", name: "newName")
        let source = NSRelationshipDescription()
        source.name = sut.originPropertyName!
        let desitnation = NSRelationshipDescription()
        desitnation.name = sut.name!
        let entity = NSEntityDescription()
        entity.name = "name"
        entity.properties = [source]
        let mapping = try sut.createPropertyMapping(from: source, to: desitnation, of: entity)
        XCTAssertEqual(mapping?.valueExpression, .relationshipMapping(from: sut.originKeyPath, to: sut.name!))
    }

    func test_originName_shouldSplitByDot() {
        let sut = UpdateRelationship("name.value", name: "newName")
        XCTAssertEqual(sut.originPropertyName, "name")
    }
}
