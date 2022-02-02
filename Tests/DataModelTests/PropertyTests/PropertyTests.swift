//
//  PropertyTests.swift
//  
//
//  Created by ezou on 2021/10/9.
//

import XCTest

@testable import Crush

class PropertyTests: XCTestCase {
    func test_property_shouldBeOptionalByDefault() {
        let property = Value.Int16("property")
        let description = property.createPropertyDescription()
        XCTAssertTrue(description.isOptional)
    }

    func test_property_shouldBeRequired() {
        let property = Required(wrappedValue: Value.Int16("property"))
        let description = property.createPropertyDescription()
        XCTAssertFalse(description.isOptional)
    }

    func test_property_shouldBeOptional() {
        let property = Optional(wrappedValue: Value.Int16("property"))
        let description = property.createPropertyDescription()
        XCTAssertTrue(description.isOptional)
    }

    func test_property_shouldNotBeTransientByDefault() {
        let property = Value.Int16("property")
        let description = property.createPropertyDescription()
        XCTAssertFalse(description.isTransient)
    }

    func test_property_shouldBeTransient() {
        let property = Transient(wrappedValue: Value.Int16("property"))
        let description = property.createPropertyDescription()
        XCTAssertTrue(description.isTransient)
    }

    func test_property_indexedBySpotlightShouldBeFalseByDefault() {
        let property = Value.Int16("property")
        let description = property.createPropertyDescription()
        XCTAssertFalse(description.isIndexedBySpotlight)
    }

    func test_property_indexedBySpotlightShouldBeTrue() {
        let property = IndexedBySpotlight(wrappedValue: Value.Int16("property"))
        let description = property.createPropertyDescription()
        XCTAssertTrue(description.isIndexedBySpotlight)
    }

    func test_property_nameShouldEqualProperty() {
        let property = Value.String("property")
        let description = property.createPropertyDescription()
        XCTAssertEqual(description.name, "property", "name should be property")
    }
}
