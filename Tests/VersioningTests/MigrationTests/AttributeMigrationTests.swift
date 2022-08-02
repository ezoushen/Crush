//
//  AttributeMigrationTests.swift
//  
//
//  Created by ezou on 2021/10/23.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

class AddAttributeTests: XCTestCase {
    let sut = AddAttribute("name", type: String.self, isOptional: false, isTransient: true)
    
    func test_createProperty_shouldSetName() {
        var store: [EntityMigrationCallback] = []
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertEqual(description.name, sut.name)
    }
    
    func test_createProperty_shouldSetIsOptional() {
        var store: [EntityMigrationCallback] = []
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertEqual(description.isOptional, sut.isOptional)
    }
    
    func test_createProperty_shouldSetIsTransient() {
        var store: [EntityMigrationCallback] = []
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertEqual(description.isTransient, sut.isTransient)
    }
    
    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    func test_createProperty_shouldBeDerived() {
        let sut = AddAttribute("name", type: String.self, isOptional: false, derivedExpression: NSExpression(format: "another"))
        var store: [EntityMigrationCallback] = []
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertTrue(description is NSDerivedAttributeDescription)
    }

    func test_createProperty_shouldSetDefaultValue() {
        var store: [EntityMigrationCallback] = []
        let description = sut.default("123").createProperty(callbackStore: &store) as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? String, "123")
    }
    
    func test_createProperty_shouldSetVersionHashModifier() {
        var store: [EntityMigrationCallback] = []
        let description = sut.versionHashModifier("MODIFIER").createProperty(callbackStore: &store) as! NSAttributeDescription
        XCTAssertEqual(description.versionHashModifier, "MODIFIER")
    }
    
    func test_createPropertyMapping_shouldSetName() {
        let mapping = sut.createPropertyMapping(from: nil, to: nil, of: NSEntityDescription())
        XCTAssertEqual(mapping?.name, sut.name)
    }

    func test_createPropertyMapping_shouldReadDefaultValueFromModel() {
        let mapping = sut.createPropertyMapping(from: nil, to: nil, of: NSEntityDescription())
        XCTAssertEqual(mapping?.valueExpression, .addAttribute(name: sut.name!, customValue: false))
    }

    func test_createPropertyMapping_shouldReadInjectedDefaultValue() {
        let mapping = sut
            .valueForExistingObject { _ in nil }
            .createPropertyMapping(from: nil, to: nil, of: NSEntityDescription())
        XCTAssertEqual(mapping?.valueExpression, .addAttribute(name: sut.name!, customValue: true))
    }
}

class UpdateAttributeTests: XCTestCase {
    func test_migrateAttribute_shouldUpdateName() throws {
        var store: [EntityMigrationCallback] = []
        let sut = UpdateAttribute("originName", name: "newName")
        var description = NSAttributeDescription()
        description.name = "originName"
        description = try sut.migrateAttribute(description, callbackStore: &store)!
        XCTAssertEqual(description.name, sut.name)
    }

    func test_migrateAttribute_shouldUpdateIsOptional() throws {
        var store: [EntityMigrationCallback] = []
        let sut = UpdateAttribute("originName", isOptional: false)
        var description = NSAttributeDescription()
        description.name = "originName"
        description = try sut.migrateAttribute(description, callbackStore: &store)!
        XCTAssertFalse(description.isOptional)
    }

    func test_migrateAttribute_shouldUpdateIsTransient() throws {
        var store: [EntityMigrationCallback] = []
        let sut = UpdateAttribute("originName", isTransient: true)
        var description = NSAttributeDescription()
        description.name = "originName"
        description = try sut.migrateAttribute(description, callbackStore: &store)!
        XCTAssertTrue(description.isTransient)
    }

    func test_migrateAttribute_shouldUpdateAttributeType() throws {
        var store: [EntityMigrationCallback] = []
        let sut = UpdateAttribute("originName", type: String.self) {
            guard let value = $0 as? Int else { return nil }
            return String(value)
        }
        var description = NSAttributeDescription()
        description.attributeType = .integer16AttributeType
        description.name = "originName"
        description = try sut.migrateAttribute(description, callbackStore: &store)!
        XCTAssertEqual(description.attributeType, .stringAttributeType)
    }

    func test_migrateAttribute_shouldUpdateDefaultValue() throws {
        var store: [EntityMigrationCallback] = []
        let sut = UpdateAttribute("originName")
            .default("123")
        var description = NSAttributeDescription()
        description.name = "originName"
        description = try sut.migrateAttribute(description, callbackStore: &store)!
        XCTAssertEqual(description.defaultValue as? String, "123")
    }
    
    func test_migrateAttribute_shouldUpdateVersionHashModifier() throws {
        var store: [EntityMigrationCallback] = []
        let sut = UpdateAttribute("originName")
            .versionHashModifier("MODIFIER")
        var description = NSAttributeDescription()
        description.name = "originName"
        description = try sut.migrateAttribute(description, callbackStore: &store)!
        XCTAssertEqual(description.versionHashModifier, "MODIFIER")
    }
    
    func test_migrateAttribute_shouldResetVersionHashModifier() throws {
        var store: [EntityMigrationCallback] = []
        let sut = UpdateAttribute("originName")
            .versionHashModifier(nil)
        var description = NSAttributeDescription()
        description.versionHashModifier = "MODIFIER"
        description.name = "originName"
        description = try sut.migrateAttribute(description, callbackStore: &store)!
        XCTAssertEqual(description.versionHashModifier, nil)
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    func test_migrateAttribute_shouldUpdateDerivedExpression() throws {
        var store: [EntityMigrationCallback] = []
        let sut = UpdateAttribute("originName", type: Date.self, derivedExpression: NSExpression.dateNow())
        var description = NSAttributeDescription()
        description.name = "originName"
        description = try sut.migrateAttribute(description, callbackStore: &store)!
        XCTAssertTrue(description is NSDerivedAttributeDescription)
        XCTAssertEqual((description as? NSDerivedAttributeDescription)?.derivationExpression, .dateNow())
    }

    func test_createPropertyMapping_shouldThrowWithNilDescription() {
        let sut = UpdateAttribute("originName", isTransient: true)
        XCTAssertThrowsError(try sut.createPropertyMapping(from: nil, to: nil, of: NSEntityDescription()))
    }

    func test_createPropertyMapping_shouldSetName() throws {
        let sut = UpdateAttribute("originName", isTransient: true)
        let source = NSAttributeDescription()
        source.name = "originName"
        let destination = NSAttributeDescription()
        destination.name = "originName"
        let mapping = try sut.createPropertyMapping(from: source, to: destination, of: NSEntityDescription())
        XCTAssertEqual(mapping?.name, destination.name)
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    func test_createPropertyMapping_shouldSetAttributeMapping() throws {
        let sut = UpdateAttribute("originName", isOptional: false)
        let source = NSAttributeDescription()
        source.name = "originName"
        let destination = NSAttributeDescription()
        destination.name = "originName"
        let mapping = try sut.createPropertyMapping(from: source, to: destination, of: NSEntityDescription())
        XCTAssertEqual(mapping?.valueExpression, .attributeMapping(from: "originName"))
    }

    func test_createPropertyMapping_shouldUpdateUserInfo() throws {
        let sut = UpdateAttribute("originName", type: String.self) {
            guard let value = $0 as? Int else { return nil }
            return String(value)
        }
        let source = NSAttributeDescription()
        source.name = "originName"
        let destination = NSAttributeDescription()
        destination.name = "originName"
        let mapping = try sut.createPropertyMapping(from: source, to: destination, of: NSEntityDescription())
        XCTAssertEqual(mapping?.valueExpression, .customAttributeMapping(from: "originName"))
        XCTAssertTrue(mapping?.userInfo?.contains(where: {
            $0.key as? String == UserInfoKey.attributeMappingFunc
            && $0.value is (Any?) -> Any?
        }) == true)
    }
    
    func test_createPropertyObjectMapping_shouldUpdateUserInfo() throws {
        let sut = UpdateAttribute("originName", type: String.self) { (_: NSManagedObject) in
            return nil
        }
        let source = NSAttributeDescription()
        source.name = "originName"
        let destination = NSAttributeDescription()
        destination.name = "originName"
        let mapping = try sut.createPropertyMapping(from: source, to: destination, of: NSEntityDescription())
        XCTAssertEqual(mapping?.valueExpression, .customAttributeMapping { _ in nil })
        XCTAssertTrue(mapping?.userInfo?.contains(where: {
            $0.key as? String == UserInfoKey.attributeMappingFromObjectFunc
            && $0.value is (NSManagedObject) -> Any?
        }) == true)
    }
}
